# Build prompt — Jwenn Mèt

A single paste-ready prompt for an AI app builder, condensed from
[`MVP.md`](MVP.md) (scope and cuts) and [`SCHEMA.md`](SCHEMA.md) (data model).

**How to use it**

1. Copy everything below the rule — from `## What you are building` to the end.
2. Set the **Stack** line to whatever your builder actually targets. It is
   written for React Native + Expo + Firebase; if the tool only produces web,
   say so in that line and expect a web prototype, not a store-ready app.
3. If the tool truncates long prompts, send §1–§7 first, let it scaffold, then
   send §8 onward as follow-ups. The **Do not build** list must go in the first
   message either way — it is the part that saves the most rework.

> **This describes a rebuild.** A working Flutter implementation of this same
> scope already exists in this repository. See `MVP.md` §11 before deciding to
> regenerate it.

---

## What you are building

**Jwenn Mèt** — a mobile marketplace connecting customers in Haiti with
verified skilled workers. Tagline: *Find trusted skilled workers across Haiti.*

The entire product is one loop. Build this and nothing else:

> A customer searches their commune for a trade, opens a verified worker's
> profile, requests a job, chats to agree terms, the worker accepts and
> completes it, the customer settles the invoice, and both leave a review.

Quality bar: Airbnb / LinkedIn, not a utility app. Rounded cards, soft
elevation, generous spacing, large type.

## 1. Stack

- **React Native + Expo**, TypeScript, file-based routing
- **Firebase**: Auth (email/password, phone OTP, Google, Apple), Firestore with
  offline persistence enabled, Cloud Storage, Cloud Messaging
- **Cloud Functions** for: payment creation, rating recomputation, notification
  fan-out. Payment credentials never touch the device
- Clean separation: screens → view models / hooks → a service layer behind
  interfaces. **Screens must never import Firebase directly.** Provide a demo
  implementation of each service backed by local seed JSON, selected once at
  boot, so the whole app runs with no backend

## 2. Do not build these

They were in the original brief and are deliberately out of scope. Building any
of them is wasted work:

- **AI matching or recommendations.** Rank deterministically instead:
  rating × recency × distance × availability. There is no data to learn from yet
- **Real-time GPS job tracking.** A 3-hour plumbing visit is not a 7-minute ride
- **Availability calendar.** Ship an available / busy toggle and preferred hours
- **Card payments.** MonCash and recorded cash only (see §9)
- **Escrow or held funds.** The app *records* settlement, it does not custody money
- **Teams, company accounts, subcontracting**
- **Web or desktop app**
- **Editorial content** ("artisan of the week", blog, feed)
- Onboarding carousels beyond 3 slides, in-app help centre, referral screens,
  worker analytics beyond a simple earnings total

## 3. Languages

Three, fully localised, switchable in Settings and chosen before sign-up:
**Kreyòl Ayisyen (`ht`, the default)**, **Français (`fr`)**, **English (`en`)**.

- One JSON catalog per language, identical key sets, identical `{placeholders}`.
  Fail the build if they diverge
- Every string goes through the catalog: labels, empty states, errors,
  validation messages, push notification bodies
- **Notifications store a catalog key plus arguments, never rendered text**, so
  a notification written last week displays in whatever language the user reads
  today
- Kreyòl has no built-in date/number bundle — fall back to French for those

## 4. Design system

| Token | Hex | Use |
| --- | --- | --- |
| Royal Blue | `#0B3D91` | Primary |
| Heritage Red | `#C8102E` | Accent, sparingly; never the only signal on a destructive action |
| Warm Ivory | `#F4F1E8` | Light background |
| Palm Green | `#2E8B57` | Success, verified badge |

- **Poppins** headings, **Inter** body
- Light and dark themes, both complete. Define colors as tokens once; never
  hard-code a hex in a component
- Accessibility: WCAG AA contrast, dynamic type to 200%, 44pt minimum touch
  target, a semantic label on every control
- Imagery: one heritage hero (Citadelle Laferrière) on Home and onboarding
  only. Everywhere else, photography is of workers at work. Use clearly-marked
  placeholders; do not invent image URLs

## 5. Roles

- **Customer** — searches, books, chats, pays, reviews
- **Worker** — profile, portfolio, accepts/declines jobs, invoices, earnings,
  submits ID for verification
- **Admin** — verification queue, report queue, review moderation, suspend user

Role is chosen at sign-up and drives which home screen loads.

## 6. Navigation

Bottom tabs: **Home · Search · Jobs · Messages · Profile**

Routing has one gate chain, evaluated in order:
language chosen → onboarding seen → authenticated → role-appropriate home.

## 7. Screens

