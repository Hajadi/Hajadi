# Building and launching Jwenn Mèt — the complete beginner's guide

For someone who has never written code or shipped an app.

---

## Read this first — it changes everything

**The app is already written.** Every screen, every feature in
[`MVP.md`](MVP.md), is already code sitting in this repository. Nobody needs to
build it again.

So your job is **not** to learn programming. Your job is four things:

1. Install some tools on your computer
2. Run the app, to see it working
3. Create a backend (the part that stores accounts, jobs and messages) and
   connect the app to it
4. Publish it to the Google Play Store and Apple App Store

That is assembly and configuration, not programming. A careful person who can
follow instructions can do most of it. Two parts genuinely need help, and this
guide tells you exactly which two and what to do about them.

### Some words you will keep seeing

| Word | What it actually means |
| --- | --- |
| **Terminal** (or Command Prompt) | A window where you type commands instead of clicking. It looks intimidating; it's just a text box that runs one instruction at a time |
| **Flutter** | The toolkit this app is written with. One codebase becomes both an Android app and an iPhone app |
| **Firebase** | Google's service that stores your data — user accounts, jobs, chat messages, photos. It is the app's "back office" |
| **Repository / repo** | The folder holding all the code. That's this project |
| **Emulator / simulator** | A fake phone that runs on your computer so you can test without a real device |
| **Build** | Turning the code into an actual installable app file |
| **Demo mode** | This app can run with fake data and no backend at all. It's how you'll see it working on day one |

### What it costs

| Item | Cost | When you need it |
| --- | --- | --- |
| Flutter, Firebase free tier, the code | **Free** | Now |
| Google Play Console account | **$25, once, forever** | Only to publish on Android |
| Apple Developer Program | **$99 per year** | Only to publish on iPhone |
| A Mac computer | Borrow or rent one | **Only** for the iPhone version. Android works on Windows, Mac or Linux |
| Firebase Blaze plan | Pay-as-you-go — roughly $0–25/month at small scale | Before launch (Cloud Functions require it) |
| Google Maps API | Free monthly credit covers early use | Before launch |
| A domain name for your privacy policy | ~$12/year | Before store submission |

**Start on Android.** It's cheaper, it's most of the Haitian market, and you
don't need a Mac.

### How long it takes

| Part | Realistic time |
| --- | --- |
| Part 1 — see the app running | 1–3 hours |
| Part 2 — on your own phone | 30 minutes |
| Part 3 — real backend | 3–5 hours |
| Part 4 — branding and photos | Days (waiting on a photographer) |
| Part 5 — Android release | 1–2 days, plus Google's review |
| Part 6 — iPhone release | 2–4 days, plus Apple's review |

Spread over evenings, three to six weeks is normal. Don't try to do it in a
weekend.

### The two parts you should not do alone

Be honest with yourself about these:

1. **Payment provider integration** (MonCash). Someone has to write the actual
   code that talks to MonCash's servers. The places are marked in
   `functions/index.js`, but filling them in is real programming.
2. **The store signing setup** — a few lines inside `android/app/build.gradle`.
   Small, but a typo means nothing builds.

Three ways to handle them: hire a Flutter developer for a few days; ask
MonCash whether they have an integration partner; or use an AI coding assistant
(Claude Code, Cursor) pointed at this repository — it can make those edits
while you watch. Everything else in this guide you can do yourself.

---

# Part 1 — See the app working

**Goal:** the app running on your computer with fake data, so you can click
through every screen. No backend, no accounts, no money.

### Step 1.1 — Install Flutter

Go to **flutter.dev**, click *Get started*, and pick your operating system
(Windows, macOS, or Linux). Follow their installer. It's long. Do it anyway.

> **Why this is worth the hour:** everything else depends on it. There is no
> shortcut.

When it finishes, open your Terminal (Mac: press ⌘+Space, type "Terminal".
Windows: press the Start key, type "PowerShell") and type:

