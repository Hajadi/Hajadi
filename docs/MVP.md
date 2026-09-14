# Jwenn Mèt — MVP Definition

> **Status:** proposal · **Owner:** _unassigned_ · **Last revised:** 2026-09-14
>
> This document converts the original product brief (a feature wish-list written
> as an app-builder prompt) into an MVP: a scoped, testable, shippable first
> release with explicit cuts, measurable success criteria and a decision log.
>
> Companion documents: [`SCHEMA.md`](SCHEMA.md) (data model),
> [`DEPLOYMENT.md`](DEPLOYMENT.md) (backend + store release),
> [`PLATFORM_SETUP.md`](PLATFORM_SETUP.md) (platform keys).

---

## 1. One-liner

**Jwenn Mèt** lets someone in Haiti find, vet and hire a skilled tradesperson
from their phone in under ten minutes — and lets that tradesperson get paid and
build a reputation that travels with them.

**Tagline:** _Find trusted skilled workers across Haiti._
**Kreyòl:** _Jwenn bon mèt metye toupatou an Ayiti._

---

## 2. The problem

Hiring a plumber, electrician or mason in Haiti runs on personal referral. That
has three consequences:

| Problem | Who feels it | Today's workaround |
| --- | --- | --- |
| No way to find a worker outside your own network | Customer | Ask neighbours, WhatsApp groups, wait days |
| No way to tell a competent worker from an incompetent one before the job | Customer | Trust the referrer; absorb the risk |
| No portable reputation — good work only earns you the next job from the same client | Worker | Word of mouth, limited to one neighbourhood |
| Price is negotiated blind, with no reference point | Both | Haggling, disputes mid-job |

**These are stated as hypotheses, not findings.** Section 4 lists what the MVP
exists to prove. If customer-side discovery pain turns out to be weaker than
worker-side reputation pain, the product changes shape — better to learn that
from twelve weeks of real usage than from a bigger build.

---

## 3. Users

### Primary: the customer ("Kliyan")

Urban or peri-urban, Port-au-Prince metro, smartphone-owning, on mobile data with
intermittent coverage. Needs a specific job done — often urgently (a burst pipe,
a dead inverter). Willing to pay for a worker who shows up. Reads Kreyòl first,
French second.

### Primary: the skilled worker ("Mèt metye")

Electrician, plumber, mason, AC technician. Works on referral, has gaps in their
week, owns an Android phone, is comfortable with WhatsApp and MonCash. Motivated
by steady lead flow and by proof of competence they can point to.

### Secondary: the operator (internal admin)

One to two people. Approves identity verification, works the report queue,
moderates reviews. **Not** a growth role — a trust role. Without this person the
marketplace has no floor.

---

## 4. What the MVP exists to test

The MVP is an experiment. Its job is to resolve four assumptions, ranked by how
badly the product fails if they are wrong:

| # | Assumption | How the MVP tests it | Falsified if |
| --- | --- | --- | --- |
| A1 | Workers will answer job requests from strangers, fast | Measure time-to-first-response on every request | Median response > 2h, or < 50% of requests answered in 24h |
| A2 | Customers will hire someone they found in an app instead of asking a neighbour | Measure request → accepted → completed conversion | < 25% of posted jobs reach "completed" |
| A3 | Both sides will settle payment inside the app (even when the app only *records* cash) | Measure invoices marked paid in-app vs. jobs completed | < 40% of completed jobs get an in-app settlement record |
| A4 | Reviews accumulate fast enough to become a real signal | Measure reviews per completed job, and time to a worker's 5th review | < 30% of completed jobs get a review |

Everything in Section 5 either serves one of these four tests or is a legal or
safety floor. Everything that serves neither is in Section 6.

---

## 5. MVP scope — what ships

The whole release is one sentence:

> A customer searches their commune for a trade, opens a verified worker's
> profile, requests a job, chats to agree terms, the worker accepts and completes
> it, the customer settles the invoice, and both leave a review.

Anything not on that path is justified below or cut.

### 5.1 Must have

