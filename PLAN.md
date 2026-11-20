# PLAN.md — Settle

A Splitwise-style expense splitter for Pakistani friends, roommates, families and trips.
The app is a **ledger only**: it records who paid and who owes. Money moves outside the app
(bank transfer, Raast, NayaPay, SadaPay, JazzCash, Easypaisa, cash).

App name: **Settle**. Package id: `com.settleapp.settle` (change if you prefer, before `flutter create`).

---

## 1. Hard constraints

- **Zero cost.** No paid services, no paid APIs, no custom domain.
- **Flutter** app, Android first. Built with Android Studio + Claude Code.
- **Firebase Spark (free) plan only:** Auth + Cloud Firestore.
  - No Cloud Functions (needs paid plan). All logic runs in the app.
  - No Firebase Dynamic Links (shut down in 2025).
  - No Firebase Storage (no receipt photos).
- **Auth:** Google sign-in + email/password. **No phone/SMS login.** People may add an
  optional phone number (typed, never verified, no SMS) for WhatsApp reminders (2026-11-20).
- **Distribution:** release APK on **GitHub Releases** (no Google Play developer account).
- Source code on GitHub from day one.

---

## 2. The core scene

Five friends go for chai. Ali pays Rs 1000 for chai, Sara pays Rs 500 for fries.
Total 1500, each share 300. The app shows:

- Bilal pays Ali Rs 300
- Hamza pays Ali Rs 300
- Fatima pays Ali Rs 100 and Sara Rs 200

Adding an expense must take **3 taps or fewer** in the common case:
amount + title → paid by (defaults to me) → who was there (all ticked, split equal) → Save.

---

## 3. Features

There is **one version**: everything below ships together in the first release.
Build order (§9) decides the sequence, not separate releases.

### Accounts and groups
1. Sign in with Google or email/password. Password reset by email.
2. Profile: display name, optional phone number (asked on the sign-up form, editable in
   Settings; not verified), optional payment methods (see §5).
3. Groups: name, free-text type, members.
4. Invite by **join code** + QR code, shared through WhatsApp.
5. **Placeholder members**: add friends by name before they install. They claim their name later.

### Expenses
6. Add expense with split modes: **Equal, Exact amounts, Percentages, Itemized**.
   Itemized (restaurants): items, shared items, tax and service charge spread by what each person had.
   Tax and service are each a % of the items or a rupee amount, shared by what each person
   ordered; the tip is in rupees, split equally or given by one or more people (2026-11-20); the bill total becomes the
   expense amount. A shared item (drinks) is an item with several people ticked (2026-11-20).
7. Edit/delete expense; balances always recompute.
   Multiple payers on one expense.
   Duplicate guard ("Same amount and people added 2 minutes ago. Add anyway?"): same amount
   and same people with a share, added in the last 10 minutes (2026-11-20).
   Search and filter expenses.

### Balances and settling
8. Balances per group and overall ("You owe Rs 300" / "You are owed Rs 900").
9. **Simplified settle-up** list (minimum payments).
10. Settle flow: "I paid" → creditor confirms (or creditor records payment directly).
    The amount starts at what's owed and can be changed to any amount (owner's decision,
    2026-11-20). Paying a placeholder counts straight away (nobody can confirm for them).
    One pending "I paid" per person at a time; the payer can cancel it, the creditor can
    say "Not received".