```
flutter --version
```

**You should see:** something starting with `Flutter 3.32` or higher.

**If you see "command not found":** Flutter installed but your computer doesn't
know where it is. Go back to the Flutter install page and redo the step about
"Update your PATH". This trips up almost everyone; it is not you.

### Step 1.2 — Check what's missing

```
flutter doctor
```

This prints a checklist. You want green checkmarks on **Flutter** and, for
Android, **Android toolchain** and **Android Studio**.

Red X marks tell you what to install and usually give you the command. Work
through them one at a time. You can ignore anything about Xcode, iOS or CocoaPods
for now — that's the iPhone half, and you're not there yet.

**Android Studio** is a separate download (developer.android.com/studio). You
need it even though you won't really use it — it carries the Android tools and
the emulator.

### Step 1.3 — Get the code onto your computer

If you don't have the project folder yet, install **Git** (git-scm.com), then:

```
git clone https://github.com/Hajadi/Hajadi.git
cd Hajadi
```

`cd` means "change directory" — it moves your Terminal into that folder.
Everything after this must be typed while you are inside it.

### Step 1.4 — Download the app's dependencies

```
flutter pub get
```

This fetches the ~25 building blocks the app uses. Takes a minute.

**You should see:** `Got dependencies!`

### Step 1.5 — Create the phone-specific folders

```
flutter create .
```

Don't miss the dot at the end — it means "here, in this folder".

This generates the `android/` and `ios/` folders. They aren't stored in the
repository on purpose, because they contain settings unique to your own Google
and Apple accounts.

### Step 1.6 — Run it

Plug in an Android phone with USB debugging on, or start an emulator from
Android Studio (*Device Manager* → ▶). Then:

```
flutter run
```

First run takes several minutes. After that it's seconds.

### ✅ Checkpoint 1

**The app opens on a language picker: Kreyòl, Français, English.**

Pick Kreyòl. Sign in with:

| Role | Email | Password |
| --- | --- | --- |
| Customer | `customer@demo.ht` | `demo1234` |
| Worker | `worker@demo.ht` | `demo1234` |
| Admin | `admin@demo.ht` | `demo1234` |

If it asks for a phone code, type `123456`.

**Now go do the whole loop yourself, as a customer:** search for a plumber in
Delmas, open a profile, request a job, send a message. Then sign out, sign in
as the worker, accept that job, complete it, send the invoice. Sign back in as
the customer, pay it, leave a review. Then sign in as the admin and approve
somebody's ID.

Do this before anything else. You now understand your own product better than
any document can teach you — and you'll spot things you want changed while
changing them is still free.

> Everything you just did was fake. Restarting the app wipes it. That's demo
> mode, and it's exactly what it's for.

---

# Part 2 — Put it on your own phone

**Goal:** the app installed on your phone, working without the cable.

```
flutter build apk --debug
```

The file lands at `build/app/outputs/flutter-apk/app-debug.apk`. Copy it to
your phone (email it to yourself, or use a USB cable) and tap it. Android will
warn you about installing from an unknown source — allow it.

### ✅ Checkpoint 2

The app is on your phone, running in demo mode, and you can hand the phone to
someone else to try.

**Do that.** Show it to two or three workers you know — a plumber, a hair
stylist. Watch where they get confused without helping them. This is the
cheapest research you will ever do, and it's worth more than another month of
building.

---

# Part 3 — The real backend

**Goal:** real accounts, real data that survives restarting, on servers you own.

### Step 3.1 — Create a Firebase project

Go to **console.firebase.google.com**, sign in with a Google account, click
*Add project*. Name it `jwenn-met`.

Then turn on four things in the left-hand menu:

| Service | What to do | What it's for |
| --- | --- | --- |
| **Authentication** | *Get started* → enable Email/Password, Google, and Phone | How people sign in |
| **Firestore Database** | *Create database* → Production mode → region `nam5` | Users, jobs, messages, reviews |
| **Storage** | *Get started* → same region | Profile photos, portfolios, ID scans |
| **Cloud Messaging** | Already on. Just note it exists | Push notifications |