| # | Capability | Why it is non-negotiable |
| --- | --- | --- |
| M1 | Email + phone (OTP) sign-up, two roles (customer / worker) | Entry to everything |
| M2 | Worker profile: photo, trade(s), commune, years of experience, rate, short bio, up to 6 portfolio photos | This *is* the product's answer to "can I trust this person" |
| M3 | Search by trade + commune, with distance/rating/price sort and filters | The discovery test (A2) |
| M3b | An **Other** trade a worker types themselves, searchable and bookable like any listed one | A catalog is a guess; this is how it corrects itself (see §6) |
| M4 | Job request → worker accept/decline → in-progress → completed | The core transaction (A1, A2) |
| M5 | 1:1 in-app chat scoped to a job | Terms get agreed in conversation, not in a form |
| M6 | Invoice on completion, settled by cash-confirmed or MonCash | The money test (A3) |
| M7 | Two-way star rating + written review, published after completion | The reputation test (A4) |
| M8 | Government-ID verification → admin approval → **verified badge** | The trust floor; the badge is the brand |
| M9 | Report a user (from profile, chat or job) + admin report queue | Safety floor; a marketplace without this is negligent |
| M10 | Push notifications for: new request, accept/decline, new message, job completed | Response latency is A1; without push the loop dies |
| M11 | Full Kreyòl / Français / English localisation, switchable in-app | Kreyòl is the default. Not a feature — a precondition |
| M12 | Offline-tolerant reads (cached search results, job list, chat history) | Coverage is intermittent; a blank screen on the bus is churn |
| M13 | Admin console: verification queue, report queue, review moderation, user suspend | M8 and M9 are unenforceable without it |

### 5.2 Should have — in the release if the schedule allows, cut without drama

- Favourites / saved workers
- Categories browse screen (a grid of trades) alongside search
- Worker earnings summary (this month, all-time, pending)
- Emergency call button (114) behind a confirmation
- Home shelves: popular trades, top-rated nearby, recently active

### 5.3 Explicitly out of the MVP

Each of these was in the original brief. Each is cut with a reason and a
re-entry condition.

| Cut | Reason | Comes back when |
| --- | --- | --- |
| **AI matching / recommendations** | "AI" here means ranking, and ranking on a cold marketplace with no data is worse than a good sort. A deterministic score (rating × recency × distance × availability) is honest and shippable now | There are ≥ 5k completed jobs to learn from |
| **Real-time GPS job tracking** | Uber-style live tracking fits a 7-minute ride, not a 3-hour plumbing visit. Customers need an ETA, not a moving dot. A chat message covers it | Same-hour dispatch becomes a real use case |
| **Availability calendar** | A full calendar is a large build that workers won't maintain. MVP ships an available / busy toggle + preferred working hours | Workers ask for it, or double-booking becomes a top complaint |
| **Card payments (Visa/Mastercard)** | Acquirer onboarding, merchant account and PCI scoping in Haiti are measured in months, not sprints. They must not sit on the launch critical path. MonCash + recorded cash covers the test in A3 | Merchant access is granted; the code path already exists (see §11) |
| **Escrow / held funds** | Holding customer money makes this a regulated payments business. The MVP records settlement, it does not custody funds | After legal review, and not before |
| **Worker-to-worker subcontracting, teams, company accounts** | Complexity for a market segment that isn't validated | Demand appears in interviews |
| **Web app / desktop** | Neither side of this market is on a desktop | Never, probably |
| **Featured artisan of the week** | Editorial content is a weekly human cost with no test attached | There is a marketing function to run it |
| **Nationwide launch (all ten departments)** | Marketplace liquidity is local. Thin coverage everywhere is worse than dense coverage somewhere | Metro cohort hits the §9 targets |
| **10 trades** | Same argument. Depth over breadth | Per-trade demand justifies it |

### 5.4 Geographic and category scope at launch

**Launch area:** Port-au-Prince metro only — Pétion-Ville, Delmas, Port-au-Prince
commune, Carrefour, Croix-des-Bouquets. One contiguous, dense market.

**Launch trades — vertical 1, building & repair:** five, chosen for frequency
of need and low job-size variance:

