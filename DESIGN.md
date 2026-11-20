# DESIGN.md — Settle

The app should feel like a well-made tool: calm, fast, clear about money.
**Rule zero: every element must have a purpose. Nothing is added to "look modern".**

---

## 1. Principles

1. **Numbers first.** The most important thing on any screen is an amount and who it's with.
2. **One primary action per screen.** It is visually the strongest thing. Everything else is quieter.
3. **Plain words.** "You owe Ali Rs 300", not "Outstanding balance detected".
4. **Fast over fancy.** Must feel instant on a cheap Android phone with weak data.
5. **Consistency.** Same component, same look, everywhere.

---

## 2. Colour

Flat colours only. Material 3 `ColorScheme.fromSeed` with overrides.

| Role | Hex | Use |
|---|---|---|
| Primary (Teal) | `#0B8295` | Primary buttons, FAB, selected tab, app bar accents. White text on it passes (4.5:1). |
| Deep teal | `#0A6170` | Teal text and links on light backgrounds. |
| Night | `#0A3A42` | Brand colour (logo on dark). Not used as a screen background. |
| Mist | `#A7D9E2` | Second bar shade in the logo; light teal tints. |
| Secondary | `#4E8C85` | Secondary/tonal buttons, selected chips. |
| Background | `#F7F8F8` | Screen background. |
| Surface | `#FFFFFF` | Panels (see §4), sheets. Dark mode: `#1A1F21`. |
| Text (Ink) | `#14272B` | Main text. |
| Text muted | `#5F6B6D` | Secondary text, dates, labels. |
| Outline | `#D5DBDC` | Input borders, the few dividers we use. |
| Owed (positive) | `#12884E` | "You are owed", + amounts. |
| Owe (negative) | `#D63B3B` | "You owe", − amounts, destructive actions. |

