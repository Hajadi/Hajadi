/**
 * Cloud Functions for Jwenn Mèt.
 *
 * These own everything a client must not be trusted with:
 *   - rating aggregates and job counters;
 *   - verification status and admin claims;
 *   - payment creation and settlement (wallet keys never reach the device);
 *   - push notifications, sent as catalog keys so every device renders them
 *     in its own language.
 */
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentWritten, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();

const REGION = "us-central1";
const SERVICE_FEE_RATE = 0.1;

// Wallet credentials live in Secret Manager, never in the repo:
//   firebase functions:secrets:set MONCASH_CLIENT_SECRET
const MONCASH_CLIENT_ID = defineSecret("MONCASH_CLIENT_ID");
const MONCASH_CLIENT_SECRET = defineSecret("MONCASH_CLIENT_SECRET");
const NATCASH_MERCHANT_ID = defineSecret("NATCASH_MERCHANT_ID");
const NATCASH_API_KEY = defineSecret("NATCASH_API_KEY");
// Card acquirer (Visa / Mastercard). The device only ever holds the
// publishable key; this secret one is what actually moves money.
const CARD_SECRET_KEY = defineSecret("CARD_SECRET_KEY");
const PAYMENT_WEBHOOK_SECRET = defineSecret("PAYMENT_WEBHOOK_SECRET");

/** Writes an in-app notification and pushes it to the user's devices. */
async function notify(uid, { type, messageKey, args = {}, jobId, conversationId, workerId }) {
  const payload = {
    type,
    messageKey,
    args,
    jobId: jobId ?? null,
    conversationId: conversationId ?? null,
    workerId: workerId ?? null,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  };
  await db.collection("users").doc(uid).collection("notifications").add(payload);

  const user = await db.collection("users").doc(uid).get();
  const tokens = user.get("fcmTokens") || [];
  if (tokens.length === 0) return;

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      // Data-only: the client renders the catalog key in the user's language.
      data: {
        type,
        messageKey,
        jobId: jobId ?? "",
        conversationId: conversationId ?? "",
        args: JSON.stringify(args),
      },
    });
    // Drop tokens the device no longer accepts, or the list grows forever.
    const stale = [];
    response.responses.forEach((result, index) => {
      if (!result.success) stale.push(tokens[index]);
    });
    if (stale.length > 0) {
      await user.ref.update({ fcmTokens: FieldValue.arrayRemove(...stale) });
    }
  } catch (error) {
    logger.error("push failed", { uid, error: error.message });
  }
}

/**
 * Recomputes a worker's rating from published reviews only.
 * The client can never write these fields (see firestore.rules).
 */
exports.onReviewWritten = onDocumentWritten(
  { region: REGION, document: "reviews/{reviewId}" },
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    const workerId = after?.workerId || before?.workerId;
    if (!workerId) return;

    const published = await db
      .collection("reviews")
      .where("workerId", "==", workerId)
      .where("status", "==", "published")
      .get();

    const count = published.size;
    const sum = published.docs.reduce((total, doc) => total + (doc.get("rating") || 0), 0);
    await db.collection("workers").doc(workerId).set(
      {
        rating: count === 0 ? 0 : Number((sum / count).toFixed(2)),
        reviewCount: count,
      },
      { merge: true },
    );

    if (!before && after) {
      await notify(workerId, {
        type: "review",
        messageKey: "notifReviewReceived",
        args: { name: after.customerName || "" },
      });
    }
  },
);

/** Notifies both sides as a job moves through its lifecycle. */
exports.onJobWritten = onDocumentWritten(
  { region: REGION, document: "jobs/{jobId}" },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after) return;
    const jobId = event.params.jobId;

    if (!before) {
      await notify(after.workerId, {
        type: "job_request",
        messageKey: "notifNewRequest",
        args: { name: after.customerName || "" },
        jobId,
      });
      return;
    }
    if (before.status === after.status) return;

    if (after.status === "accepted" || after.status === "rejected") {
      await notify(after.customerId, {
        type: after.status === "accepted" ? "job_accepted" : "job_rejected",
        messageKey: after.status === "accepted" ? "notifAccepted" : "notifRejected",
        args: { name: after.workerName || "" },
        jobId,
      });
    }

    if (after.status === "completed") {
      await db.collection("workers").doc(after.workerId).set(
        { jobsCompleted: FieldValue.increment(1) },
        { merge: true },
      );
      await db.collection("stats").doc("platform").set(
        {
          // Nested maps, not dotted keys: `set()` treats a dot as part of the
          // field name, so `a.b` would create a literal field called "a.b".
          completedJobs: FieldValue.increment(1),
          jobsByCategory: { [after.categoryId]: FieldValue.increment(1) },
          jobsByDepartment: {
            [after.departmentId || "unknown"]: FieldValue.increment(1),
          },
        },
        { merge: true },
      );
    }
  },
);

