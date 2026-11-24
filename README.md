<p align="center">
  <img src="assets/icon/logo.png" alt="Settle logo" width="96">
</p>

<h1 align="center">Settle</h1>
<p align="center"><b>Hisaab barabar.</b> Split bills with friends, family and roommates in Pakistan.</p>

<p align="center">
  <a href="https://github.com/rafayfarooq768/Settle/releases/latest"><b>Download for Android</b></a>
</p>

---

Settle keeps track of who paid and who owes in a group: chai with friends, rent at home,
a trip to the north. It tells everyone the fewest payments that make the group even.

Settle **never moves money**. You pay each other the way you already do (Raast, Nayapay,
Sadapay, JazzCash, Easypaisa, a bank transfer or cash) and mark it paid in the app.

It is free, with no ads and no premium version.

## What it does

- **Groups you join with a code.** Share the code or its QR on WhatsApp. Friends who haven't
  installed yet can be added by name and claim their history when they join.
- **Expenses in three taps.** Amount and title, who paid, who was there. Split equally, by
  exact amounts, by percentage, or **by items** for restaurant bills: tax and service charge
  are shared by what each person ordered, and the tip is split however you like. One
  expense can have several payers.
- **Balances to the paisa.** "You owe Sara Rs 200", "Hamza owes you Rs 300". Shares always
  add up exactly to the bill.
- **Settle up.** The shortest list of payments that clears the group. Tap **I paid**, the
  other person confirms, done. Their bank or wallet details are shown with copy buttons.
- **WhatsApp reminders.** A friendly message, already written, opened in WhatsApp.
- **Everything is undoable and logged.** Edit or delete with Undo, an activity log of who
  did what, a warning before adding the same expense twice.
- **Search and monthly totals.** Find an expense by name or month; see what the group spent
  each month.
- **Works offline.** Add expenses with no signal; they sync when you're back online.
- Light and dark mode. Sign in with Google or email.

## Install

Settle isn't on the Play Store. You install it from this page:

1. On your Android phone, open the
   [latest release](https://github.com/rafayfarooq768/Settle/releases/latest).
2. Under **Assets**, download the APK:
   - `Settle-<version>.apk` for almost every phone from the last few years.
   - `Settle-<version>-older-phones.apk` if that one says "App not installed".
3. Open the downloaded file and tap **Install**.
   - If Android asks, allow your browser (or WhatsApp) to **install unknown apps**.
   - If Play Protect warns about an unknown app, tap **More details → Install anyway**.
     It warns about every app that isn't from the Play Store.
4. Open Settle, sign in, and create a group or tap **Join with a code**.

Needs Android 7.0 or newer.

## Updating

When a new version comes out, it's posted on the same
[releases page](https://github.com/rafayfarooq768/Settle/releases/latest).
Download the new APK and install it the same way. Android shows **Update** instead of
Install, and you stay signed in: your groups and expenses are kept.

You don't need to uninstall first. Uninstalling isn't harmful (everything is saved online),
but you'd have to sign in again.

## Privacy

- Your groups, expenses and payments are stored in Google Firebase. Only members of a group
  can see that group.
- Your payment methods and phone number are optional. If you add them, only people who share
  a group with you can see them, so they know how to pay you or remind you on WhatsApp.
- No ads, no tracking, no selling data. The app has no analytics.

---

## For developers

Flutter (Android first), Riverpod, go_router, Material 3. Firebase on the free Spark plan:
Authentication and Cloud Firestore only. No Cloud Functions, so all logic runs in the app.

### Build

```sh
flutter pub get
flutter run                                # debug on a connected phone
flutter build apk --release --split-per-abi
```

`android/app/google-services.json` is committed; its API key is restricted to this app's
package and signing keys. Release builds are signed with a keystore that is **not** in this
repo (`android/key.properties`, gitignored). Without it, release builds fall back to debug
signing so they still run locally; never publish those.

### Test

```sh
flutter test
```

- `test/core/money/`: the money core in pure Dart: splits, rounding, balances and
  simplifying debts, including the worked examples in [PLAN.md](PLAN.md) §4.
- `test/data/`: every repository against an in-memory Firestore, and a group's whole story
  from first expense to everyone settled.
- `test/screens/`: the real app and router with a fake sign-in, tapping through each screen.

Security rules are tested on the local Firestore emulator:

```sh
firebase emulators:exec --only firestore --project demo-settle "npm --prefix firestore-tests test"
```

### Money rules

Amounts are integer **paisa**, never floating point. Every expense's shares and payers sum
exactly to its amount, or it isn't saved. Balances are never stored; they are computed from
expenses and confirmed payments every time, so editing an old expense is always correct.

### Project docs

| File | What's in it |
|---|---|
| [PLAN.md](PLAN.md) | Features, money rules, data model, security rules, build order |
| [DESIGN.md](DESIGN.md) | How every screen looks and behaves |
| [BRAND.md](BRAND.md) | Logo, colours, fonts |
| [PRODUCT.md](PRODUCT.md) | Who it's for and why |
| [CLAUDE.md](CLAUDE.md) | Rules for working on the code |