Rules:
- **Never** convey owe/owed by colour alone. Always include words or a sign: "You owe Rs 300", "+ Rs 700".
- Owed/owe colours are for money only. Don't reuse red for decoration or green for "success" toasts.
- No gradients. No glow. No translucent/frosted layers.
- Dark mode (owner's decision, 2026-11-20): **neutral near-black**, not teal. Background
  `#0F1213`, panels `#1A1F21`, raised surfaces `#22282A`/`#2A3133`, outline `#3A4245`.
  Teal only for accents (buttons, FAB, selected tab, links). Keep owed/owe hues,
  adjusted for contrast.
- **Brand colours only** (owner's decision, 2026-11-19): no purple, no extra tints. The
  "settled" state uses Deep teal (Mist on dark), never a money colour.

---

## 3. Typography

- **One font family for the interface.** Use the platform default (Roboto).
- **Manrope** is the brand font: the logo wordmark, splash and sign-in logo, and (owner's decision,
  2026-11-20) **headings**: screen titles, the big balance, section labels, sheet titles, tabs.
  Body text, lists, inputs and buttons stay Roboto. See BRAND.md.
- Logo, icon and brand rules live in **BRAND.md**.
- Use Material 3 type scale; don't invent sizes.

| Use | Style |
|---|---|
| Screen title | `titleLarge` (22) |
| Big balance on Home / Group | `headlineMedium` (28), weight 600 |
| List item primary | `bodyLarge` (16) |
| List item secondary | `bodyMedium` (14), muted |
| Labels, buttons | `labelLarge` (14), weight 500 |

- All amounts use **tabular figures** (`FontFeature.tabularFigures()`) so columns line up.
- Format: `Rs 1,200` (thousand separators, no decimals unless paisa ≠ 0). Use `Rs`, not `PKR`, in UI.
- Only one large number per screen. No oversized hero headings.

---

## 4. Spacing and layout

- 4dp base grid. Allowed values: **4, 8, 12, 16, 24, 32**. Nothing else.
- Screen horizontal padding: 16.
- List row height: min 56, 16 horizontal padding.
- Tap targets: min 48×48.
- Layout is mostly **lists**, not grids of cards. A list row is not a card.
- **Panels** (revised 2026-11-19, owner asked for more structure): related rows sit together
  on one Surface panel on the Background, with 16 side margin and a section label above it.
  Rows inside a panel are separated by a divider inset to the text (not full width).
  A panel has no border and no shadow; contrast with the background is enough.
- One level only: never a panel inside a panel, and no card per row.
- Section labels: `labelLarge`, muted, 24 above and 8 below, aligned with the panel's text.

---

### Consistency pass (owner, 2026-11-20)
Decisions from checking every screen against DESIGN (3).md's polish notes. Where DESIGN (3)
uses an off-grid value we snap to the grid (owner left it to us):
- Panels: 4 padding at top and bottom inside, so rows don't touch the rounded corners.
- Rows: 16 from the edge, **12** from the avatar or icon to the text (dividers inset to match),
  names weight 500. Rows at least 56 tall.
- Avatar initials Roboto 600 at 40% of the avatar size (16 on 40, 11 on 28).
- Section labels Manrope 14/600 (DESIGN (3) says 13; 14 keeps the Material scale).
- Home summary panel padding 16 (DESIGN (3) says 20/16; 16 stays on the grid).
- Full-width form buttons 52 tall; other buttons 48.
- Line heights and tracking per the DESIGN (3).md §3 table (`_textTheme` in `app_theme.dart`).

## 5. Shape and elevation

- Corner radius: **8** for buttons, inputs and chips; **12** for panels; sheets' top corners **16**. Nothing fully rounded except avatars and the FAB.
- Elevation: **0** by default. Only the bottom sheet and FAB may cast a shadow (Material default, not custom).
- No cards inside cards. At most one level of container on any screen.
- Dividers only between list rows where rows would otherwise blur together (e.g. expense list). No decorative borders.

---

## 6. Components

### Buttons (hierarchy must be obvious)
| Level | Widget | Example |
|---|---|---|
| Primary | `FilledButton` | Save, I paid, Confirm |
| Secondary | `FilledButton.tonal` or `OutlinedButton` | Remind, Add placeholder |
| Tertiary | `TextButton` | Cancel, Skip |
| Destructive | `TextButton` in owe-red | Delete expense |

One primary button per screen. Full-width only at the bottom of forms.

### Inputs
- `OutlinedInputBorder`, radius 8, label above or floating — pick one and use it everywhere (floating).
- Amount input (`AmountField`, owner 2026-11-20): big centred number (headlineLarge) with a muted `Rs`,
  no box, underline that turns teal while focused, thousand separators as you type, autofocus.
- Pickers (`SelectField`): look like the text fields (outlined, floating label), value inside, ▾ at
  the end, optional leading avatar/icon and helper line. Used for Paid by, Split and Date.
- Sheets start with `SheetTitle` (titleMedium).
- Errors: inline text under the field, in plain words. No popups for validation.

### Lists
- **Money label** (owner, 2026-11-20 polish): the same at the end of every row
  (`MoneyStack`). A short sentence-case word in the money colour over the amount:
  "You owe" / "You lent" / "You are owed" / "Owes" / "Gets back" in bodySmall 12/500,
  then "Rs 300" in bodyLarge 16/600, tabular. States with no amount are one quiet line in
  bodyMedium: "Settled up", "Not involved", "Paid your share" (muted), "Settled" (Deep teal).
  Sentence case, never ALL CAPS.
- Every amount at the end of a row (payments, items, settle-up) uses that same 16/600
  (`rowAmountStyle`).
- Expense row: title + "Ali paid Rs 1,000" (muted) on the left; your part on the right as a
  money label.
- **A chevron means the row opens something** (owner, 2026-11-20). Expense rows and Home group
  rows end with the money label, 8, then a muted chevron (`RowEnd`, end padding 8 so the
  chevron sits where the 16 margin was). Rows in the same panel that don't open (payments)
  keep the chevron's empty space so their amounts line up.
- Date headers group expenses (Today, Yesterday, 12 Nov).

### Avatars
- Initials on a flat **Mist** circle with Deep teal initials (dark: Deep teal with Mist). No photos.
- Placeholder members: same avatar with an outline instead of fill, and "not joined yet" muted text.
- Groups have **no avatar or tile** (owner's decision, 2026-11-20). A group row leads with its name
  in titleMedium and ends with a chevron so it reads as tappable.
- A row of up to 5 small member avatars (28dp, overlapping by 8) may show who is in a group,
  followed by "+N" if there are more. Never decorative; it opens the member list.
- The signed-in user's avatar sits at the end of the Home app bar and opens Settings.

### Icons
- Material Symbols (Outlined), one weight, 24dp.
- Icons only where they help recognition: tab bar, FAB, back, settings, copy, share, QR,
  edit (pencil), search and activity (history clock) in app bars.
- **No emoji as icons. No icon next to every heading.**

### Status indicators
- Only two needed: settlement **pending** and **confirmed**. Shown as muted text ("Waiting for Ali to confirm"), not pills.
- No badges for counts unless it's something actionable (pending confirmations).

---

## 7. Motion

- Use Flutter/Material defaults for page transitions and ripples.
- No load-in animations, no staggered list entrances, no bouncing.
- Allowed, all defined once in `lib/core/theme/app_motion.dart`:
  - **Press feedback:** buttons scale to 0.97 while pressed, 120 ms, strong ease-out
    (`Cubic(0.23, 1, 0.32, 1)`), so a tap feels heard.
  - **Bottom sheets:** drawer curve (`Cubic(0.32, 0.72, 0, 1)`), 300 ms in, 200 ms out
    (exit is faster than entry). Always opened through `showAppSheet`.
  - The standard progress indicator while a real network action runs, and a brief
    `SnackBar` after save ("Expense added" with Undo).
    It closes by itself: 2.5 s, or 4 s when it has Undo (`AppMotion`, owner 2026-11-20).
- When the phone has "Remove animations" on, press feedback and sheet motion are off.
- Never fake loading. If data is cached, show it immediately.
- The keyboard opens only when you tap a field, or with a new form's autofocus. Closing a
  sheet, dialog, date picker or screen never brings it back (owner, 2026-11-20;
  `KeyboardStaysClosedObserver` on the router).

### Whole-screen layout
Forms and single-purpose screens (sign in, sign up, reset, create group, join, change
password, invite, settings, group settings) use `ScreenLayout`: content from the top,
actions pinned to the bottom in the thumb zone, scrolling together when the keyboard is up.
No floating blocks of content in the middle of an empty screen.

## 8. Feedback and dialogs

- Prefer **Undo** over confirmation. Deleting an expense: delete, show SnackBar with Undo.
- Confirmation dialogs only for irreversible, high-impact actions: leaving a group, deleting a group,
  regenerating join code.
- Bottom sheets for small pickers (paid by, split mode). Full screens for forms.

---

## 9. Empty states

Plain text and one action. No illustrations.
- Layout (owner, 2026-11-20 polish; `EmptyState`): left-aligned with the panels, 24 below the
  top, titleMedium 16/600 line (max 280 wide), optional muted line, actions 16 below, stacked
  with 8 between: primary `FilledButton`, then `OutlinedButton`. Tab messages (errors,
  "Everyone is settled up") use the same layout without actions.
- No groups (owner, 2026-11-20): "No groups yet" (titleLarge) + muted "Split bills with friends,
  family or roommates.", then a "How it works" panel of three numbered steps (a real sequence:
  make or join a group; add what anyone paid; see who owes whom and settle up outside the app).
  [Create group] (filled) and [Join with a code] (text) pinned at the bottom, like the forms.
- No expenses: "No expenses yet." [Add expense]
- All settled: "Everyone is settled up." (Deep teal text, once)

---

## 10. Copy

- Short, specific, friendly. Second person.
- Money lines always: who + direction + amount. "You owe Sara Rs 200". "Hamza owes you Rs 300".
- WhatsApp reminder default (editable): "Salam! Rs 300 for Chai is pending on Settle. My NayaPay: 03xx-xxxxxxx"
- No marketing copy inside the app. No fake numbers, testimonials or user counts anywhere.
- All strings in ARB files (English with Roman Urdu touches). No Urdu-script locale (owner, 2026-11-20).

### Roman Urdu touches
English is the main language. A **little** Roman Urdu adds warmth and makes the app feel local.
It should sound like how friends actually text, never forced or cringe.

**Use Roman Urdu for (light, human moments):**
- Greetings: "Salam, Ali"
- Empty states: "Abhi koi expense nahi. Add expense"
- Success SnackBars: "Done! Expense add ho gaya" / "Shabash, sab settle ho gaya"
- All-settled state: "Hisaab barabar. Everyone is settled up."
- WhatsApp reminder text: "Bhai, Rs 300 chai ke pending hain"
- Gentle nudges: "Kuch bhool to nahi gaye?" (duplicate guard)

**Keep in English (clarity matters more):**
- Every money line: "You owe Sara Rs 200", "Hamza owes you Rs 300"
- Buttons and actions: Save, I paid, Confirm, Delete, Settle up
- Form labels, validation errors, settings, sign-in
- Anything about accounts, payments or security

Rules:
- Roman Urdu is a seasoning: at most one Roman Urdu phrase per screen, never in the same
  sentence as an amount the user must act on.
- Use common spellings people text with (nahi, hai, ho gaya, bhai, yaar, hisaab). Don't mix in Urdu script.
- Roman Urdu strings go in the English ARB file (they're part of the English UI).
- No Roman Urdu jokes about money, debt or shaming people who owe.

---

## 11. Key screens

**Home**
- App bar: "Salam, Ali" (the screen's one Roman Urdu phrase); your avatar at the end opens Settings.
- "Overall" section label, then a panel: the words ("You are owed", bodyLarge 16/500, in the
  money colour) over the amount (headlineMedium 28) with a small muted "Rs" (60%, weight 600),
  or "You're all settled up" in Deep teal; then a small muted line 8 below
  ("You owe Rs 300 · You are owed Rs 1,200") only if both are non-zero. Same layout as the
  Group header (`BalanceHero`), which uses headlineLarge 32.
- "Groups" label, then one panel of group rows: name (row name style, 16/500), "Friends · 4 members"
  (muted), the money label on the right ("You are owed" over "Rs 700", or "Settled up"), then a
  chevron 8 after it.
  The last row is "New group or join" in teal text with a + at the end, opening a sheet with both choices.
- Add expense (owner, 2026-11-20): a full-width primary button pinned at the bottom (16 sides,
  8 above, 16 below), not a FAB, so the short Home screen doesn't end in empty space with one
  corner button. With one group it opens Add expense directly; otherwise a sheet asks which
  group. The Group screen keeps its FAB (its list scrolls under it).

**Group**
- App bar: group name, then Search, Activity (history icon) and settings icons.
- Header (owner's decision, 2026-11-20): **no panel**. Straight on the background, aligned with
  the panel text below: a small label in the balance colour ("You are owed" / "You owe"), the
  amount under it in headlineLarge, number first. Settled: muted "Your balance" over
  "All settled" in Deep teal (Mist on dark). Then one tappable line: member avatars,
  "4 members" (muted) and a chevron, opening Group settings.
- Tabs: Expenses | Balances | Settle up.
- FAB "Add expense" (brand Teal, both modes) only once someone besides you is in the group;
  before that, "Invite friends" in the empty state is the one primary action.
- Expenses tab: one panel per day under a date label (Today, Yesterday, 12 Nov). Confirmed
  payments sit in the same list on the day they were paid ("Ali paid you", muted "Payment",
  plain amount; not money colours, a payment isn't a debt). Expenses up to the last moment the
  whole group was at zero are dimmed with "settled" (Deep teal) instead of your part
  (owner's decision, 2026-11-20). Computed in the app every time, never stored.
- Balances: list of members with net, sorted largest owed → largest owes, stacked like Home
  ("owes" over "Rs 300"; your own row says "you owe").
- Settle up: "Your payments" panel first ("You pay Ali" in owe-red / "Ali pays you" in owed-green,
  amount at the end), then "Others in the group" ("Bilal pays Ali", plain). Labels only for
  non-empty sections. One row per person. Its actions are text buttons (`RowButton`)
  under the money line: the main one teal and semibold, the other muted. No filled or
  outlined boxes (owner, 2026-11-20).
  "You pay Ali" → **I paid**; "Ali pays you" → **Record payment**, **Remind**.
  A pending "I paid" sits in that person's row and replaces its actions: Ali's row shows
  "Says they paid Rs 100" → **Confirm**, **Not received**; your row to Ali shows
  "Rs 100 sent, waiting for Ali to confirm" → **Cancel payment**. When it's refused or
  cancelled the row goes back to its usual actions. A pending payment with no matching row
  gets a row of its own. A count badge on the Settle up tab and a teal "1 payment to confirm"
  line on the Home group row are the in-app notices (no push).
- I paid / Record open a sheet: title "Pay Ali", the money line it settles, the amount
  (`AmountField`, prefilled, editable), primary action, Cancel. Remind opens a sheet with the
  editable WhatsApp message and "Send on WhatsApp". A muted line under the title says where it
  goes: "Opens your WhatsApp chat with +92 300 1234567", or that WhatsApp will ask who to send
  it to when they have no number.

**Add expense**
- Amount (autofocus) → Title → Paid by (row, opens sheet) → Split (row: "Equally between 5", opens split screen) → Save.
- Split screen (full screen, title "Split Rs 1,000"): mode selector as a `SegmentedButton`
  (Equal / Exact / %; selected segment solid Teal with white text, no pale tint, radius 8;
  selected chips the same, owner 2026-11-20), one muted line saying what to enter, then one panel of members:
  Equal ticks people; Exact / % put an inline number at the end of each row (`InlineNumberField`,
  owner 2026-11-20: no boxes): the figure on a thin underline that turns teal while typing, like
  `AmountField`, with "Rs" before it or "%" after it, the empty hint "0", and %
  show the rupees it works out to under the name. Above Done, a live line: "Rs 200 left to
  assign" (muted), "Rs 100 too much" (error colour), or "Adds up to Rs 1,000" (settled colour).
  Done is disabled until it adds up. Switching modes keeps what you typed.
  Nobody with 0 is part of the expense. Back on Add expense the Split field says "Exact amounts"
  / "By percentage" / "By items" with "Your share Rs 300" (or what's left) under it.
- Several payers (owner, 2026-11-20): the Paid by sheet's last row is "More than one person",
  opening a screen with an amount per person, the same live line and Done. Paid by then reads
  "You and Sara" / "You and 2 others" with small overlapping avatars. In the list:
  "2 people paid Rs 1,500".
- Itemized (owner, 2026-11-20: its own screen, not a 5th tab): a teal "Split a bill by items ›"
  link under the split screen's members opens "Split by items". Panels: Items (name, who had it
  or "Everyone", price; last row "Add item" in teal with +), "Tax, service and tip" (Tax and
  Service charge are each a % or Rs: the unit is a teal "% ▾" / "Rs ▾" button at the end, tap to
  switch, keeping what it comes to; a % shows its rupees under the label. Both are shared by what each
  person ordered, said in a muted line under the panel. Tip in Rs, its "Rs" in the same end slot
  so the numbers line up; once there's a tip, a "Who gives the tip" row opens a sheet: "Everyone,
  equally" (picks and closes) or tick one or more people and Done; the row then reads "Ali" /
  "Ali and Sara" / "Ali and 2 others" (owner, 2026-11-20)), then "Who owes what" once there's an item. Above Done:
  "Bill total Rs 4,400" (and "The amount changes from Rs 4,000" if you typed something else).
  An item is added or edited in a sheet: Item name, Price, "Who had it?" chips (nobody ticked for
  a new item, owner 2026-11-20), Save item, and Delete item (owe-red) when editing. The bill total becomes the
  expense amount.

**Expense detail** (step 9, 2026-11-20)
- Opened by tapping an expense row. App bar: the title, edit (pencil) at the end.
- Header straight on the background like the Group header: the amount as the one big number
  (headlineLarge, small muted "Rs"), a muted line "Today · added by Ali", then your part in
  words and money colour ("You owe Rs 300" / "You lent Rs 700", or muted "You paid your share").
- Panels: "Paid by", then the split ("Split equally", "Split by exact amounts", ... ) with an
  avatar, name and amount per person, then "History" (the expense's activity rows).
- "Delete expense" in owe-red text at the bottom. Delete goes back to the list with an Undo
  SnackBar, no confirmation (§8). A deleted expense (opened from Activity) says so in the
  header and offers "Restore expense" instead.
- Edit reuses Add expense ("Edit expense"), filled in, same split mode. Save shows
  "Done! Expense update ho gaya" with Undo, which puts the old version back.

**Search** (step 11, owner 2026-11-20)
- Opened by the search icon on the Group app bar. The app bar is the search field (autofocus,
  hint "Search expenses", no box) with a clear ✕ once there's text. It matches the title or
  note, any case.
- Under it, two `FilterChip`s: "Involves me" (you paid or have a share) and "Month ▾" (a sheet:
  "Any month" and each month that has expenses; the chip then reads "November 2026").
- Results: the same day panels and expense rows as the Expenses tab, without payments.
  Nothing matching: one muted line, "No expenses match."

**By month** (Balances tab, step 11)
- Under the member balances: "By month" label, one panel, one row per month, newest first:
  "November 2026" over muted "Group spent Rs 11,197", and at the end "Your share" (muted) over
  the amount in the row amount style, not a money colour (a share isn't a debt); "Not
  involved" when you had no share. Numbers only, no chart. Deleted and unbalanced expenses
  and payments don't count.
- Lists on screens with a FAB end with `AppSpacing.fabClearance` so it never covers a row.

**Activity**
- One panel per day under a date label, like the expense list. Row: the actor's avatar, the
  sentence ("Ali added Chai", "You" for you), an optional muted detail ("Rs 1,000 →
  Rs 1,200", "Ali paid you Rs 300"), the time at the end (bodySmall, muted). Expense entries
  open the expense.

**Duplicate guard**
- On Save of a new expense, if one with the same amount and the same people (who has a share,
  not who paid) was added in the last 10 minutes: a sheet titled "Kuch bhool to nahi gaye?",
  a muted line saying what was added and when, "Add anyway" (primary) and Cancel. A sheet,
  not a dialog: nothing is lost either way.

**Paying: methods in the I paid sheet** (owner, 2026-11-20: no separate Pay screen)
- Under the amount: "Ali's payment methods" (titleSmall, muted), then one row per method,
  in the order Ali added them: name (16/500), the account title (muted),
  the number (LTR, selectable), and a copy button at the end. No panel (the sheet is one);
  dividers between methods. Copy turns the icon into a teal tick for 2.5 s instead of a
  SnackBar (which would sit behind the sheet).
- The amount doesn't autofocus here, so the keyboard doesn't cover the methods.
- No methods: one muted line, "Ali hasn't added a payment method yet. Ask them how to pay."
  Placeholders can't have methods, so their sheet shows neither.
- No bank or wallet logos (owner, 2026-11-20): brand colours only, trademarks, and names are
  free text.

**Join**
- Code field + "Scan QR" text button. Then "Which one are you?" list of placeholders + "I'm not listed".

**Group settings**
- Panels: Group (name and type), Members (avatars; placeholders show "not joined yet"),
  Invite (join code). "Leave group" in owe-red text at the bottom; when you are the only real
  member left it becomes "Delete group" (owe-red, confirmed by dialog).
- Tapping a placeholder opens a sheet: Change name, Remove (owe-red). Remove works only at a
  zero balance and keeps their history; it isn't confirmed by dialog (nothing is lost).

**Invite**
- One panel holding the code (large, LTR) and its QR. Primary: Share on WhatsApp. Secondary: Copy code.

**Settings**
- Small lockup (T = 32, no tagline) at the top (BRAND.md §6).
- Account panel: Name (opens a sheet), Phone (optional; "Not added" or "+92 300 1234567",
  opens a sheet; saving it empty removes it), Email (read-only), Password (opens Change password).
  Google-only accounts have no Password row at all (owner, 2026-11-20).
- Payment methods panel (step 10): one row per method, in the order added: name over the
  number and a chevron at the end; the last row "Add payment method" in
  teal with a + (`AddRow`, the same row as "New group or join" and "Add item"). A muted
  `PanelNote` under it: "People in your groups see these when they pay you."
- Add / edit payment method is a full screen (a form, §8): Name with suggestion chips
  (Raast, Nayapay, Sadapay, JazzCash, Easypaisa, Meezan Bank, HBL, UBL), Account title
  (starts as your name), Account number / IBAN / Raast ID. No "preferred" flag (owner,
  2026-11-20): every method is always shown. Save; when editing, "Delete payment method" in
  owe-red, with Undo, no confirmation.
- Sign out as a text button below the panel.

---

## 12. Anti-slop checklist (review every screen against this)

Add only if very, very necessary (owner, 2026-11-20: loosened from "do not add"):
1. Gradients (any).
2. Glassmorphism, blur, frosted layers.
3. Glow on buttons, borders or backgrounds.
4. Decorative blobs or floating shapes.
5. Large or inconsistent corner radii (stick to §5).
6. Cards nested in cards.
7. Custom shadows.
8. Animations that don't explain a change.
9. Hover effects (it's a phone app; use default ripples).
10. Emoji as icons.
11. Illustrations, stock or AI-generated.
12. Purple/blue/pink colour washes.
13. More than one font family (Roboto, plus Manrope for headings and the logo).
14. Oversized headings.
15. Huge empty gaps or cramped rows (stick to §4).
16. Badges/pills/chips that aren't actionable or essential.
17. The same layout copy-pasted for screens with different jobs.
18. Icons beside headings.
19. Fake stats, testimonials, user counts.
20. Marketing or filler copy.
21. Decorative separators or borders.
22. Buttons with equal weight for unequal actions.
23. Off-grid spacing or misaligned edges.
24. Charts or dashboards nobody asked for.
25. Page-load animations.
26. Gimmicky gestures or interactions.
27. Fake loaders or progress bars.
28. One-off component styles.
29. Modals where Undo or inline text would do.
30. Anything decorative with no function.

If in doubt, remove it.
