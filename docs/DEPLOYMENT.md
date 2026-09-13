# Deployment

From an empty machine to apps in both stores. Steps 1–3 are enough to run the
app against a real backend; 4–6 are for release.

## 0. Prerequisites

```
flutter --version          # 3.32 or newer
dart --version             # 3.8 or newer
node --version             # 20 (Cloud Functions)
npm i -g firebase-tools
dart pub global activate flutterfire_cli
```

Generate the platform folders once — they are not committed:

```
flutter create .           # recreates android/ and ios/
flutter pub get
```

Then apply `docs/PLATFORM_SETUP.md` (permissions, Maps key, push entitlement).

## 1. Create the Firebase project

```
firebase login
firebase projects:create jwenn-met            # or use the console
firebase use jwenn-met
```

In the console enable:

* **Authentication** → Email/Password, Google, Apple, Phone.
  For Phone, add your test numbers while developing.
* **Firestore** → production mode, region `nam5` (or closest to Haiti).
* **Storage** → same region.
* **Cloud Messaging** → note the Server key for later.

Wire the apps up:

```
flutterfire configure --project=jwenn-met
```

This writes `lib/firebase_options.dart`, `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist`. All three are gitignored on purpose —
they are per-project, and the iOS/Android files carry bundle identifiers you do
not want in a public repo.

## 2. Deploy rules, indexes and functions

```
firebase deploy --only firestore:rules,firestore:indexes,storage
cd functions && npm install && cd ..
firebase deploy --only functions
```

Set the wallet secrets before the payment functions are used:

```
firebase functions:secrets:set MONCASH_CLIENT_ID
firebase functions:secrets:set MONCASH_CLIENT_SECRET
firebase functions:secrets:set NATCASH_MERCHANT_ID
firebase functions:secrets:set NATCASH_API_KEY
firebase functions:secrets:set PAYMENT_WEBHOOK_SECRET
```

Then fill in the two provider calls marked in `functions/index.js` and register
`https://<region>-<project>.cloudfunctions.net/paymentWebhook` as the callback
URL in each merchant dashboard.

## 3. Seed data and create the first admin

```
export GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
node scripts/seed_firestore.js --project jwenn-met --auth
```

`--auth` creates `customer@demo.ht`, `worker@demo.ht` and `admin@demo.ht`
(password `demo1234`) and grants the admin custom claim to the last one. For a
production launch, seed without `--auth`, then grant yourself admin:

```
node -e "require('firebase-admin').initializeApp();require('firebase-admin').auth().setCustomUserClaims('<uid>',{admin:true})"
```

The claim reaches the device on the next token refresh — sign out and back in.

Run the app against the real backend:

```
flutter run --dart-define=DEMO_MODE=false \
            --dart-define=PAYMENTS_BASE_URL=https://us-central1-jwenn-met.cloudfunctions.net
```

### Local emulators

```
firebase emulators:start
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
  node scripts/seed_firestore.js --project demo-jwenn-met --auth
```

## 4. Branding

```
python3 scripts/generate_branding.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## 5. Android release

```
keytool -genkey -v -keystore ~/jwennmet-upload.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` (gitignored):

```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/absolute/path/jwennmet-upload.jks
```

Reference it from `android/app/build.gradle` (`signingConfigs.release`), then:

```
flutter build appbundle --release --dart-define=DEMO_MODE=false
```

Upload `build/app/outputs/bundle/release/app-release.aab` to the Play Console.
Add the release SHA-1 **and** SHA-256 to Firebase → Project settings, or Google
sign-in and phone auth will fail in production builds only.

Play Console checklist: data-safety form (location, photos, phone number),
target API level, and a privacy policy URL — the app links to
`https://jwennmet.ht/privacy`.

## 6. iOS release

```
flutter build ipa --release --dart-define=DEMO_MODE=false
```

* Bundle id must match the one in `GoogleService-Info.plist`.
* Sign in with Apple: enable the capability in Xcode and in the Apple Developer
  portal — Apple rejects apps offering Google sign-in without it.
* Push: upload the APNs auth key (`.p8`) to Firebase → Cloud Messaging.
* Add the usage strings from `docs/PLATFORM_SETUP.md`; App Review rejects
  builds whose location and camera prompts have no explanation.

Upload with Xcode Organizer or `xcrun altool`.

## 7. After release

* Watch `recomputeStats` (nightly, 03:00 America/Port-au-Prince) in Functions logs.
* Firestore backups: `gcloud firestore export gs://<bucket>/$(date +%F)`.
* Keep the verification queue short — the verified badge is the product's
  trust anchor; a slow queue is what makes workers leave.
