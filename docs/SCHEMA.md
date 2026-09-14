# Firestore schema

Conventions: document ids are opaque; every `*At` field is a server timestamp;
amounts are in **gourdes (HTG)**; `categoryId` and `departmentId` store the
stable ids from `ServiceCategory` / `HaitiDepartment` and are **never**
localized in the database — the label is resolved at render time. The one
exception is a custom trade, which has no id to resolve: it is stored as the
text the worker typed, in whatever language they typed it, and shown that way
to everyone.

Fields marked **server-owned** are rejected for client writes by
`firebase/firestore.rules` and maintained by `functions/index.js`.

---

## `users/{uid}`

Identity only, so a customer document stays small and cheap to sync.

| Field | Type | Notes |
| --- | --- | --- |
| `fullName` | string | |
| `role` | string | `customer` \| `worker` \| `admin` — **server-owned** |
| `email`, `phone` | string? | at least one is present |
| `photoUrl` | string? | public URL under `profiles/{uid}/` |
| `languageCode` | string | `ht` \| `fr` \| `en` |
| `departmentId`, `city` | string? | |
| `latitude`, `longitude` | number? | last known position, for distance search |
| `phoneVerified` | bool | set after OTP |
| `status` | string | `active` \| `suspended` \| `deleted` — **server-owned** |
| `favoriteWorkerIds` | string[] | |
| `fcmTokens` | string[] | stale tokens pruned when a push fails |
| `createdAt`, `updatedAt` | timestamp | |

### `users/{uid}/notifications/{id}`

| Field | Type | Notes |
| --- | --- | --- |
| `type` | string | `job_request`, `job_accepted`, `job_rejected`, `message`, `review`, `verification`, `payment` |
| `messageKey` | string | key in `assets/i18n/*.json` |
| `args` | map<string,string> | placeholder values, e.g. `{name: "Wilner"}` |
| `jobId`, `conversationId`, `workerId` | string? | deep-link target |
| `read` | bool | the only field a client may update |
| `createdAt` | timestamp | |

Storing the key rather than rendered text is what lets a notification written
in one language render in another after the user switches.

---

## `workers/{uid}`

The public, searchable half of a worker account. Same id as `users/{uid}`.

| Field | Type | Notes |
| --- | --- | --- |
| `fullName`, `headline`, `bio` | string | |
| `categoryIds` | string[] | one or more `ServiceCategory` ids; the id `other` means "see `customCategories`" |
| `customCategories` | string[] | trades the worker typed themselves, verbatim, in their own language. At most 3, each ≤ 40 characters. Present only alongside `other` in `categoryIds` |
| `departmentId`, `city` | string | home base |
| `serviceDepartmentIds`, `serviceCities` | string[] | where they will travel |
| `hourlyRate` | number | HTG |
| `currency` | string | `HTG` |
| `rating` | number | 0–5 — **server-owned** |
| `reviewCount`, `jobsCompleted` | number | **server-owned** |
| `yearsExperience` | number | |
| `verification` | string | `unverified` \| `pending` \| `approved` \| `rejected` — **server-owned** |
| `availableNow` | bool | the "available now" filter |
| `portfolio` | array<map> | `{id, imageUrl, caption, categoryId, uploadedAt}` |
| `certificates` | array<map> | `{id, title, fileUrl, issuer, issuedAt}` |
| `latitude`, `longitude` | number? | distance filter and map pins |
| `acceptedPaymentMethods` | string[] | subset of `moncash`, `natcash`, `card`, `cash` |
| `suspended` | bool | **server-owned**; mirrors `users.status` |

Search hits the indexed predicates server-side (`suspended`, `categoryIds`,
`verification`, `availableNow`, ordered by `rating`); free text, price, city and
distance are applied client-side by `WorkerQuery` so identical rules govern
cached, live and demo results.

`other` is an ordinary value in `categoryIds`, so filtering for it needs no new
index: it returns every worker with a trade the catalog does not list yet. Those
workers are found by name through free text, which matches `customCategories`
as well as the listed trades' names in all three languages — a search for
"plonbye", "plombier" or "plumber" reaches the same workers.

A `customCategories` entry is a promotion candidate: when enough workers type
the same thing, it should become a real `ServiceCategory` value, and their
documents migrated from `other` to the new id.

---

## `jobs/{jobId}`

One customer asking one worker for one job.

