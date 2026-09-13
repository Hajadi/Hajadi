# Jwenn Mèt — Find a Skilled Worker (Haiti)

A production-shaped Flutter marketplace connecting customers with verified
skilled workers across all ten departments of Haiti: electricians, plumbers,
carpenters, masons, mechanics, painters, welders, cleaners, tailors and AC
technicians.

Trilingual end to end — **Kreyòl Ayisyen · Français · English** — with MonCash,
NatCash and cash settlement, ID verification, in-app chat and an admin console.

```
flutter pub get
flutter run          # starts in demo mode: no Firebase project needed
```

---

## What is in here

| Area | Where |
| --- | --- |
| App entry, DI, bootstrap | `lib/main.dart`, `lib/app.dart`, `lib/bootstrap.dart` |
| Theme, localization, constants, shared widgets | `lib/core/` |
| Models (users, workers, jobs, reviews, chat, invoices, reports) | `lib/models/` |
| Services (auth, data, storage, payments, messaging, location) | `lib/services/` |
| View-models (MVVM) | `lib/viewmodels/` |
| Screens | `lib/views/` |
| Translations (EN / FR / HT) | `assets/i18n/` |
| Sample dataset | `assets/sample_data/` |
| Security rules, indexes, Cloud Functions | `firebase/`, `functions/` |
| Schema, deployment, platform setup | `docs/` |

## Architecture

MVVM with `provider`, and a service layer behind interfaces:

```
views  ──watch──►  viewmodels (ChangeNotifier)  ──►  services (interfaces)
                                                       ├── FirebaseAuthService / DemoAuthService
                                                       ├── FirestoreDataService / DemoDataService
                                                       ├── FirebaseStorageService / DemoStorageService
                                                       ├── HttpPaymentService   / DemoPaymentService
                                                       └── FirebaseMessagingService / DemoMessagingService
```

Views never touch Firebase. `Services.create()` (`lib/services/service_locator.dart`)
decides once, at boot, which implementation set is live — which is what makes
demo mode possible and what keeps the whole app unit-testable.

* **Routing** — `go_router` with a single `redirect` that owns the gates:
  language → onboarding → auth → role-appropriate home
  (`lib/core/routing/app_router.dart`).
* **User-scoped state** — the job list, inbox and notification badge live in
  `UserScope` above the router, so they survive tab switches and are rebuilt
  only when the signed-in identity or role changes.
* **Offline** — Firestore persistence is enabled at boot, so every `snapshots()`
  stream replays from the local cache before the network answers. Home-screen
  shelves are additionally cached in `SharedPreferences`.

## Demo mode

`flutter run` boots with `DEMO_MODE=true`: the app reads
`assets/sample_data/` (24 workers across all ten departments, 18 jobs, reviews,
chat threads, invoices, a verification queue and open reports) and keeps writes
in memory, so the full loop — search → request → accept → complete → invoice →
pay → review — can be walked with no backend at all.

| Account | Email | Password |
| --- | --- | --- |
| Customer | `customer@demo.ht` | `demo1234` |
| Worker | `worker@demo.ht` | `demo1234` |
| Admin | `admin@demo.ht` | `demo1234` |

Phone sign-in accepts the OTP `123456`. Restarting the app resets demo data.

To run against a real project:

```
flutter run --dart-define=DEMO_MODE=false
```

If Firebase fails to initialize (no `firebase_options.dart`), the app falls
back to demo mode instead of crashing.

## Languages

The catalogs in `assets/i18n/{en,fr,ht}.json` are the single source of truth;
`lib/core/localization/strings.dart` is generated from them:

```
python3 scripts/gen_strings.py     # regenerate typed getters, verify parity
```

The generator fails if a key is missing from a catalog or if its `{placeholders}`
differ, and `test/localization_test.dart` enforces the same rule in CI. Usage is
typed: `context.l10n.requestJob`, `context.l10n.resultsCount(count: 12)`.

Haitian Creole has no bundle in `flutter_localizations` or `intl`, so `ht`
borrows the French bundle for built-in widget strings and date symbols — see
`AppLocalizations.localizationsDelegates`.

