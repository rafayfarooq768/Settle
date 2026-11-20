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

- **One font family for the interface.** Use the platform default (Roboto). Urdu: Noto Nastaliq Urdu or Noto Sans Arabic, only for Urdu text.
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
- Expense row: title + "Ali paid Rs 1,000" (muted) on the left; your part on the right
  ("you owe Rs 300" in red / "you lent Rs 700" in green / "not involved" muted).
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
- Icons only where they help recognition: tab bar, FAB, back, settings, copy, share, QR.
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
    It closes by itself: 4 s, or 6 s when it has Undo (`AppMotion`).
- When the phone has "Remove animations" on, press feedback and sheet motion are off.
- Never fake loading. If data is cached, show it immediately.

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
- No groups: "No groups yet. Create one or join with a code." [Create group] [Join]
- No expenses: "No expenses yet." [Add expense]
- All settled: "Everyone is settled up." (Deep teal text, once)

---

## 10. Copy

- Short, specific, friendly. Second person.
- Money lines always: who + direction + amount. "You owe Sara Rs 200". "Hamza owes you Rs 300".
- WhatsApp reminder default (editable): "Salam! Rs 300 for Chai is pending on Settle. My NayaPay: 03xx-xxxxxxx"
- No marketing copy inside the app. No fake numbers, testimonials or user counts anywhere.
- All strings in ARB files (English with Roman Urdu touches, plus a full Urdu locale). Layouts must survive RTL.

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
- Roman Urdu strings still go in the English ARB file (they're part of the English UI).
  The full Urdu-script translation is a separate locale.
- No Roman Urdu jokes about money, debt or shaming people who owe.

---

## 11. Key screens

**Home**
- App bar: "Salam, Ali" (the screen's one Roman Urdu phrase); your avatar at the end opens Settings.
- Summary panel: muted label "Overall", then the overall balance in one line of large text
  ("You are owed Rs 900", or "You're all settled up" in tertiary) + small muted line
  ("You owe Rs 300 · You are owed Rs 1,200") only if both are non-zero.
- "Groups" label, then one panel of group rows: name (titleMedium), "Friends · 4 members" (muted),
  your balance on the right stacked as "you are owed" over "Rs 700" (or "settled up"), then a chevron.
  The last row is "New group or join" in teal text with a + at the end, opening a sheet with both choices.
- FAB: Add expense. With one group it opens Add expense directly; otherwise a sheet asks which group.

**Group**
- App bar: group name, settings icon.
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
  non-empty sections. Your rows carry compact row buttons (`RowButton`) under the text:
  "You pay Ali" → **I paid** (tonal); "Ali pays you" → **Record payment** (tonal) + **Remind**
  (outlined). Pending ones sit at the top of "Your payments": "Ali says they paid you" →
  **Confirm** / **Not received**; "You paid Ali" with muted "Waiting for Ali to confirm" →
  **Cancel payment**. A count badge on the Settle up tab and a teal "1 payment to confirm"
  line on the Home group row are the in-app notices (no push).
- I paid / Record open a sheet: title "Pay Ali", the money line it settles, the amount
  (`AmountField`, prefilled, editable), primary action, Cancel. Remind opens a sheet with the
  editable WhatsApp message and "Send on WhatsApp".

**Add expense**
- Amount (autofocus) → Title → Paid by (row, opens sheet) → Split (row: "Equally between 5", opens split screen) → Save.
- Split screen: mode selector as a `SegmentedButton` (Equal / Exact / % / Shares), member list
  below, live "Rs X left" line when not balanced, Save disabled until balanced.

**Pay screen**
- "Pay Ali Rs 300" as the title. Ali's payment methods listed: name, account title, number, copy button.
  Preferred first. Primary button: "I paid". Secondary: Cancel.

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
- Account panel: Name (opens a sheet), Email (read-only), Password (opens Change password;
  Google-only accounts see "You sign in with Google" instead).
- Sign out as a text button below the panel.

---

## 12. Anti-slop checklist (review every screen against this)

Do not add:
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
13. More than one font family (plus Urdu font).
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