1. Elektrisyen (electrician)
2. Plonbye (plumber)
3. Mason (mason)
4. Teknisyen AC / frijidè (AC & refrigeration)
5. Mekanisyen (mechanic)

**Vertical 2, beauty & wellness — a decision, not five more chips** (Q8).
Kwafè (hair stylist), barbye (barber), makiyè (makeup artist), manikè (nail
technician) and masè (massage therapist) are in the catalog and fully built. But
they are a *different marketplace*: appointments rather than emergencies, low
ticket, high frequency, high repeat, and largely a different population on both
sides. That is not a reason to skip it — the opposite. Higher frequency means
A1, A2 and A4 all resolve faster, so beauty may be the better wedge, or a
parallel one. What it must not be is an accident: launching ten trades to test
one hypothesis dilutes supply density across two markets that share nothing but
an app. Pick one to lead with, or run both deliberately with separate supply
targets.

**Supply target before opening to customers:** 15 verified workers per trade in
the launch area = **75 verified workers** per vertical. Do not open the customer
side below this. A customer who searches and finds nobody does not come back.

**The full catalog is 15 listed trades plus Other**, and that is fine — the
catalog is what exists in the app, the *launch set* is what supply and marketing
are pointed at. They are different numbers on purpose.

### 5.5 The Other trade — how the catalog corrects itself

Any fixed list of trades is a guess about a market nobody has measured yet. So a
worker who does not find their trade types it, and:

- it is stored verbatim, in whatever language they typed it, and shown that way
  to everyone — at most 3 per worker, 40 characters each;
- if what they typed is a trade we *already* list, however spelled ("Coiffeuse",
  "kwafe", "Hair Stylist"), they are put in that real bucket instead — a private
  duplicate nobody browses helps no one;
- customers reach them through free-text search and through an **Other** tile
  in the browse grid and filter sheet;
- a job booked with them records `other` plus that wording, so the job history
  says what it was actually for.

**The typed text is the product's best demand signal.** It is a list, in the
workers' own words, of the trades the catalog is missing. Review it monthly:
when enough workers type the same thing, it becomes a real trade and their
documents migrate off `other`. Two of the metrics in §9 should be read together
with it — a rising share of `other` profiles means the catalog is falling
behind its own market.

**Moderation.** Custom trades are free text on a world-readable profile. The
count is capped in the security rules and the length in the client; the content
itself is covered by the same report queue that covers a bio (§12). The monthly
review is also the moderation pass.

---

## 6. Core user stories with acceptance criteria

Written as Given / When / Then so they double as the QA script.

### Customer

**US-1 — Find a worker**
_As a customer, I search for a trade in my commune so I can see who is available._
- Given I am signed in, when I select "Plonbye" and "Delmas", then I see a
  ranked list of verified plumbers serving Delmas.
- Given I have no connection, when I open search, then I see the last results I
  loaded, marked as offline.
- Given no worker matches, then I see an empty state offering to widen the
  commune, not a blank screen.

**US-2 — Judge a worker**
_As a customer, I open a profile so I can decide whether to trust this person._
- The profile shows: portrait, verified badge (or its absence), rating with
  review count, years of experience, trades, commune coverage, rate, bio,
  portfolio photos, and the three most recent reviews.
- An unverified worker is shown without the badge and is ranked below verified
  workers. The badge is never implied by styling alone.

**US-3 — Request a job**
- Given I am on a profile, when I tap Hire, then I supply a description,
  preferred date and address, and submit.
- The worker receives a push notification within 60 seconds.
- The request appears in my Jobs tab as `pending`.

**US-4 — Agree terms**
- A chat thread is created with the job; both parties can send text and photos.
- Messages are delivered offline-first: queued locally, sent on reconnect.

**US-5 — Settle and review**
- When the worker marks the job complete, I receive an invoice (agreed amount +
  10% platform fee, itemised).
- I settle via MonCash, or confirm cash — cash stays `unpaid` until the worker
  confirms receipt.
- After settlement I am prompted once to rate and review. I can decline.
- My review is published immediately and is visible on the worker's profile.