| Area | Screens |
| --- | --- |
| Onboarding | Splash, language picker, 3-slide intro, role picker |
| Auth | Sign up, log in, phone + OTP, forgot password |
| Home | Greeting in the user's language, search bar ("What service do you need?"), popular trades, top-rated nearby, recent jobs |
| Search | Results list, filter sheet (trade, department, commune, rating, price, verified-only, available-now), grouped categories grid |
| Worker | Public profile, portfolio viewer, all reviews |
| Jobs | Job list (customer and worker views), job detail, booking/request form |
| Messages | Conversation list, chat thread |
| Reviews | Write review |
| Worker tools | Dashboard, profile edit, earnings, ID verification upload |
| Settings | Profile, settings (language, theme, notifications), report-user sheet, emergency call button |
| Admin | Dashboard, verifications, reports, reviews, users |

## 8. Trade catalog

Store the **id**. Never store a translated label. Resolve the label at render
time from the catalog.

| id | English | Français | Kreyòl |
| --- | --- | --- | --- |
| `electrician` | Electrician | Électricien | Elektrisyen |
| `plumber` | Plumber | Plombier | Plonbye |
| `carpenter` | Carpenter | Charpentier | Chapantye |
| `mason` | Mason | Maçon | Mason |
| `painter` | Painter | Peintre | Pent |
| `welder` | Welder | Soudeur | Soudè |
| `ac_technician` | AC technician | Technicien en climatisation | Teknisyen klimatizasyon |
| `mechanic` | Mechanic | Mécanicien | Mekanisyen |
| `cleaner` | Cleaner | Agent d'entretien | Netwayè |
| `tailor` | Tailor | Tailleur | Tayè |
| `hair_stylist` | Hair stylist | Coiffeur | Kwafè |
| `barber` | Barber | Barbier | Barbye |
| `makeup_artist` | Makeup artist | Maquilleur | Makiyè |
| `nail_technician` | Nail technician | Manucure | Manikè |
| `massage_therapist` | Massage therapist | Masseur | Masè |
| `other` | Other | Autre | Lòt |

Displayed in four groups — Building & repair (`electrician` … `mechanic`),
Home & everyday (`cleaner`, `tailor`), Beauty & wellness (`hair_stylist` …
`massage_therapist`), Other (`other`). Sixteen trades in one flat grid does not
read; group them on the browse screen, the filter sheet and the worker's own
trade picker.

### Custom trades — the `other` escape hatch

A worker whose trade is not listed types it. Rules:

1. Store the typed text verbatim in `customCategories`, in whatever language
   they typed it, and show it that way to everyone. Add `other` to their
   `categoryIds` alongside it
2. **Max 3 per worker, 40 characters each.** Enforce in the UI *and* in the
   Firestore rules
3. Before storing, fold the text — lowercase, strip accents, normalise `_`/`-`
   to spaces, collapse whitespace — and compare it against a per-trade alias
   list covering all three languages. If it matches a listed trade, select that
   trade instead and tell the user. "Coiffeuse", "kwafe" and "Hair Stylist" all
   belong in `hair_stylist`, not in a private bucket nobody browses
4. Typing the literal word "Other"/"Autre"/"Lòt" adds nothing
5. Removing the last custom trade removes `other` from `categoryIds`
6. Free-text search matches `customCategories` **and** the alias lists, so
   searching "plonbye", "plombier" or "plumber" all reach plumbers, and typing
   "électricien" works with or without the accent
7. A job booked against one stores `categoryId: "other"` plus `customCategory`

## 9. Data model (Firestore)

Ids are opaque. Every `*At` is a server timestamp. Amounts are in **gourdes
(HTG)**. Fields marked **server-owned** must be rejected for client writes in
the security rules and maintained by Cloud Functions.

**`users/{uid}`** — `fullName`, `role` (`customer`|`worker`|`admin`), `email`,
`phone`, `photoUrl`, `languageCode`, `departmentId`, `city`, `latitude`,
`longitude`, `phoneVerified`, `status` (`active`|`suspended` — **server-owned**),
`favoriteWorkerIds[]`, `fcmTokens[]`, `createdAt`

**`workers/{uid}`** — world-readable; same id as the user. `fullName`,
`headline`, `bio`, `categoryIds[]`, `customCategories[]` (§8), `departmentId`,
`city`, `serviceDepartmentIds[]`, `serviceCities[]`, `hourlyRate`, `currency`,
`photoUrl`, `phone`, `yearsExperience`, `availableNow`, `latitude`, `longitude`,
`acceptedPaymentMethods[]`, `portfolio[]` (`{id, imageUrl, caption, categoryId,
uploadedAt}`), `certificates[]` (`{id, title, fileUrl, issuer, issuedAt}`),
`createdAt`; **server-owned:** `rating`, `reviewCount`, `jobsCompleted`,
`verification` (`unverified`|`pending`|`approved`|`rejected`), `suspended`

