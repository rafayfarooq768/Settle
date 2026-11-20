# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Settle starts with the owner's own circle: friends, roommates and family in Pakistan, invited
over WhatsApp. They use it after shared spending (chai and dinners out, rent and bills at
home, trips) to record who paid and see who owes whom. Wider sharing comes later, only if it
goes well (owner, 2026-11-20).

## Product Purpose

A Splitwise-style expense splitter for Pakistan. It is a **ledger only**: it records who paid
and who owes, and money moves outside the app (bank transfer, Raast, Nayapay, Sadapay,
JazzCash, Easypaisa, cash). Success means a group stops arguing about the hisaab: adding an
expense takes three taps or fewer in the common case, and the settle-up list shows the
fewest payments that make everyone even.

## Positioning

Confirmed by the owner (2026-11-20), against Splitwise:
- **Free, with no premium tier.** No ads, no paid features, no daily limits.
- **Made for Pakistan.** Rupees and paisa, the payee's Raast / Nayapay / JazzCash / bank
  details shown in the "I paid" sheet with copy buttons, WhatsApp reminders, a little Roman
  Urdu where it adds warmth.
- **Restaurant bills.** An itemized split where tax, service charge and tip are shared by
  what each person ordered.

## Operating Context

- Groups form in WhatsApp: the invite is a join code and QR code shared there, and the
  reminder is a prefilled WhatsApp message (no API).
- Phones are often cheap Android devices on weak or no data. The app works offline from the
  Firestore cache and syncs later.
- Installed as an APK from GitHub Releases, not the Play Store.

## Capabilities and Constraints

- Everything in PLAN.md §3 ships in one release: Google and email sign-in, groups, join code
  and QR, placeholder members who claim their history later, Equal / Exact / Percent /
  Itemized splits, multiple payers, edit/delete with Undo, duplicate guard, balances,
  simplified settle-up, "I paid" → confirm flow, WhatsApp reminders, activity log, search
  and filter, monthly totals, light and dark mode.
- Zero cost: Firebase Spark plan only (Auth + Firestore). No Cloud Functions, Storage, push
  notifications, Dynamic Links or paid APIs.
- No phone/SMS login. A phone number is optional, typed, never verified, and used only to
  open WhatsApp chats.
- Money is integer paisa; shares always sum exactly to the amount; balances are computed,
  never stored.
- Removed from scope by the owner: committee (BC/kameti), CSV export, shares split mode,
  recurring expenses, Urdu-script language and RTL, receipt photos, a separate profile setup
  screen.
- Terms used in the UI: group, expense, placeholder ("not joined yet"), settle up, "I paid",
  record payment, remind, payment method.

## Brand Commitments

- Name **Settle** (capital S), tagline **Hisaab barabar**. Logo, colours and Manrope brand
  font are fixed in BRAND.md; the logo files are in `assets/icon/`.
- Voice: English, short and plain, second person, with a light Roman Urdu touch (greetings,
  empty states, success messages, reminders). Never Roman Urdu in money lines, buttons,
  errors or payment screens. No jokes about debt.

## Evidence on Hand

- No users, testimonials, ratings or download counts yet. Nothing like that may appear in
  the app, README or release notes.
- The PLAN.md §4 worked examples (chai, gaming zone, restaurant, rounding) are the
  reference cases for money behaviour.

## Product Principles

1. Never wrong about money: to the paisa, every time, offline too.
2. Fast over fancy: instant on a cheap phone with weak data.
3. Plain words: "You owe Ali Rs 300", always with who, direction and amount.
4. Fits how friends already settle: WhatsApp, Raast and wallets, cash; the app never
   touches the money.
5. Free for good: nothing that would ever need a paid service.

## Accessibility & Inclusion

Cheap Android phones on weak data and offline, readable text contrast (4.5:1) in light and
dark mode, tap targets at least 48dp. Nothing beyond this was requested (owner, 2026-11-20).
