# CLAUDE.md — Settle

Read these before doing any work:
- **@PLAN.md** — what we're building, constraints, money rules, data model, build order.
- **@DESIGN.md** — how it must look and behave. Its §12 checklist: add those things only if
  very, very necessary (owner, 2026-11-20).
- **DESIGN (3).md** — DESIGN.md plus the 2026-11-20 polish notes (type table, row anatomy,
  vertical rhythm, empty states). Check it too; DESIGN.md wins where they differ, and
  off-grid values in it are snapped to the 4/8/12/16/24/32 scale.
- **@BRAND.md** — logo, app icon, brand colours and brand font. Logo files are in `assets/icon/`.

If a request conflicts with PLAN.md or DESIGN.md, point out the conflict before writing code.
When a decision changes the plan, update PLAN.md in the same change.

## Project
**Settle**: a Splitwise-style expense splitter for Pakistan. Ledger only: the app never moves money.

## Non-negotiable constraints
- Flutter, Android first. Material 3.
- Firebase **Spark (free) plan**: Auth + Firestore only.
  - No Cloud Functions, no Dynamic Links, no paid APIs, no Storage.
- There is one release containing every feature in PLAN.md §3. No "v1/v2" split.
- Auth: **Google + email/password only. No phone/SMS auth.** An optional, unverified phone
  number on the profile, used only to open WhatsApp reminders, is allowed (owner, 2026-11-20).
- Distribution: APK via GitHub Releases. No Play Store assumptions.
- Never suggest or add a dependency or service that costs money. If something needs a paid
  plan, say so and propose a free alternative.

## Money code rules
- Amounts are `int` paisa. **Never use `double` for money.**
- Shares for every expense must sum exactly to its amount; payers too.
- Balances are computed from expenses + settlements, never stored.
- Money logic lives in pure Dart (`lib/core/money/`) with no Flutter or Firebase imports,
  and is fully unit tested. Use the worked examples in PLAN.md §4 as tests.
- Any change to money logic must keep `flutter test` green. Add a test for every bug fixed.

## Code conventions
- State management: Riverpod. Navigation: go_router. (Don't introduce alternatives.)
- Structure by feature: `lib/features/<feature>/{data,domain,ui}`, shared code in `lib/core/`.
- Firestore access only through repository classes; no Firestore calls in widgets.
- All user-facing strings in ARB files (`lib/l10n/`). No hardcoded UI strings. English only
  (no Urdu-script locale, owner 2026-11-20).
- UI language is English with a little Roman Urdu, following DESIGN.md §10 "Roman Urdu touches".
  Never use Roman Urdu in money lines, buttons, errors or payment screens.
- Theme defined once in `lib/core/theme/` from DESIGN.md tokens. Widgets use
  `Theme.of(context)`; no hardcoded colours, sizes or radii in widgets.
- Spacing only from the DESIGN.md scale (4, 8, 12, 16, 24, 32) via constants.
- Keep widgets small; extract when a build method gets long.
- Run `dart format .` and `flutter analyze` with zero warnings before finishing a task.

## Firestore
- Security rules live in `firestore.rules` and must be updated with any schema change.
- Never leave test-mode (open) rules.
- Keep reads low: listen to a group's subcollections only while its screen is open.

## Secrets
- Never commit: release keystore, `key.properties`, any passwords.
- `google-services.json` is fine to commit for this project, but restrict the API key in
  Google Cloud Console.

## Workflow
- Work in the build order from PLAN.md §9. One step at a time, small commits.
- Before UI work, re-check DESIGN.md §12 checklist. After UI work, review the screen against it.
- Test on a real Android phone when possible; check slow/offline behaviour.
- When unsure about product behaviour, ask instead of guessing.