/** Pushes each new chat message to the other participant. */
exports.onMessageCreated = onDocumentCreated(
  { region: REGION, document: "conversations/{conversationId}/messages/{messageId}" },
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const conversationId = event.params.conversationId;
    const conversation = await db.collection("conversations").doc(conversationId).get();
    const participants = conversation.get("participantIds") || [];
    const recipient = participants.find((id) => id !== message.senderId);
    if (!recipient) return;

    const titles = conversation.get("titles") || {};
    await notify(recipient, {
      type: "message",
      messageKey: "notifNewMessage",
      args: { name: titles[message.senderId] || "" },
      conversationId,
    });
  },
);

/** Keeps the admin console's user counters current. */
exports.onUserWritten = onDocumentWritten(
  { region: REGION, document: "users/{uid}" },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (before && after) return;

    const delta = after ? 1 : -1;
    const role = (after || before).role;
    await db.collection("stats").doc("platform").set(
      {
        totalUsers: FieldValue.increment(delta),
        totalWorkers: FieldValue.increment(role === "worker" ? delta : 0),
        totalCustomers: FieldValue.increment(role === "customer" ? delta : 0),
      },
      { merge: true },
    );
  },
);

/** Mirrors an admin's verification decision onto the public profile. */
exports.onVerificationDecided = onDocumentWritten(
  { region: REGION, document: "verificationRequests/{uid}" },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after || before?.status === after.status) return;
    if (after.status !== "approved" && after.status !== "rejected") return;

    await db.collection("workers").doc(event.params.uid).set(
      { verification: after.status },
      { merge: true },
    );
    if (after.status === "approved") {
      await notify(event.params.uid, {
        type: "verification",
        messageKey: "notifVerified",
      });
    }
  },
);

/**
 * Creates a MonCash or NatCash payment for an invoice.
 *
 * The client sends only an invoice id: the amount is read from Firestore so a
 * tampered request cannot under-pay, and the wallet credentials stay here.
 */
exports.createPayment = onRequest(
  {
    region: REGION,
    cors: true,
    secrets: [
      MONCASH_CLIENT_ID,
      MONCASH_CLIENT_SECRET,
      NATCASH_MERCHANT_ID,
      NATCASH_API_KEY,
      CARD_SECRET_KEY,
    ],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "method_not_allowed" });
      return;
    }
    const { invoiceId, method, payerPhone, cardToken, cardBrand, cardLast4 } =
      req.body || {};
    if (!invoiceId || !method) {
      res.status(400).json({ error: "invalid_request" });
      return;
    }

    // Authenticate the caller: an unauthenticated request must never be able
    // to drive a wallet charge, and only the invoice's customer may pay it.
    const header = req.get("authorization") || "";
    const idToken = header.startsWith("Bearer ") ? header.slice(7) : null;
    if (!idToken) {
      res.status(401).json({ error: "unauthenticated" });
      return;
    }
    let caller;
    try {
      const { getAuth } = require("firebase-admin/auth");
      caller = await getAuth().verifyIdToken(idToken);
    } catch (error) {
      logger.warn("rejected payment token", { error: error.message });
      res.status(401).json({ error: "unauthenticated" });
      return;
    }

    const invoiceRef = db.collection("invoices").doc(invoiceId);
    const invoice = await invoiceRef.get();
    if (!invoice.exists) {
      res.status(404).json({ error: "invoice_not_found" });
      return;
    }
    if (invoice.get("customerId") !== caller.uid) {
      res.status(403).json({ error: "not_your_invoice" });
      return;
    }
    if (invoice.get("status") === "paid") {
      res.status(409).json({ error: "already_paid" });
      return;
    }

    if (!["moncash", "natcash", "card"].includes(method)) {
      res.status(400).json({ error: "unsupported_method" });
      return;
    }

    const amount = (invoice.get("subtotal") || 0) + (invoice.get("serviceFee") || 0);
    const reference = `${method.toUpperCase()}-${invoiceId}-${Date.now()}`;
    let redirectUrl = null;

    if (method === "card") {
      // --- Card integration (Visa / Mastercard) ----------------------------
      // The app tokenizes with the acquirer's publishable key, so what arrives
      // here is a single-use token — never a PAN. Charge it with CARD_SECRET_KEY
      // and return the 3-D Secure URL when the issuer asks for a challenge:
      //
      //   POST https://api.<acquirer>.com/payments
      //   { source: cardToken, amount: <minor units>, currency: "HTG",
      //     "3ds": { enabled: true },
      //     success_url / failure_url -> your hosted return pages }
      //
      // If no token is present the app has no tokenization key configured, so
      // fall back to the acquirer's hosted checkout page and let it collect
      // the card entirely outside our systems.
      if (!cardToken) {
        logger.info("card payment without token: using hosted checkout", {
          invoiceId,
        });
        // redirectUrl = <hosted checkout session URL from the acquirer>;
      }
      await invoiceRef.update({
        status: "processing",
        transactionRef: reference,
        method,
        // Brand and last four are all we keep, and only for the receipt.
        ...(cardBrand ? { cardBrand } : {}),
        ...(cardLast4 ? { cardLast4: String(cardLast4).slice(-4) } : {}),
      });
    } else {
      // --- Wallet integration ----------------------------------------------
      // Replace with the provider call once merchant access is granted. Both
      // wallets follow the same shape: authenticate with the merchant
      // credentials, create a payment for `amount` in HTG, and return a hosted
      // checkout URL the app opens.
      //
      //   MonCash: POST https://moncashbutton.digicelgroup.com/Api/v1/CreatePayment
      //   NatCash: POST https://api.natcash.ht/merchant/v1/payments
      await invoiceRef.update({
        status: "processing",
        transactionRef: reference,
        method,
      });
    }

    // Settlement always arrives at `paymentWebhook` below — never trust the
    // client's word for it, whichever method was used.
    logger.info("payment requested", { invoiceId, method, amount, payerPhone });
    res.json({ reference, status: "processing", redirectUrl });
  },
);

