#!/usr/bin/env node
/**
 * Seeds a Firebase project with the sample dataset in assets/sample_data.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
 *   node scripts/seed_firestore.js --project jwenn-met [--auth] [--wipe]
 *
 *   --auth   also create Firebase Auth users for the demo accounts
 *            (password: demo1234) and grant the admin claim
 *   --wipe   delete the seeded collections first
 *
 * Against the emulators, set FIRESTORE_EMULATOR_HOST=localhost:8080 and
 * FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 instead of a service account.
 */
const fs = require("node:fs");
const path = require("node:path");
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const args = process.argv.slice(2);
const projectId =
  args[args.indexOf("--project") + 1] ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.GCLOUD_PROJECT;
const withAuth = args.includes("--auth");
const wipe = args.includes("--wipe");

if (!projectId) {
  console.error("error: pass --project <id> or set GOOGLE_CLOUD_PROJECT");
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

const DATA_DIR = path.join(__dirname, "..", "assets", "sample_data");
const read = (name) =>
  JSON.parse(fs.readFileSync(path.join(DATA_DIR, name), "utf8"));

const DEMO_PASSWORD = "demo1234";
const DEMO_ACCOUNTS = [
  { uid: "demo_customer", email: "customer@demo.ht", admin: false },
  { uid: "demo_worker", email: "worker@demo.ht", admin: false },
  { uid: "demo_admin", email: "admin@demo.ht", admin: true },
];

/** ISO strings in the fixtures become real Firestore timestamps. */
const DATE_FIELDS = new Set([
  "createdAt",
  "updatedAt",
  "completedAt",
  "scheduledAt",
  "sentAt",
  "lastMessageAt",
  "issuedAt",
  "paidAt",
  "submittedAt",
  "reviewedAt",
  "resolvedAt",
  "uploadedAt",
  "issuedAt",
]);

function convert(value, key) {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) return value.map((item) => convert(item));
  if (typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, convert(v, k)]),
    );
  }
  if (typeof value === "string" && DATE_FIELDS.has(key)) {
    const parsed = Date.parse(value);
    if (!Number.isNaN(parsed)) return Timestamp.fromMillis(parsed);
  }
  return value;
}

async function writeAll(collection, records, { subcollection } = {}) {
  let batch = db.batch();
  let pending = 0;
  for (const record of records) {
    const { id, messages, ...rest } = record;
    batch.set(db.collection(collection).doc(id), convert(rest));
    pending += 1;

    if (subcollection && Array.isArray(messages)) {
      for (const message of messages) {
        const { id: messageId, ...messageRest } = message;
        batch.set(
          db.collection(collection).doc(id).collection(subcollection).doc(messageId),
          convert(messageRest),
        );
        pending += 1;
      }
    }
    if (pending >= 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
  console.log(`  ${collection}: ${records.length} documents`);
}

async function wipeCollection(name) {
  const snapshot = await db.collection(name).get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`  wiped ${name} (${snapshot.size})`);
}

async function seedNotifications() {
  const byUser = read("notifications.json");
  let count = 0;
  for (const [uid, notifications] of Object.entries(byUser)) {
    const batch = db.batch();
    for (const notification of notifications) {
      const { id, ...rest } = notification;
      batch.set(
        db.collection("users").doc(uid).collection("notifications").doc(id),
        convert(rest),
      );
      count += 1;
    }
    await batch.commit();
  }
  console.log(`  notifications: ${count} documents`);
}

async function seedAuth() {
  const auth = getAuth();
  for (const account of DEMO_ACCOUNTS) {
    try {
      await auth.createUser({
        uid: account.uid,
        email: account.email,
        password: DEMO_PASSWORD,
        emailVerified: true,
      });
      console.log(`  created auth user ${account.email}`);
    } catch (error) {
      if (error.code !== "auth/uid-already-exists") throw error;
      await auth.updateUser(account.uid, { password: DEMO_PASSWORD });
      console.log(`  updated auth user ${account.email}`);
    }
    if (account.admin) {
      await auth.setCustomUserClaims(account.uid, { admin: true });
      console.log("  granted admin claim to admin@demo.ht");
    }
  }
}

async function main() {
  console.log(`Seeding ${projectId}…`);

  if (wipe) {
    for (const name of [
      "users",
      "workers",
      "jobs",
      "reviews",
      "conversations",
      "invoices",
      "reports",
      "verificationRequests",
    ]) {
      await wipeCollection(name);
    }
  }

  await writeAll("users", read("users.json"));
  await writeAll("workers", read("workers.json"));
  await writeAll("jobs", read("jobs.json"));
  await writeAll("reviews", read("reviews.json"));
  await writeAll("conversations", read("conversations.json"), {
    subcollection: "messages",
  });
  await writeAll("invoices", read("invoices.json"));
  await writeAll("reports", read("reports.json"));
  await writeAll("verificationRequests", read("verification_requests.json"));
  await seedNotifications();

  if (withAuth) await seedAuth();

  console.log("Done. Run `firebase deploy --only firestore:indexes` if you have not yet.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