### Worker

**US-6 — Get verified**
- I upload a government ID; it goes to an admin-only Storage path.
- I am told my status is `pending`, and notified on approval or rejection.
- Rejection states a reason.

**US-7 — Answer a request**
- I receive a push notification with the job summary.
- I accept or decline; declining asks an optional reason and returns the job to
  the customer as `declined`.
- Accepting moves the job to `accepted` and notifies the customer.

**US-8 — Get paid**
- On completion I issue the invoice from the job screen.
- My earnings screen shows paid, pending and this-month totals.

**US-11 — Name your own trade**
_As a worker whose trade is not in the list, I type it so customers can still
find and book me._
- Given I open My trades, when none of the tiles is what I do, then I type it
  into "Other trade" and it appears as a chip on my profile.
- Given I type something the app already lists, however I spelled it, then it
  selects that listed trade instead and tells me so — I am not filed into a
  bucket nobody browses.
- I can add up to 3, at 40 characters each; removing the last one clears my
  Other status.
- My typed trade is searchable by name, appears under the Other tile, and a job
  booked with me records that wording.

### Admin

**US-9 — Hold the trust floor**
- A queue of pending verifications with the ID document and profile side by side;
  approve or reject with a reason.
- A queue of reports with the reported user, reporter, context and history;
  suspend, dismiss or escalate.
- Review moderation: publish, hide, delete.

### Cross-cutting

**US-10 — Language**
- I pick my language before sign-up and can change it in Settings.
- Every string, empty state, error and push notification renders in my language.
- A notification written last week renders in whatever language I read **today**
  (notifications store a catalog key + arguments, never rendered text).

---

## 7. Screens in the MVP

Bottom navigation: **Home · Search · Jobs · Messages · Profile**

| Area | Screens |
| --- | --- |
| Onboarding | Splash, language picker, intro, role picker |
| Auth | Sign up, log in, phone + OTP, forgot password |
| Home | Greeting, search bar, popular trades, top-rated nearby, recent jobs |
| Search | Results list, filter sheet (trade, commune, rating, price, verified-only), categories grid |
| Worker | Profile, portfolio viewer, all-reviews |
| Jobs | Job list (customer & worker views), job detail, booking/request form |
| Messages | Conversation list, chat thread |
| Reviews | Write review |
| Worker tools | Dashboard, profile edit, earnings, verification upload |
| Settings | Profile, settings (language, notifications, theme), report sheet, emergency button |
| Admin | Dashboard, verifications, reports, reviews, users |

**Deliberately not in the MVP:** onboarding tutorial carousel beyond 3 slides,
in-app help centre, referral screen, worker analytics beyond earnings.

---

## 8. Design and brand

### Identity

| Token | Value | Use |
| --- | --- | --- |
| Royal Blue | `#0B3D91` | Primary |
| Heritage Red | `#C8102E` | Accent — sparingly; reserved for emphasis, never for destructive actions alone |
| Warm Ivory | `#F4F1E8` | Light background |
| Palm Green | `#2E8B57` | Success, verified badge |

Type: **Poppins** headings, **Inter** body. Light and dark themes, both shipped.
Rounded cards, soft elevation, generous spacing, large type — the Airbnb/LinkedIn
register, not a utility-app register.

### On photography

The brief asks for heritage imagery — Citadelle Laferrière, Sans-Souci, Marché
en Fer — to communicate pride and trust. Kept, with two constraints:

1. **One hero, one place.** Heritage imagery appears on the home hero and
   onboarding only. Past that it competes with the content and starts reading as
   a tourism app — the exact failure the brief warns against.
2. **Everywhere else, the photography is of workers.** Real Haitian
   electricians, plumbers, masons, mechanics and tailors at work. This is what
   builds trust in a marketplace; a fortress does not.

**This is a real dependency, not a styling note.** Licensed heritage shots and a
commissioned worker-portrait shoot must be budgeted and started in week 1 —
placeholder stock will make the app look like every other template. Track it as
a launch blocker. Accessibility: every image needs alt text in all three
languages; text over the hero must clear WCAG AA against the blue overlay.