11. WhatsApp reminder (prefilled `wa.me` message, no API). Opens the person's chat when they
    added a phone number; otherwise WhatsApp asks who to send it to. Placeholders have no
    phone (owner's decision, 2026-11-20).
12. Activity log: every add/edit/delete/settle, with who did it.
13. Monthly summary per group (totals by month, computed in the app; no charts for decoration).

### App-wide
14. Offline use (Firestore offline cache).
15. English UI with light **Roman Urdu** touches (greetings, empty states, success messages,
    WhatsApp reminders). Money lines, buttons and errors stay in English. See DESIGN.md §10.
16. Light and dark mode.

### Not included (needs a paid service)
- Receipt photos: Firebase Storage needs the paid Blaze plan for new projects (verify before deciding).
- Push notifications: sending them needs a server or Cloud Functions. Use in-app notices
  (pending confirmations shown on open) and WhatsApp reminders instead.

### Removed from scope (owner's decision, 2026-11-19)
Don't build these or suggest them back unless the owner asks.
- Committee (BC/kameti) tracking.
- Export group to CSV.
- Shares split mode (units per person) — owner's decision, 2026-11-20. Equal, Exact and %
  cover it.
- Recurring expenses (rent, internet) — owner's decision, 2026-11-20. Not for now.
- Full Urdu (Urdu script) language and RTL layout — owner's decision, 2026-11-20. The UI is
  English with Roman Urdu touches only.

---

## 4. Money rules (must never be wrong)

- Store all amounts as **integers in paisa** (`int`). Never `double`. Rs 300 = `30000`.
- Display whole rupees by default; show paisa only if non-zero.
- Every expense resolves to a list of **shares**: `{memberId: amountOwed}`.
  The sum of shares **must equal** the expense total exactly. Save is blocked until it does.
- **Rounding:** split, floor each share, give leftover paisa one at a time to participants
  in a stable order (payer first). Totals must always match to the paisa.
- **Balances are never stored.** Compute from all expenses + settlements every time.
  Editing or deleting an old expense then stays correct automatically.
- Split mode only decides how shares are produced. The balance and settle-up math only
  ever sees `paid` and `shares`.

### Net balance
For each member: `net = totalPaid − totalShares + settlementsPaid − settlementsReceived`.
Positive = is owed. Negative = owes. Sum of all nets in a group = 0 (assert this in tests).

### Simplify debts
1. Split members into creditors (net > 0) and debtors (net < 0).
2. Match the largest debtor with the largest creditor; transfer `min(|debt|, credit)`.
3. Repeat until all are zero. Result: at most `n − 1` payments.

### Split modes
| Mode | Input | Validation |
|---|---|---|
| Equal | tick participants | at least 1 participant |
| Exact | amount per person | sum = total; show "Rs X left to assign" live |
| Percent | % per person | sum = 100% |
| Itemized | items → people, plus tax/service/tip | tax and service by each person's subtotal; tip equally or by chosen people |

### Worked examples (use as unit tests)
- **Chai:** 1000 by A + 500 by B, 5 people equal → A +700, B +200, C/D/E −300.
- **Gaming zone:** 1000 by A, exact: A 300, B 500, C 200, D 0, E 0 → B pays A 500, C pays A 200.
- **Restaurant:** Ali steak 1500, Sara 600, Bilal 600, Hamza 500, shared drinks 800,
  10% tax, paid by Ali → Ali +2530, Sara −880, Bilal −880, Hamza −770.
- **Rounding:** Rs 1000 among 3 → 333.34 / 333.33 / 333.33, total exactly 1000.

---

## 5. Payment methods

- Optional. A user can add any number.
- Fields: **name** (free text, e.g. "Meezan Bank", "Nayapay", "Sadapay", "JazzCash"),
  **account title**, **account number / IBAN / Raast ID**. No preferred flag (owner,
  2026-11-20): every method is always shown, in the order added.
- Suggestion chips for common names, but any text is allowed. No strict format validation.
- Shown at settle-up to the person paying (in the "I paid" sheet), each with a copy button.
- Saved on the profile and every member doc in one batch, so it never half-saves offline.
- Visible only to people who share a group with the owner.

---

## 6. Groups, invites, placeholders

- **Group type** is free text with suggestions (Friends, Trip, Home, Office, Family).
- Each group has a short **join code** (e.g. `CHAI-4821`) and a QR code of that code.
- **Invite** opens WhatsApp share:
  "Join our group on Settle. Code: CHAI-4821. Download: <GitHub release link>"
- **Join flow:** install → sign in → enter or scan code → "Which one are you?" list of
  unclaimed placeholders → tap your name (merges history) or "I'm not listed" (new member).
- **Placeholders** can't log in. Any real member can add expenses involving them.
- Any member can **remove an unclaimed placeholder**, only while its balance is zero
  (owner's decision, 2026-11-19). It's hidden, not deleted, so past expenses keep their names.
- Creator can regenerate the join code (old code stops working).
- Members can leave only when their group balance is zero.
- When you are the **only real member left**, you can delete the group (owner's decision,
  2026-11-19). It deletes the group, all its subcollections and its join code from the app
  (no Cloud Functions), so it needs a connection. Confirmed by dialog.

---

## 7. Data model (Firestore, starting point)

```
users/{uid}
  displayName, email, createdAt
  phone                           // optional, "+923001234567" or ""; not verified
  paymentMethods: [{ id, name, accountTitle, accountNumber }]

groups/{groupId}
  name, type, createdBy, createdAt, joinCode, currency: "PKR"
  memberUids: [uid, ...]          // real users only; used by security rules

groups/{groupId}/members/{memberId}
  displayName, uid (null for placeholder), claimedAt, joinedAt, active
  paymentMethods: [...]           // copy of the user's own, for settle-up (§5)
  phone                           // copy of the user's own, for reminders; "" for placeholders

groups/{groupId}/expenses/{expenseId}
  title, amount (paisa), date, createdBy (uid), createdAt, updatedAt, deleted (soft delete)
  splitMode: "equal" | "exact" | "percent" | "itemized"
  payers: { memberId: paisa }     // sums to amount
  shares: { memberId: paisa }     // sums to amount
  splitInput: { ... }             // raw input so the expense can be edited in the same mode
  note

groups/{groupId}/settlements/{settlementId}
  from (memberId), to (memberId), amount (paisa), status: "pending" | "confirmed"
  createdBy (uid), createdAt, confirmedAt

groups/{groupId}/activity/{activityId}
  type, actorMemberId, targetId, summary, before, after, createdAt
  // summary is data (expense title / member name), not UI text; the app
  // builds the localized sentence from type.

joinCodes/{code}
  groupId                          // lookup for joining (get only, never listed)

joinCodes/{code}/joins/{uid}
  groupId, joinedAt                // proof the joiner had the current code
```

Membership uses `memberId` (not `uid`) everywhere in expenses, so placeholders and claimed
members work the same way. Claiming a placeholder just sets `uid` on the member doc
(after joining has added the uid to `memberUids`).

**Joining:** the joiner writes `joinCodes/{code}/joins/{uid}` and adds their own uid to
`memberUids` in one batch. The rules allow that only if the joins doc exists under the
group's *current* code. Regenerating deletes the old code doc, so old codes stop working.
Then the joiner can read members and pick "Which one are you?" (claim) or "I'm not listed".

### Security rules (must ship with the release)
`firestore.rules`, tested on the Firestore emulator (`firestore-tests/`; the run command is at the
top of `rules.test.js`). Decisions (2026-11-19):
- Group and subcollections: only users in `memberUids`. Nobody can add someone else.
- `users/{uid}`: owner only. Payment methods are copied onto the member doc so group-mates
  see them (the "store a copy on the member doc" option).
- Members are never deleted. Placeholders: any member adds/renames; only you can claim one
  for yourself, and only while unclaimed.
- Phone: you set it on your own profile and member docs only; placeholders never have one.
- Expenses: soft delete only; `createdBy` must be you and can't change; amounts must be
  integer paisa.
- Settlements: "I paid" only by the payer; confirm only by the person paid; the person paid
  (or anyone, if they're a placeholder) can record a confirmed payment directly.
- Activity: append-only, and you can only log actions as your own member.
- Join codes: get by exact code only; only the creator regenerates.
- Deleting: only when `memberUids` is exactly you; then the group, its subcollections and its
  join code may be deleted.
- Never ship with open test-mode rules.

**Rules can't check these** (no loops or balance math in rules), so the app enforces them
and the money core rejects bad stored data (such expenses are left out of balances):
payers/shares summing to the amount, and "leave only when your balance is zero".

---

**Reads:** a group's subcollections are listened to while its screen is open, and also while
Home is open (Home shows your balance in each group, DESIGN.md §11). Fine for a handful of
groups on the free plan; revisit if someone has many large groups.

## 8. Screens

1. Sign in (Google, email/password, reset password)
2. Sign up asks for name and phone; payment methods are added in Settings (no separate
   profile setup screen, owner 2026-11-20)
3. Home: overall balance, group list with per-group balance, Add expense
4. Group: Expenses | Balances | Settle up
5. Add / edit expense (amount, title, paid by, split)
6. Expense detail (who paid, who owes what, history)
7. Settle up: payment list → "I paid" sheet with the amount and the creditor's payment methods
   (owner, 2026-11-20: in the sheet, not a separate screen)
8. Join group (code / QR / claim name)
9. Group settings (name, type, members, add placeholder, join code)
10. Activity
11. Settings (name, password, payment methods, sign out)

See DESIGN.md for how each one should look.

---

## 9. Build order

1. Flutter project, Firebase connected (Android), Google + email sign-in working on a real phone
   (debug **and** release SHA-1 added in Firebase).
2. Money core as pure Dart with unit tests: shares, rounding, net balances, simplify. No UI.
3. Firestore models, repositories, security rules.
4. Create group, add placeholders, join code + QR, claim flow.
5. Add expense: Equal split. Group expenses list.
6. Balances + settle-up list.
7. Settle flow + WhatsApp reminder.
8. Exact / Percent splits, then Itemized and multiple payers.
9. Edit/delete + activity log + duplicate guard.
10. Payment methods + settle-up pay screen.
11. Search/filter, monthly summary.
12. Dark mode pass.
13. Polish against DESIGN.md, test on a low-end phone, release APK on GitHub Releases.

---

## 10. Testing

- Unit tests for every money function, including all §4 examples and random property tests
  (shares sum to total; group nets sum to 0; simplify output settles everyone).
- Widget tests for add-expense validation.
- Manual test on a low-end Android phone with slow/offline network.

---

## 11. Release

- `flutter build apk --release` (consider `--split-per-abi` for smaller files).
- Sign with a release keystore. **Keep the keystore and its password backed up and out of git.**
  Losing it means users can't update without reinstalling.
- Upload to GitHub Releases with short release notes.
- The repo must be public before the first release: invites link to
  `github.com/rafayfarooq768/Settle/releases/latest` (`lib/core/config/app_links.dart`),
  and private-repo releases don't open for friends. Restrict the API key first.
- Share the release link in WhatsApp groups.