**On Phone sign-in:** add your own number as a test number while you're
developing, so you're not paying for SMS every time you log in.

### Step 3.2 — Install the connector tools

```
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

`npm` comes with **Node.js** — install it from nodejs.org first if the command
isn't found. Get version 20.

`firebase login` opens your browser to sign in. That's normal.

### Step 3.3 — Connect the app to your project

```
flutterfire configure --project=jwenn-met
```

Choose Android and iOS when it asks. It writes three files that tell the app
which Firebase project is yours. **These files are private** — they're already
excluded from the repository, which is correct. Don't post them anywhere.

### Step 3.4 — Upload the security rules

This is the most important command in this entire guide:

```
firebase deploy --only firestore:rules,firestore:indexes,storage
```

**What it does:** uploads the rules that decide who is allowed to read and
write what. Without them your database is either wide open to the world or
closed to everyone.

These rules are what make the app trustworthy — they're why a worker can't
edit their own star rating, and why only an admin can see an uploaded ID card.
They're already written. You're just uploading them.

### Step 3.5 — Upload the server code

Cloud Functions need Firebase's **Blaze** (pay-as-you-go) plan. Upgrade in the
console — set a budget alert at $25 so you can't be surprised.

```
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Step 3.6 — Fill the database with starter data

```
node scripts/seed_firestore.js --project jwenn-met --auth
```

This creates the demo workers, jobs and the three test accounts in your real
database, so the app isn't an empty shell while you're testing.

> **Before real launch, run it without `--auth`** so demo accounts with known
> passwords never exist in production.

### Step 3.7 — Run against the real backend

```
flutter run --dart-define=DEMO_MODE=false \
            --dart-define=PAYMENTS_BASE_URL=https://us-central1-jwenn-met.cloudfunctions.net
```

### ✅ Checkpoint 3

Create a brand-new account with your own email. Close the app completely.
Open it again. **You're still logged in, and your data is still there.**

That's the difference between a demo and a real app. Open the Firebase console,
click Firestore, and you'll see your own account sitting there as a row.

---

# Part 4 — Make it yours

### Step 4.1 — Phone permissions and map keys

Open [`PLATFORM_SETUP.md`](PLATFORM_SETUP.md) and copy each block into the file
it names. These are the texts Apple and Google show users — *"Jwenn Mèt uses
your location to show skilled workers near you"* — and **store review will
reject you without them.**

This is copy-and-paste, but into code files. Go slowly. Change nothing except
what the document tells you to.

### Step 4.2 — Icon and splash screen

```
python3 scripts/generate_branding.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Step 4.3 — Photography

From [`MVP.md`](MVP.md) §8, and it's a launch blocker, not decoration:

- **One** heritage image (the Citadelle) on the home screen and onboarding
- **Everywhere else, real photos of real workers working** — an electrician on
  a ladder, a hair stylist mid-braid

Hire a Haitian photographer. Budget for a day. Stock photos of strangers in
other countries will make your app look like every other template, and workers
will notice before customers do.

### Step 4.4 — The documents you must write

Store review will block you without these, and you cannot generate them
honestly from a template:

- **Privacy policy** — hosted at a real web address
- **Terms of service**
- **Community guidelines**, in all three languages

Have a lawyer look at them. This is the cheapest legal advice you'll ever buy
compared to getting it wrong.

---

# Part 5 — Publish on Android

### Step 5.1 — Create your signing key

This proves every future update genuinely came from you.

```
keytool -genkey -v -keystore ~/jwennmet-upload.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

> ### ⚠️ Back this file up in three places, today
>
> `jwennmet-upload.jks` and its password. If you lose them, **you can never
> update your app again.** Not "it's difficult" — you cannot. You'd have to
> publish a brand-new app and abandon every user and every review.
>
> Put it in a password manager, an encrypted drive, and somewhere physical.