---

## 9. Success metrics

**North star:** completed-and-settled jobs per week in the launch area.

Targets are for **week 12 after opening the customer side**. They are starting
proposals — agree them with stakeholders before launch; a metric nobody has
committed to is decoration.

| Metric | Target | Ties to |
| --- | --- | --- |
| Verified workers in launch area | 150 | Supply |
| Completed-and-settled jobs / week | 60 | North star |
| Job request → accepted | ≥ 60% | A1 |
| Median time to first worker response | < 30 min | A1 |
| Accepted → completed | ≥ 75% | A2 |
| Completed jobs with an in-app settlement record | ≥ 50% | A3 |
| Completed jobs that receive a review | ≥ 40% | A4 |
| Worker 4-week retention (≥ 1 job accepted) | ≥ 50% | Supply health |
| Customer repeat rate (2nd job within 90 days) | ≥ 25% | Demand health |
| Crash-free sessions | ≥ 99.5% | Quality |
| Disputes / reports per 100 completed jobs | < 3 | Trust |
| Share of new worker profiles using **Other** | watch, no target | The catalog's own error rate (§5.5) |

**Guardrails — investigate immediately if breached:** any suspended worker who
completed a job in the prior 7 days; any report unactioned for > 48h; median
search-results load > 3s on 3G.

**Kill / pivot criteria.** If by week 12 request→accepted is under 30% **and**
median response time is over 2 hours, the supply side does not work as designed.
Stop building features; go back to worker interviews.

---

## 10. Non-functional requirements

| Area | Requirement |
| --- | --- |
| Platforms | Android 8+ and iOS 14+. Android is the priority — it is the market |
| Network | Every screen must be usable on 3G. Search results, job list and chat history read from local cache first, network second |
| Payload | Images served at display resolution and cached; no screen over ~1.5 MB cold. Data is expensive here |
| Performance | Cold start < 3s on a mid-range Android; search results < 2s on 3G (cached: instant) |
| Offline writes | Chat messages and job actions queue locally and sync on reconnect, with a visible pending state |
| Localisation | Three catalogs kept at strict key + placeholder parity, enforced in CI. Kreyòl is the default for new installs in Haiti |
| Accessibility | WCAG AA contrast, dynamic type to 200%, semantic labels on every control, 44pt minimum touch target |
| Privacy | ID documents readable only by admins; phone numbers never exposed between users before a job is accepted; data deletion on account closure |
| Security | Server owns `rating`, `reviewCount`, `jobsCompleted`, `verification`, `status` — client writes are rejected by rules, not by convention |
| Observability | Crash reporting, funnel analytics for every §9 metric, and an alert on the guardrails |

---

## 11. Technology — and one decision to make

**The brief specifies React Native + Expo. This repository is a Flutter app.**

That is not a detail to resolve later, so it is the first decision in the log.
The existing Flutter codebase already implements the large majority of the MVP
scope above:

- MVVM with `provider`, services behind interfaces, `go_router` routing with
  gate-based redirects
- Firebase Auth, Firestore (offline persistence on), Storage, Cloud Messaging
- Three-language catalogs with CI-enforced parity and typed accessors
- ID verification → admin queue → badge; report flows; review moderation
- MonCash / NatCash / card / cash payment paths with a Cloud Function that never
  lets card data reach our own backend
- A demo mode with 24 seeded workers that walks the entire loop with no backend

**Recommendation: stay on Flutter.** Rewriting in Expo would discard a working
implementation of the scope this document defines, to gain nothing the MVP's
four assumptions depend on. If there is a reason to move — team skills, hiring,
an existing RN codebase elsewhere — it should be stated and decided explicitly,
and the rewrite cost should be counted against the launch date, not absorbed
into it.