Notifications are stored as a **catalog key plus arguments**, never as rendered
text, so a notification written last week still displays in whatever language
the user reads today.

## Trust and safety

* Government ID upload → admin queue → verified badge. ID scans go to
  `identity/{uid}/` in Storage, which only an admin can read.
* `rating`, `reviewCount`, `jobsCompleted`, `verification` and `status` are
  **server-owned**: the security rules reject any client write to them, and a
  Cloud Function recomputes ratings from published reviews.
* Report a user from a profile, a chat thread or a job; reports are admin-only.
* Review moderation (publish / hide / delete) from the admin console.
* Emergency call button (114) behind a confirmation, on home and profile.
* OTP phone verification; a verified number links to the existing account
  rather than creating a second one.

## Payments

MonCash, NatCash, **Visa / Mastercard** and cash. Credentials never reach the
device: the app calls `createPayment` (Cloud Function), which verifies the
caller's ID token, confirms they own the invoice, reads the amount from
Firestore and creates the charge. Settlement arrives at `paymentWebhook`. Cash
stays `unpaid` until the worker confirms receipt in the app. Every completed job
issues an invoice with a 10% platform fee (`AppConfig.serviceFeeRate`).

### Cards, and staying out of PCI scope

The card number is never sent to our own backend. The app validates it locally
(brand, Luhn, expiry, CVC — `lib/core/utils/card_utils.dart`) and then exchanges
it for a **single-use token** with the acquirer, using the publishable key; only
that token reaches `createPayment`, which charges it with the secret key held in
Secret Manager. A 3-D Secure challenge comes back as a redirect the app opens.

```
flutter run --dart-define=DEMO_MODE=false \
            --dart-define=CARD_TOKENIZATION_URL=https://api.<acquirer>.com/tokens \
            --dart-define=CARD_PUBLISHABLE_KEY=pk_live_...
```

Leave those two defines unset and cards fall back to the acquirer's **hosted
checkout page**, where no card data touches the app at all. Either way the only
card details ever stored are the brand and the last four digits, on the invoice,
for the receipt.

**Visa and Mastercard are the only accepted schemes.** Amex and Discover are
detected purely so an unsupported card gets a clear message rather than a vague
decline; they are refused by `CardUtils.validateNumber` on the device and again
by the `ACCEPTED_CARD_BRANDS` allowlist in `createPayment`, because a client is
not something to take at its word. Configure the acquirer to offer the same two
schemes so a hosted checkout matches.

In demo mode any Luhn-valid Visa/Mastercard number (for example
`4242 4242 4242 4242`) succeeds and one ending `0000` declines.

See `functions/index.js` for the wallet and card provider hooks to fill in once
merchant access is granted.

## Tests and checks

```
flutter test                                # unit tests
python3 scripts/check_dart_sources.py       # imports, delimiters, l10n keys
python3 scripts/gen_strings.py              # catalog parity
```

Covered: search filtering and sorting (`WorkerQuery`), Haitian phone/email
validation, card validation (accepted brands, Luhn, expiry boundaries, CVC
length) and the demo payment paths, model serialization including Firestore
timestamps, invoice math, catalog parity, and the integrity of the bundled
dataset.

## Regenerating assets

```
python3 scripts/generate_sample_data.py     # assets/sample_data/*.json
python3 scripts/generate_branding.py        # app icon, adaptive foreground, splash
dart run flutter_launcher_icons             # platform icon sets
dart run flutter_native_splash:create       # splash screens
```

## Setting up the backend

`docs/DEPLOYMENT.md` walks through creating the Firebase project, seeding it
(`node scripts/seed_firestore.js --project <id> --auth`), deploying rules,
indexes and functions, and shipping to the Play Store and App Store.
`docs/SCHEMA.md` documents every collection and field.
`docs/PLATFORM_SETUP.md` covers the Android/iOS keys the plugins need
(Maps, location, camera, push).

## Requirements

Flutter 3.32+ / Dart 3.8+. Android and iOS. Platform folders are not committed;
run `flutter create .` in the project root once to generate them, then apply
`docs/PLATFORM_SETUP.md`.
