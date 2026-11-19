# BRAND.md — Settle

The identity system for Settle. Source of truth for the logo, app icon, brand colours
and brand font. The visual brand sheet lives on the design canvas; this file holds the
same specs in a form code can follow.

- Name: **Settle** (always capital S, never all caps, never "SETTLE" or "settle" in the logo)
- Tagline: **Hisaab barabar** (shown in all caps in the logo lockup)

---

## 1. The symbol

Two rows of bars. The top row is split **unequally** (people paid different amounts).
The bottom row is split **equally** (everyone ends up paying the same).
Left pieces use the main shade, right pieces the second shade.

### Geometry (108 × 108 unit grid, Android adaptive icon grid)

| Piece | x | y | width | height | radius | colour on teal tile |
|---|---|---|---|---|---|---|
| Top left | 30 | 37 | 30 | 12 | 3 | White `#FFFFFF` |
| Top right | 66 | 37 | 12 | 12 | 3 | Mist `#A7D9E2` |
| Bottom left | 30 | 59 | 21 | 12 | 3 | White `#FFFFFF` |
| Bottom right | 57 | 59 | 21 | 12 | 3 | Mist `#A7D9E2` |

- Horizontal gaps: 6 units. Row gap: 10 units.
- The symbol spans x 30–78, y 37–71 (48 × 34) and sits inside Android's 66-unit safe zone.
- Never change proportions, add pieces, rotate, outline or add effects.

### SVG (symbol on tile)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">
  <rect width="108" height="108" rx="24" fill="#0B8295"/>
  <rect x="30" y="37" width="30" height="12" rx="3" fill="#FFFFFF"/>
  <rect x="66" y="37" width="12" height="12" rx="3" fill="#A7D9E2"/>
  <rect x="30" y="59" width="21" height="12" rx="3" fill="#FFFFFF"/>
  <rect x="57" y="59" width="21" height="12" rx="3" fill="#A7D9E2"/>
</svg>
```

### Colour pairs by background
| Background | Tile | Main bars | Second bars |
|---|---|---|---|
| Light (white / paper) | Teal `#0B8295` | White | Mist `#A7D9E2` |
| Teal `#0B8295` | White | Teal `#0B8295` | `#6CBAC7` |
| Night `#0A3A42` | Teal `#0B8295` | White | Mist `#A7D9E2` |
| Symbol without tile, on white | none | Teal `#0B8295` | `#6CBAC7` |
| Monochrome dark | none | Ink `#14272B` | Ink `#14272B` |
| Monochrome light | none | White | White |

---

## 2. Logo lockup (symbol + name + tagline)

All sizes derive from the symbol tile size **T**:

| Element | Size |
|---|---|
| Symbol tile | T |
| Gap symbol → text | 0.25 T |
| "Settle" | Manrope Bold 700, font size 0.75 T, letter spacing −3%, line height 0.9 |
| Gap name → tagline | 0.1 T |
| "Hisaab barabar" | Manrope SemiBold 600, all caps, font size 0.155 T (min 10 px), letter spacing +20% |

- Text block is vertically centred on the symbol; name and tagline share the same left edge.
- Tagline colour: `#5C7378` on light, White on teal, Mist on Night.
- **Hide the tagline when T < 48 px.**
- Clear space: 0.25 T on every side. Minimum: symbol 16 px; lockup 24 px tall (no tagline).

Example at T = 96: tile 96, gap 24, "Settle" 72 px, gap 10, tagline 15 px.

---

## 3. Colour palette

| Name | Hex | Use |
|---|---|---|
| Teal | `#0B8295` | Primary brand colour, icon tile, primary buttons |
| Deep teal | `#0A6170` | Teal text and links on light backgrounds |
| Night | `#0A3A42` | Dark surfaces, dark mode base (instead of black) |
| Mist | `#A7D9E2` | Second bar shade, light teal tints |
| Ink | `#14272B` | Text, monochrome logo |
| White | `#FFFFFF` | Secondary brand colour |
| Slate (muted text) | `#5C7378` | Tagline and secondary text on light |

No gradients, glows, shadows or outlines on any logo element.

---

## 4. Typography

- **Manrope** (Google Fonts, SIL Open Font License) — brand font. Bundle the font files in
  `assets/fonts/` (Manrope-SemiBold.ttf, Manrope-Bold.ttf) so it works offline. Don't use
  the `google_fonts` package to fetch at runtime.
- Manrope is used **only** for: the logo wordmark, splash branding, sign-in screen logo,
  and marketing (README, website).
- All app interface text uses **Roboto** (Android system font), per DESIGN.md.

---

## 5. App icons (files in `assets/icon/`)

| File | Use |
|---|---|
| `icon.png` (1024) | Legacy launcher icon (full square, teal background) |
| `icon_foreground.png` (1024) | Adaptive icon foreground (bars only, transparent) |
| `icon_monochrome.png` (1024) | Themed icon layer, Android 13+ (white bars, transparent) |
| `notification_icon.png` (96) | Status bar notification icon (white bars, transparent) |
| `logo.png` (1024) | Rounded tile icon for README, sign-in screen, social profile |
| `symbol.png` | Symbol without tile, teal on transparent |
| `*.svg` | Vector sources of all of the above |

Adaptive icon background colour: `#0B8295`.

---

## 6. In-app usage

- **Splash screen (Android 12+ splash API):** background `#0B8295`, centre icon = symbol
  bars only (white + mist, from `icon_foreground`), no tile. Branding text "Settle" in
  white Manrope Bold at the bottom if supported.
- **Sign-in screen:** primary lockup on light background, T = 64, with tagline.
- **App bar:** no logo; use the screen title (DESIGN.md).
- **About / settings:** small lockup, T = 32, no tagline.
- Build the logo in Flutter from the SVG geometry above (a `CustomPainter` or `flutter_svg`
  with the `.svg` files), not from a scaled PNG, so it stays sharp.
- One `SettleLogo` widget with parameters: `size` (T), `variant` (light / teal / night /
  mono), `showTagline` (auto-false when size < 48).