| Layer | Choice |
| --- | --- |
| Client | Flutter 3.32+ / Dart 3.8+ (recommended) — or Expo + React Native, if the rewrite is decided |
| Auth | Firebase Auth — email/password, phone OTP, Google, Apple |
| Data | Cloud Firestore, offline persistence enabled |
| Files | Cloud Storage — portraits, portfolio, ID documents (admin-read only) |
| Push | Firebase Cloud Messaging |
| Server logic | Cloud Functions — payments, rating recomputation, notification fan-out |
| Payments | MonCash + recorded cash at launch; NatCash and cards behind a flag |
| Maps | Google Maps + Geolocator for commune/service-area selection |

Collections: `users`, `workers`, `jobs`, `reviews`, `chats/{id}/messages`,
`invoices`, `reports`, `notifications`. Full field-level documentation in
[`SCHEMA.md`](SCHEMA.md).

---

## 12. Trust, safety and compliance

Trust is the product. These are launch blockers, not features:

- **Identity verification** — government ID, admin-reviewed, badge on approval.
  ID scans live at `identity/{uid}/`, readable by admins only.
- **Server-owned reputation** — ratings and job counts are recomputed by a Cloud
  Function from published reviews. A client cannot write its own score.
- **Report + suspend** — reachable from profile, chat and job. Every report is
  actioned within 48h (a §9 guardrail).
- **Emergency call (114)** behind a confirmation, on home and profile.
- **Phone verification** — an OTP-verified number links to the existing account
  rather than creating a duplicate.
- **Community guidelines** — published in all three languages, accepted at
  sign-up, linked from every report sheet. **Owner needed; not yet written.**
- **Terms, privacy policy and a data-deletion path** — required by both app
  stores. **Needs legal review before submission.**

---

## 13. Plan

Twelve weeks to the customer-side opening. Weeks are indicative; the gates are
not.

| Phase | Weeks | Outcome | Gate to pass |
| --- | --- | --- | --- |
| 0 — Decide & prepare | 1 | Platform decision closed; photography commissioned; legal engaged; metrics instrumented | Section 11 decision is signed off |
| 1 — Core loop | 2–4 | Auth, profiles, search, request → accept → complete, chat, push | A customer and a worker on real devices complete a job end to end |
| 2 — Money & reputation | 5–6 | Invoices, MonCash + cash settlement, reviews, earnings | Settlement and review recorded on a real job |
| 3 — Trust | 7–8 | Verification, reports, admin console, guidelines, policies | An operator runs a full day from the console alone |
| 4 — Polish & hardening | 9–10 | Design pass, offline behaviour, accessibility, performance budgets, crash-free target | Meets every §10 requirement on a mid-range Android on 3G |
| 5 — Supply onboarding | 9–11 | 75 verified workers recruited and live, in parallel with phase 4 | 15 verified workers per launch trade |
| 6 — Closed beta | 11 | 20 customers, 30 workers, real jobs, daily triage | ≥ 20 completed jobs; no unresolved safety incident |
| 7 — Launch | 12 | Play Store + App Store, metro area | Store approval; §9 dashboard live |

**Weeks 13–24 (post-launch, in priority order):** availability calendar · card
payments once merchant access lands · ranking improvements from real data ·
second city (Cap-Haïtien) · additional trades · referral loop.

---

## 14. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Cold-start: no workers, so no customers | Fatal | Do not open the customer side below 75 verified workers. Recruit supply by hand, in person, before launch |
| Workers don't answer requests | Fatal (A1) | Push + SMS fallback; response time shown on the profile; deprioritise slow responders in ranking |
| Transactions move to WhatsApp and cash, off-platform | High — kills the fee and the review loop | Make in-app settlement the easiest path; tie reviews and the badge to recorded jobs |
| MonCash integration slips | High | Launch cash-recorded-only if it does; the loop still tests A3 partially |
| Card/acquirer onboarding drags | Medium | Already off the critical path by design (§5.3) |
| Connectivity and data cost suppress usage | Medium | Offline-first reads, aggressive image budgets (§10) |
| Fraud, no-shows, unsafe workers | High — reputational | Verification, reports actioned in 48h, suspend, emergency button |
| Photography not ready | Medium — the app looks generic | Commission in week 1; treat as a launch blocker |
| Platform rewrite (RN) absorbed silently into the schedule | High | Section 11 decision, made explicitly, with its cost counted |