**`jobs/{jobId}`** — private to its two parties. `customerId`, `customerName`,
`customerPhotoUrl`, `workerId`, `workerName`, `workerPhotoUrl`, `categoryId`,
`customCategory?`, `description`, `status` (`pending` → `accepted` →
`in_progress` → `completed`, or `rejected` / `cancelled`), `paymentMethod`,
`departmentId`, `city`, `addressNote`, `latitude`, `longitude`, `budget`,
`agreedPrice?`, `photoUrls[]`, `scheduledAt`, `createdAt`, `updatedAt`,
`completedAt`, `reviewId?`, `invoiceId?`

**`reviews/{reviewId}`** — `jobId`, `workerId`, `customerId`, `customerName`,
`rating` (1–5), `comment`, `workerReply?`, `status`
(`published`|`hidden`|`deleted`), `createdAt`. Only the customer on a
**completed** job may create one. The worker may add `workerReply` and nothing
else. Moderation is admin-only

**`conversations/{id}`** with subcollection `messages/{id}` — `participantIds[]`
(exactly 2), `titles{}`, `unreadCounts{}`, `lastMessage`, `updatedAt`; messages
carry `senderId`, `text`, `imageUrl?`, `sentAt`, `readAt?`

**`invoices/{invoiceId}`** — `number`, `jobId`, `customerId`, `customerName`,
`workerId`, `workerName`, `subtotal`, `serviceFee`, `total`, `payout`, `method`,
`status` (`unpaid`|`paid`|`refunded`), `paidAt?`

**`reports/{reportId}`** — admin-only. `reporterId`, `targetUserId`, `context`
(profile | chat | job), `contextId`, `reason`, `notes`, `status`, `createdAt`

**`users/{uid}/notifications/{id}`** — `titleKey`, `bodyKey`, `args{}`, `route`,
`read`, `createdAt`. Written by the server; the client may only set `read`

**Geography.** 10 departments — `ouest`, `nord`, `nord_est`, `nord_ouest`,
`artibonite`, `centre`, `sud`, `sud_est`, `grand_anse`, `nippes` — each with its
list of communes. Store the department id and the commune name.

## 10. Business rules

- **Invoice on completion.** `serviceFee` = 10% of `subtotal`; `total` =
  subtotal + fee; `payout` = subtotal. Every completed job gets exactly one
- **Payment methods:** `moncash` and `cash` at launch. A cash invoice stays
  `unpaid` until the **worker** confirms receipt in the app
- **Reputation is server-owned.** A Cloud Function recomputes `rating`,
  `reviewCount` and `jobsCompleted` from published reviews. A client that can
  write its own score makes every badge worthless
- **Verification:** worker uploads a government ID → stored under an
  **admin-read-only** Storage path → admin approves or rejects with a reason →
  approval sets the verified badge. Unverified workers rank below verified ones
  and never render the badge
- **Privacy:** a worker's phone number is hidden from a customer until the job
  is accepted. Account deletion removes the user's data
- **Safety:** report a user from a profile, a chat or a job; emergency call to
  **114** behind a confirmation, on Home and Profile
- **Search** runs indexed predicates server-side (`suspended`, `categoryIds`,
  `verification`, `availableNow`, ordered by `rating`) and applies free text,
  price, commune and distance client-side, so cached, live and demo results
  obey identical rules

## 11. Non-functional requirements

- Android 8+ and iOS 14+. **Android is the priority — it is the market**
- Every screen usable on 3G. Search results, job list and chat history read
  from local cache first, network second. A blank screen on a bad connection
  is churn
- No screen over ~1.5 MB cold; serve images at display resolution and cache
  them. Mobile data is expensive in Haiti
- Cold start under 3s on a mid-range Android; search results under 2s on 3G
- Chat messages and job actions queue locally when offline and sync on
  reconnect, with a visible pending state
- Push notifications for: new job request, accept/decline, new message, job
  completed

## 12. Seed data

Generate a demo dataset and a demo mode that reads it, so the full loop can be
walked with no backend: ~24 workers spread across all 10 departments and every
trade in §8 — including at least two with custom trades — plus ~18 jobs in
mixed states, reviews, chat threads, invoices, a pending verification queue and
an open report. Include three fixed accounts: a customer, a worker and an admin.

## 13. Definition of done

1. A customer signs up, searches "Plonbye" in "Delmas", opens a verified
   profile, requests a job, and the worker is notified within 60 seconds
2. The worker accepts, both chat, the worker completes and issues an invoice
   with a 10% fee; the customer settles by MonCash or confirmed cash
3. Both leave a review; the worker's rating updates from the server, not the
   client
4. A worker uploads an ID, an admin approves it, the badge appears
5. A worker adds a custom trade, and a customer finds and books them by typing
   it into search
6. Every one of the above works identically in all three languages, in light
   and dark mode, and the read paths still render with the network off