### Step 5.2 — Wire the key in

This is the second of the two steps worth getting help with. Follow
[`DEPLOYMENT.md`](DEPLOYMENT.md) §5, or have a developer or AI assistant do it.

### Step 5.3 — Build the release file

```
flutter build appbundle --release --dart-define=DEMO_MODE=false
```

Produces `build/app/outputs/bundle/release/app-release.aab`.

### Step 5.4 — Play Console

1. Sign up at **play.google.com/console** — $25, once
2. Create the app, upload the `.aab`
3. Fill in: store listing, screenshots, the **data safety form** (be truthful:
   you collect location, photos and phone numbers), content rating, and your
   privacy policy URL
4. **Before submitting:** copy the release SHA-1 and SHA-256 from Play Console
   into Firebase → Project settings

> **Do not skip step 4.** If you do, the app works perfectly for you and then
> Google sign-in and phone login fail for every real user — and only in the
> released version, which is the hardest kind of bug to understand.

5. Start with a **closed test** — invite 20 people. Not a public launch

### ✅ Checkpoint 5

Someone who is not you installs Jwenn Mèt from the Play Store and completes a
job with a real worker.

---

# Part 6 — Publish on iPhone

Only after Android is live and stable. You need a Mac and $99/year.

Follow [`DEPLOYMENT.md`](DEPLOYMENT.md) §6. Three things reject builds most often:

- **Sign in with Apple is mandatory** if you offer Google sign-in. Not optional
- Every permission needs an explanation string (Step 4.1 above)
- Apple actually reads your privacy policy

Apple review takes 1–3 days and rejection on the first try is completely
normal. They tell you what to fix. Fix it and resubmit.

---

# Part 7 — After launch

- **Keep the verification queue short.** A slow queue is the single fastest way
  to lose workers. The badge is your whole product
- **Act on every report within 48 hours**
- **Read the custom trades monthly** ([`MVP.md`](MVP.md) §5.5) — it's a list, in
  workers' own words, of what your catalog is missing
- **Back up the database:** `gcloud firestore export gs://<bucket>/$(date +%F)`
- **Watch your §9 numbers.** If under 30% of job requests get accepted and
  workers take over two hours to reply, stop adding features and go talk to
  workers

---

# The part that isn't on this list

Everything above is mechanical. Any careful person gets through it.

What actually decides whether Jwenn Mèt works is not in this guide:

**You need 75 verified workers before you let a single customer in.**

Fifteen each across five trades, in the Port-au-Prince metro area, recruited by
hand — in person, one conversation at a time, before launch day. A customer who
searches and finds nobody never comes back, and you only get one first
impression per person.

That is months of unglamorous work, and it is the actual job. The app is the
easy part, and it's already done.

---

## When you get stuck

You will. Everyone does. In order:

1. **Read the error out loud.** They're less cryptic than they look — the
   answer is often in the last line
2. `flutter doctor` — it catches most setup problems
3. `flutter clean && flutter pub get` — fixes a surprising share of weirdness
4. Paste the exact error into a search engine. Someone has hit it before
5. Ask an AI assistant with the repository open — it can see your actual code
6. **Never paste a key, password, or the contents of `google-services.json`
   into a public forum**

## Where everything lives

| I want to… | Read |
| --- | --- |
| Understand the product and what's deliberately not being built | [`MVP.md`](MVP.md) |
| Know what data is stored and where | [`SCHEMA.md`](SCHEMA.md) |
| Do a real deployment (the developer version of this guide) | [`DEPLOYMENT.md`](DEPLOYMENT.md) |
| Set up phone permissions and map keys | [`PLATFORM_SETUP.md`](PLATFORM_SETUP.md) |
| Understand the code layout | [`../README.md`](../README.md) |