---

## 15. Open questions

| # | Question | Needed by | Owner |
| --- | --- | --- | --- |
| Q1 | Flutter or a React Native/Expo rewrite? (§11) | Week 1 | _unassigned_ |
| Q2 | Is 10% the right platform fee, and who pays it — customer, worker, or split? | Week 5 | _unassigned_ |
| Q3 | MonCash merchant account — who owns the application, and what is the real lead time? | Week 1 | _unassigned_ |
| Q4 | What legal entity operates the platform, and what does Haitian law require of a marketplace that records (but does not custody) payments? | Week 7 | _unassigned_ |
| Q5 | Is the operator role staffed, and what is the SLA on verification and reports? | Week 7 | _unassigned_ |
| Q6 | Are the §9 targets accepted as written? | Week 2 | _unassigned_ |
| Q7 | Photography budget and shoot schedule? | Week 1 | _unassigned_ |
| Q8 | Does the MVP launch building & repair, beauty & wellness, or both — and with what supply target each? (§5.4) | Week 2 | _unassigned_ |

---

## 16. Appendix — MVP scope vs. what already exists

Where the current Flutter codebase stands against Section 5. "Built" means the
code path exists and is exercised in demo mode; it does not mean it has been
validated against a production Firebase project or a real payment provider.

| MVP item | Status | Location |
| --- | --- | --- |
| M1 Auth (email, phone OTP, Google, Apple) | Built | `lib/views/auth/`, `lib/services/*auth_service.dart` |
| M2 Worker profile + portfolio | Built | `lib/views/worker/`, `lib/models/worker_profile.dart` |
| M3 Search + filters + sort | Built | `lib/views/search/`, `lib/models/search_filters.dart` |
| M4 Job lifecycle | Built | `lib/views/booking/`, `lib/models/job_request.dart` |
| M5 In-app chat | Built | `lib/views/chat/`, `lib/models/chat.dart` |
| M6 Invoices + MonCash/NatCash/cash | Built | `lib/services/payment_service.dart`, `functions/index.js` |
| M7 Reviews | Built | `lib/views/reviews/`, `lib/models/review.dart` |
| M8 ID verification + badge | Built | `lib/views/dashboard/verification_screen.dart`, `lib/views/admin/` |
| M9 Report user + admin queue | Built | `lib/views/common/report_sheet.dart`, `lib/views/admin/` |
| M10 Push notifications | Built | `lib/services/messaging_service.dart` |
| M11 Trilingual localisation | Built, CI-enforced | `assets/i18n/`, `scripts/gen_strings.py` |
| M12 Offline reads | Built | Firestore persistence + `SharedPreferences` shelves |
| M13 Admin console | Built | `lib/views/admin/` |
| Cards (Visa/Mastercard) | Built — **deferred by scope**, put behind a flag | `lib/core/utils/card_utils.dart`, `functions/index.js` |
| Beauty & wellness trades, grouped catalog | Built | `lib/core/constants/service_categories.dart` |
| **Other** free-text trade, deduped against the catalog | Built | `service_categories.dart`, `worker_profile_edit_screen.dart` |
| Search matching trade names in all three languages | Built | `lib/core/utils/worker_query.dart` |
| Launch-area restriction to metro | **Not built** — currently all ten departments | `lib/core/constants/` |
| Launch set narrowed to one vertical | **Not built** — catalog carries 15 trades + Other | `lib/core/constants/` |
| Monthly review of typed trades → catalog promotions | **No owner** | — |
| Heritage + worker photography | **Not sourced** — placeholder branding only | `assets/branding/` |
| Community guidelines, ToS, privacy policy | **Not written** | — |
| Analytics + crash reporting for §9 | **Not wired** | — |
| Response-time tracking (A1) | **Not instrumented** | — |

**Reading of this table:** the build is well ahead of the scope definition. The
remaining work to an MVP launch is mostly *not* engineering — it is narrowing
scope, sourcing photography, writing policies, instrumenting the funnel, and
recruiting 75 workers by hand.