/** Provider callback that actually settles an invoice. */
exports.paymentWebhook = onRequest(
  { region: REGION, secrets: [PAYMENT_WEBHOOK_SECRET] },
  async (req, res) => {
    const signature = req.get("x-jwennmet-signature");
    if (signature !== PAYMENT_WEBHOOK_SECRET.value()) {
      res.status(401).json({ error: "bad_signature" });
      return;
    }
    const { reference, status } = req.body || {};
    if (!reference) {
      res.status(400).json({ error: "invalid_request" });
      return;
    }

    const matches = await db
      .collection("invoices")
      .where("transactionRef", "==", reference)
      .limit(1)
      .get();
    if (matches.empty) {
      res.status(404).json({ error: "unknown_reference" });
      return;
    }

    const invoice = matches.docs[0];
    const paid = status === "paid" || status === "success";
    const { cardBrand, cardLast4 } = req.body || {};
    await invoice.ref.update({
      status: paid ? "paid" : "failed",
      paidAt: paid ? FieldValue.serverTimestamp() : null,
      // A hosted card checkout reports the brand and last four only here,
      // because the app never saw the card at all.
      ...(cardBrand ? { cardBrand } : {}),
      ...(cardLast4 ? { cardLast4: String(cardLast4).slice(-4) } : {}),
    });

    if (paid) {
      const total = (invoice.get("subtotal") || 0) + (invoice.get("serviceFee") || 0);
      await db.collection("stats").doc("platform").set(
        { totalRevenue: FieldValue.increment(total) },
        { merge: true },
      );
      await notify(invoice.get("workerId"), {
        type: "payment",
        messageKey: "paymentSuccess",
        jobId: invoice.get("jobId"),
      });
      await notify(invoice.get("customerId"), {
        type: "payment",
        messageKey: "paymentSuccess",
        jobId: invoice.get("jobId"),
      });
    }
    res.json({ ok: true });
  },
);

/** Grants or revokes the admin claim. Callable by an existing admin only. */
exports.setAdminRole = onCall({ region: REGION }, async (request) => {
  if (request.auth?.token?.admin !== true) {
    throw new HttpsError("permission-denied", "Admins only.");
  }
  const { uid, admin } = request.data || {};
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }
  const { getAuth } = require("firebase-admin/auth");
  await getAuth().setCustomUserClaims(uid, { admin: admin === true });
  await db.collection("users").doc(uid).set(
    { role: admin === true ? "admin" : "customer" },
    { merge: true },
  );
  return { ok: true };
});

/**
 * Nightly reconciliation. The incremental counters above can drift after a
 * failed write; this recomputes them from the collections themselves.
 */
exports.recomputeStats = onSchedule(
  { region: REGION, schedule: "0 3 * * *", timeZone: "America/Port-au-Prince" },
  async () => {
    const [users, workers, jobs, invoices] = await Promise.all([
      db.collection("users").count().get(),
      db.collection("workers").where("suspended", "==", false).get(),
      db.collection("jobs").get(),
      db.collection("invoices").where("status", "==", "paid").get(),
    ]);

    const jobsByCategory = {};
    const jobsByDepartment = {};
    let completed = 0;
    jobs.forEach((doc) => {
      const category = doc.get("categoryId") || "unknown";
      const department = doc.get("departmentId") || "unknown";
      jobsByCategory[category] = (jobsByCategory[category] || 0) + 1;
      jobsByDepartment[department] = (jobsByDepartment[department] || 0) + 1;
      if (doc.get("status") === "completed") completed += 1;
    });

    const totalRevenue = invoices.docs.reduce(
      (sum, doc) => sum + (doc.get("subtotal") || 0) + (doc.get("serviceFee") || 0),
      0,
    );

    await db.collection("stats").doc("platform").set(
      {
        totalUsers: users.data().count,
        totalWorkers: workers.size,
        activeWorkers: workers.docs.filter((doc) => doc.get("availableNow")).length,
        totalJobs: jobs.size,
        completedJobs: completed,
        totalRevenue,
        jobsByCategory,
        jobsByDepartment,
        serviceFeeRate: SERVICE_FEE_RATE,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    logger.info("stats recomputed", { totalJobs: jobs.size });
  },
);