| Field | Type | Notes |
| --- | --- | --- |
| `customerId`, `customerName`, `customerPhotoUrl` | string | denormalized for list rendering |
| `workerId`, `workerName`, `workerPhotoUrl` | string | |
| `categoryId` | string | a `ServiceCategory` id, or `other` |
| `customCategory` | string? | set when `categoryId` is `other` — the wording the job was booked under |
| `description` | string | |
| `status` | string | `pending` → `accepted` → `in_progress` → `completed`; or `rejected` / `cancelled` |
| `paymentMethod` | string | `moncash` \| `natcash` \| `card` \| `cash` |
| `departmentId`, `city`, `addressNote` | string? | |
| `latitude`, `longitude` | number? | |
| `budget` | number | what the customer proposed |
| `agreedPrice` | number? | what was actually charged; wins over `budget` |
| `photoUrls` | string[] | under `jobs/{jobId}/` |
| `scheduledAt`, `createdAt`, `updatedAt`, `completedAt` | timestamp? | |
| `reviewId`, `invoiceId` | string? | set when each is created |

---

## `reviews/{reviewId}`

| Field | Type | Notes |
| --- | --- | --- |
| `jobId`, `workerId`, `customerId` | string | |
| `customerName`, `customerPhotoUrl` | string? | |
| `rating` | number | 1–5, enforced by the rules |
| `comment` | string | |
| `status` | string | `published` \| `pending` \| `hidden` (moderation) |
| `workerReply` | string? | the only field the worker may write |
| `createdAt` | timestamp | |

A review can only be created by the customer of a **completed** job — enforced
in the rules, not just in the app.

---

## `conversations/{conversationId}`

Id is `sorted(uidA, uidB).join('_')`, so the two sides can never open two
different threads.

| Field | Type | Notes |
| --- | --- | --- |
| `participantIds` | string[2] | drives both the query and the rule |
| `titles`, `photoUrls` | map<uid,string> | denormalized so the inbox costs one read |
| `jobId` | string? | thread opened from a job |
| `lastMessage`, `lastMessageAt` | string / timestamp | |
| `unreadCounts` | map<uid,number> | incremented for the recipient |

### `conversations/{id}/messages/{messageId}`

`senderId`, `text`, `imageUrl?`, `sentAt`, `readBy[]`. Messages are immutable
except for `readBy`.

---

## `invoices/{invoiceId}`

| Field | Type | Notes |
| --- | --- | --- |
| `number` | string | human reference, e.g. `JM-2026-1042` |
| `jobId`, `customerId`, `workerId` (+ names) | string | |
| `subtotal` | number | what the worker earns |
| `serviceFee` | number | platform commission, stored per invoice so a later rate change never rewrites history |
| `currency` | string | `HTG` |
| `method` | string | `moncash` \| `natcash` \| `card` \| `cash` |
| `status` | string | `unpaid` \| `processing` \| `paid` \| `failed` \| `refunded` — **server-owned** after creation |
| `transactionRef` | string? | provider reference |
| `cardBrand` | string? | `visa` \| `mastercard` — receipts only |
| `cardLast4` | string? | exactly four digits |
| `issuedAt`, `paidAt` | timestamp? | |

Total = `subtotal + serviceFee`; worker payout = `subtotal`.

A card number, expiry or CVC must **never** be written to Firestore. The
device tokenizes with the acquirer, and `cardBrand` / `cardLast4` are all
that come back for the receipt; `functions/index.js` truncates `cardLast4`
server-side as a second line of defence.

---

## `verificationRequests/{uid}`

`workerName`, `idDocumentUrl` (Storage path `identity/{uid}/`), `idType`
(`cin` \| `nif` \| `passport` \| `license`), `certificateUrls[]`, `status`
(`pending` \| `approved` \| `rejected`), `note?`, `submittedAt`, `reviewedAt?`,
`reviewedBy?`. Readable by its owner and admins only.

## `reports/{reportId}`

`reporterId`, `targetUserId`, `targetName`, `reason` (`spam` \| `fraud` \|
`abuse` \| `fake` \| `other`), `details`, `jobId?`, `reviewId?`, `status`
(`open` \| `resolved` \| `dismissed`), `createdAt`, `resolvedAt?`,
`resolutionNote?`. Admin-read only, so a reporter is never exposed.

## `stats/platform`

Aggregates for the admin dashboard, maintained incrementally by triggers and
reconciled nightly by `recomputeStats`: `totalUsers`, `totalWorkers`,
`totalCustomers`, `activeWorkers`, `totalJobs`, `completedJobs`,
`totalRevenue`, `jobsByCategory`, `jobsByDepartment`. Nobody can write it from
a client.

---

## Storage layout

```
profiles/{uid}/photo.jpg                public read,  owner write
portfolio/{uid}/{itemId}.jpg            public read,  owner write
jobs/{jobId}/{itemId}.jpg               signed-in,    signed-in write
chats/{conversationId}/{itemId}.jpg     signed-in,    signed-in write
identity/{uid}/id-document.jpg          ADMIN read,   owner write
identity/{uid}/certificates/{id}.pdf    ADMIN read,   owner write
```

## Auth model

Firebase Auth with email/password, Google, Apple and phone (OTP). The `admin`
role is a **custom claim** set by the `setAdminRole` callable — never a plain
Firestore field a client could flip; `users.role` only mirrors it for display.
