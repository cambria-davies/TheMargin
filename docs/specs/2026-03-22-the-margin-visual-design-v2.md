# The Margin — Visual Design Specification v2

> Supersedes `2026-03-20-the-margin-visual-design.md`. This revision updates the color system, typography, manuscript stack rendering, and surface textures based on the design exploration session of 2026-03-22. Screen specifications, micro-interactions, paper surfaces, and typewriter text carry forward from v1 with font/color token substitutions noted below.

## Design Direction: "Archival"

The Margin's visual identity is rooted in the physical materiality of writing — pages accumulating into a manuscript, ink pressed into paper, the red margin line of a ruled notebook. The aesthetic is editorial and grounded, not nostalgic or skeuomorphic. Think independent literary press, not vintage shop.

The key shift from v1: **the accent is structural, not chromatic.** There is no amber, no coral, no colored accent. Hierarchy comes from weight, size, and brightness — the way an editor's eye moves across a manuscript page. In light mode, the accent is ink itself. In dark mode, it's the brightest warm white on screen.

Textures are physical but restrained — you feel paper grain on card surfaces, see ruled lines on manuscript pages, and notice the cast shadows between stacked sheets. The background is clean and flat. Materiality lives on elevated surfaces, not everywhere.

---

## Color Palette

### Accent Philosophy

No chromatic accent color. The design uses a two-tier text hierarchy where the "accent" is simply the most prominent tier:

- **Daylight:** Accent = ink (`#1A1A1A`). It's the darkest element on a light surface.
- **Lamplight:** Accent = warm white (`#FFF8F0`). It's the brightest element on a dark surface.

This means accent elements (streak numbers, progress bars, active indicators, FAB) are differentiated by being the *most extreme value on screen* — not by introducing a new hue. Dark mode compensates for the narrower brightness range with structural overrides (see Dark Mode Structural Overrides below).

### Daylight (Light Theme)

| Token | Hex | Usage | Contrast on bg |
|-------|-----|-------|----------------|
| `background` | `#F5F4F1` | App background — warm paper | — |
| `surface` | `#FDFCF8` | Cards, elevated containers | — |
| `surface-dark` | `#EAE8E3` | Pressed states, secondary surfaces | — |
| `text` | `#1A1A1A` | Primary text | 14.5:1 |
| `text-secondary` | `#4A4540` | Secondary text, labels | 6.7:1 AA |
| `text-tertiary` | `#7A756C` | Metadata, mono labels | 4.5:1 AA |
| `insights-period-tab-inactive` | `#8A8580` | Inactive labels — Insights Week/Month/Year underline tabs only | — |
| `accent` | `#1A1A1A` | Actions, highlights, streak, FAB | 14.5:1 |
| `accent-dim` | `rgba(26,26,26,0.06)` | Subtle accent backgrounds | — |
| `accent-mid` | `rgba(26,26,26,0.15)` | Medium accent (active calendar cells) | — |
| `border` | `#1A1A1A` | Primary borders | — |
| `border-light` | `#D2D5D1` | Dividers, secondary borders | — |

### Lamplight (Dark Theme)

| Token | Hex | Usage | Contrast on bg |
|-------|-----|-------|----------------|
| `background` | `#141210` | Deep warm black | — |
| `surface` | `#1E1C18` | Cards, elevated containers | — |
| `surface-dark` | `#1C1A16` | Pressed states | — |
| `text` | `#EAE2D4` | Primary text — warm cream | 13.2:1 |
| `text-secondary` | `#A09888` | Secondary text, labels | 5.4:1 AA |
| `text-tertiary` | `#787064` | Metadata, mono labels | 3.8:1 (large text) |
| `insights-period-tab-inactive` | `#757575` | Inactive labels — Insights Week/Month/Year underline tabs only (neutral grey; stronger contrast vs active than `text-tertiary`) | — |
| `accent` | `#FFF8F0` | Warm white — brightest on screen | 16.2:1 |
| `accent-dim` | `rgba(255,248,240,0.06)` | Subtle accent backgrounds | — |
| `accent-mid` | `rgba(255,248,240,0.15)` | Medium accent (active calendar cells) | — |
| `border` | `#32302A` | Primary borders | — |
| `border-light` | `#2A2824` | Dividers, secondary borders | — |

### Dark Mode Structural Overrides

When accent = warm white (`#FFF8F0`), these elements receive structural weight bumps to maintain hierarchy against the cream body text (`#EAE2D4`):

| Element | Light mode | Dark mode override |
|---------|-----------|-------------------|
| Streak number | 36px, weight 600 | **42px**, weight 600 |
| Progress bar fill | 4px ink | 4px white + subtle `box-shadow` glow |
| FAB | Ink bg, paper icon | White bg + luminous shadow, dark icon |
| Highlight insight card | 1px accent border | **2px** border, value bumped to 30px |
| Session today bar | 3px | **4px** |
| Active tab indicator | 2px | **3px** |
| Tab bar dividers | Visible | **Hidden** (too many lines on dark) |
| Week dots (today) | 3px shadow ring | Brighter glow ring |
| Active project border | 4px ink | 4px `#FFF8F0` |
| Badge ("Active") | Ink bg, paper text | White bg, dark text |

### Shared (Both Themes)

These tokens are identical in both themes — physical objects don't change color under different lighting.

| Token | Hex | Usage |
|-------|-----|-------|
| `paper` | `#F5F0E8` | Paper surfaces (log sheet, timer feed, session pages) |
| `paper-dark` | `#E8E0D0` | Paper edge, dog-ear fold |
| `paper-shadow` | `#D4C8B4` | Paper drop shadow |
| `ink-black` | `#2A2218` | Heavy ink strike |
| `ink-medium` | `#4A3E30` | Medium ink |
| `ink-dark` | `#362E24` | Dark ink — third weight in typewriter variation |
| `ink-light` | `#6A5E50` | Worn/light ink, labels on paper |
| `red-margin` | `rgba(200,80,80,0.15)` | Red margin line on ruled paper |

### Theme Philosophy

Unchanged from v1: the two themes represent the same physical objects under different lighting — not two separate skins. Ink on paper is identical in both themes. The transition feels like turning on/off a desk lamp.

### Mood Colors (Muted Ink Washes)

Unchanged from v1:

| Mood | Color | Hex |
|------|-------|-----|
| Dry | Muted rust | `#7A5C50` |
| Grinding | Warm gray | `#8A8070` |
| Steady | Olive | `#A09060` |
| Flow | Amber | `#C4956A` |
| Breakthrough | Warm gold | `#D4A85C` |

---

## Typography

| Role | Font | Weight | Usage |
|------|------|--------|-------|
| **Display** | Fraunces | 400–700 | Stat numbers, headings, streak counter, project names. Optical sizing axis: numbers get softer ball terminals at display sizes (personality) but stay crisp at body sizes (readability). |
| **Body** | Space Grotesk | 400–600 | Labels, descriptions, nav text, body copy. Bridges the mono and sans worlds — geometric but warm. |
| **Mono** | Space Mono | 400–700 | Metadata labels, progress percentages, dates, time-period tabs. Systematic, editorial. |
| **Typewriter** | Special Elite | 400 | Paper surfaces only — word counts on log form, timer tip, session pages, project stamps. Unchanged from v1. |

### Typography Rules

- **Fraunces** is the display face. Use for all stat numbers, headings, streak counts, project names, and chart values. The optical sizing axis means it adapts automatically — no need to manually adjust weights for different sizes. Use `font-variant-numeric: tabular-nums` on all number displays to prevent width shifts during count-up animations.
- **Space Grotesk** is the body/UI workhorse. Use for descriptions, labels, nav text, and any running copy. Its geometric shapes echo Space Mono without the fixed-width constraint.
- **Space Mono** is reserved for systematic/metadata text: uppercase section headers (RECENT, STREAK), progress percentages, date labels, time-period tabs (Week/Month/Year), and figure numbers. Always uppercase with `letter-spacing: 0.1em+`.
- **Special Elite** is used only on paper surfaces where the typewriter metaphor applies. Never on dark backgrounds as body text. Unchanged from v1.

### Font Bundling

Fraunces, Space Grotesk, and Space Mono are Google Fonts (OFL licensed). Bundle the following TTF weights:
- Fraunces: 400, 500, 600, 700 (regular), 400 italic
- Space Grotesk: 400, 500, 600
- Space Mono: 400, 700

Special Elite is already bundled from v1.

**Note:** Fraunces includes a variable font with an optical sizing axis (`opsz`). If using the variable font TTF, only one file is needed for all weights. If using static fonts, bundle the 4 weights listed above.

---

## The Manuscript Stack

The stack is the emotional center of the app — visual proof that invisible daily work is becoming something real.

### Rendering: SVG Illustration

The stack is rendered as an SVG with 6 visible page layers (not CSS divs). This allows for richer detail: ruled lines, margin line, dog-ear fold, watermark, and per-page drop shadows.

**Page layers (back to front):**

| Layer | Fill | Stroke | Transform |
|-------|------|--------|-----------|
| Page 1 (deepest) | `stack-back` | `stack-stroke` | rotate(-0.5deg) |
| Page 2 | `stack-back` | `stack-stroke` | rotate(0.3deg) |
| Page 3 | `stack-mid` | `stack-stroke` | rotate(-0.25deg) |
| Page 4 | `stack-mid` | `stack-stroke` | rotate(0.35deg) |
| Page 5 | `stack-top` | `stack-stroke` | rotate(-0.2deg) |
| Page 6 (top) | `stack-top` | `stack-stroke` | no rotation |

Each page has unique X offset and rotation jitter — no two pages sit identically.

**Top page detail:**
- Ruled lines (6 horizontal lines, `stack-ruled` color)
- Red dashed margin line (`rgba(200,70,70,0.22)`, stroke-dasharray 3,3 — intentionally higher opacity than the `red-margin` token (`0.15`) used on full paper surfaces, because the stack is smaller and needs the line to read at a glance)
- Ghosted italic "M" watermark (Fraunces, 4% opacity)
- Dog-ear fold in top-right corner (`stack-dogear` fill)
- Fold crease shadow line
- Right edge and bottom edge thickness lines (simulating page depth)

**SVG drop shadows:** Each page uses an `<feDropShadow>` filter for physical cast shadows. The top page has a stronger shadow (`stdDeviation: 3, opacity: 0.12`) than back pages (`stdDeviation: 2, opacity: 0.08`).

### Stack Color Tokens

These are theme-adaptive — paper is always cream, but its perceived brightness shifts under different lighting. Back pages appear slightly darker under lamplight, matching how real paper looks in dim light. The values change between themes, but the visual identity (warm cream paper) is consistent.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `stack-top` | `#FDFCF8` | `#F5F0E8` | Front pages — brightest |
| `stack-mid` | `#F5F0E8` | `#E8E2D8` | Middle pages |
| `stack-back` | `#EDE8E0` | `#DED8CE` | Back pages — darkest |
| `stack-stroke` | `rgba(0,0,0,0.12)` | `rgba(0,0,0,0.20)` | Page borders |
| `stack-ruled` | `rgba(0,0,0,0.06)` | `rgba(0,0,0,0.05)` | Ruled lines on top page |
| `stack-watermark` | `rgba(0,0,0,0.04)` | `rgba(0,0,0,0.03)` | Ghosted M |
| `stack-dogear` | `#E8E2D8` | `#D8D2C8` | Dog-ear fold fill |
| `stack-shadow` | `rgba(0,0,0,0.04)` | `rgba(0,0,0,0.3)` | feDropShadow opacity |

**Dark mode glow:** A subtle warm radial gradient behind the stack in Lamplight mode: `rgba(240,235,225,0.04)`, 260px wide ellipse centered on the stack. This simulates lamplight falling on the manuscript. Not used in Daylight.

### Geometry

Unchanged from v1:
- Width: 220px on dashboard, 180px on project detail, 80px compact, 40px thumbnail
- Pages proportional to word count: word count / 250 = visual pages
- Visual cap: 40 pages on dashboard, 15 on thumbnails
- Empty state: single blank page, slightly curled corner

### Build Animation (App Open)

Each SVG page group animates in sequentially:

1. Stagger: 0ms → 360ms (6 pages, ~70ms apart)
2. Per-page animation: `translateY(-18px) → translateY(1.5px) → translateY(-0.5px) → translateY(0)`, 350ms, ease-out-expo
3. Stack shadow fades in after last page lands (~1s)
4. Stats count up (ease-out cubic, ~900ms) after stack completes
5. Progress bar fills (1s ease-out) after stats
6. Streak card and recent sessions fade in last

Total sequence: ~1.5 seconds.

### Save-to-Stack Transition

Unchanged from v1.

---

## Texture & Depth

Three layers of physical texture, applied selectively:

### 1. Paper Noise on Elevated Surfaces

A subtle SVG fractal noise pattern at **3.5% opacity** applied to:
- Streak card
- Project cards
- Insight stat cards
- Chart panel

This gives elevated surfaces a tactile paper-stock quality — you feel texture on the cards but not on the flat background. The noise is generated via inline SVG `<feTurbulence>` (no external assets).

**Not applied to:** App background, tab bar, nav bar, session rows, or any non-card surface.

### 2. Surface Elevation in Dark Mode

In Lamplight, cards and containers use `surface` (`#1E1C18`) rather than `background` (`#141210`). This 10-point lightness step creates visible lift — cards feel like they're sitting on a darker desk surface. In Daylight this distinction is handled by borders alone (the surface/background difference is minimal).

### 3. Clean Background

No grid, no texture on the app background in either theme. The warm paper color (`#F5F4F1` light / `#141210` dark) is texture enough. All materiality lives on elevated surfaces and the manuscript stack.

---

## Global Elements (Updated)

### Tab Bar

- 3 tabs: Home, Projects, Insights
- Space Mono 8px labels, uppercase, `letter-spacing: 0.12em`
- Icons: SF Symbols — `doc.text` (Home), `books.vertical` (Projects), `chart.bar.fill` (Insights). 16px.
- Active: accent color + 2px underline indicator (top edge)
- Inactive: `text-tertiary`
- Border-top: primary border
- No inter-tab vertical dividers in dark mode
- Background: matches `background` token, transitions with theme

### Pen FAB (Home Only)

- 48px circle, bottom-right, floating above tab bar
- Background: `accent` token (ink in light, warm white in dark)
- Icon: compose pen, colored `surface` (inverse of background)
- Shadow: `0 4px 16px` soft elevation — **not** hard offset shadow (iOS convention)
- Dark mode: luminous shadow (`rgba(255,248,240,0.12)`)
- 44pt minimum touch target

### Streak Card

- Stacked-note effect: 3 bordered layers offset by 4px each (main card + 2 pseudo-layers behind)
- Paper noise texture on all three layers
- Transitions background smoothly on theme change
- In SwiftUI: implement as `ZStack` with 3 offset `RoundedRectangle` views

### Project Cards

- Bordered, `surface` background, paper noise texture
- Red margin line (1px, `red-margin` color) running vertically at left-padding position
- Current project: 4px left accent border
- Press state: standard iOS highlight (slight dimming), not hard-shadow lift
- Margin line offset adjusts for current-project's thicker border

### Progress Bar

- 4px tall, rounded ends
- Track: `border-light` color
- Fill: `accent` color
- Dark mode: subtle glow shadow on fill

---

## Screen Specifications

All screen layouts carry forward from v1 (`2026-03-20-the-margin-visual-design.md`) with these substitutions:

### Token Renames

| v1 token | v2 token | Notes |
|----------|----------|-------|
| `text-dim` | `text-secondary` | Same role, improved contrast values |
| `text-faint` | `text-tertiary` | Same role, improved contrast values |
| `surface-raised` | `surface-dark` | Renamed — used for pressed/secondary states. "Hover" dropped (not an iOS interaction). |
| `amber` | `accent` | Fundamental change: no longer a color, see Accent Philosophy |
| `amber-dim` | `accent-dim` | |
| `amber-mid` | `accent-mid` | |
| `amber-glow` | (removed) | Replaced by `stack-glow` in dark mode only (see Stack section) |

### Font Substitutions

| v1 font | v2 font | Notes |
|---------|---------|-------|
| Newsreader | Fraunces | Display/numbers. Optical sizing axis adds personality at large sizes. |
| Literata | Space Grotesk | Body/labels. Geometric sans, bridges mono and sans. |
| JetBrains Mono | Space Mono | Metadata labels. Square, systematic. |
| Special Elite | Special Elite | Unchanged — paper surfaces only. |

### New Tokens (no v1 equivalent)

| Token | Usage |
|-------|-------|
| `border` | Primary borders (replaces various inline border colors in v1) |
| `border-light` | Dividers, secondary borders |
| `insights-period-tab-inactive` | Inactive label color for Insights Week/Month/Year underline tabs |
| `stack-top`, `stack-mid`, `stack-back` | SVG stack page fills (new rendering approach) |
| `stack-stroke`, `stack-ruled`, `stack-watermark`, `stack-dogear`, `stack-shadow` | SVG stack detail elements |
| `stack-glow` | Radial gradient behind stack in dark mode (replaces `amber-glow`) |

### Size & Layout Changes from v1

| Element | v1 | v2 | Rationale |
|---------|----|----|-----------|
| Stat number | Newsreader 28pt, two numbers side-by-side | Fraunces 52pt, single hero number + secondary "+today" line | Stronger visual hierarchy, one focal point |
| FAB | 56pt | 48pt | Slightly smaller, less dominant |
| Tab icons | 18pt | 16pt | Proportional to smaller tab label |
| Tab labels | 9pt | 8pt | Space Mono reads slightly larger than Literata at same size |
| Stack build stagger | 60ms per page | ~70ms per page (6 SVG groups, 0-360ms) | Fewer visual elements, slightly slower for SVG detail |
| Stack page animation | translateY(-20pt) | translateY(-18pt) | Slightly tighter bounce |
| Number count-up | 400-600ms | 900ms, starts after stack completes | Choreographed sequence |
| Dashboard bottom section | Recent sessions list (4 rows) | Writing tip + attribution | Recent sessions accessible via "hold to peek" on stack; tip reduces redundancy |

All other sizes, positions, and behaviors from v1 remain unchanged.

### Dashboard Changes

- Nav bar: Project selector in Fraunces italic (not Special Elite uppercase). Settings gear + theme toggle (moon/sun icon) on right.
- Manuscript stack: SVG illustration (see Stack section above), with warm glow in dark mode.
- Stats: Single large number (Fraunces 52px) + "words" label (Space Mono 9px uppercase). Today's count shown as "+1,500 today" on a separate line (Space Mono 11px, accent color for the number).
- Streak: Rendered in the stacked-note card component.
- Writing tip: Below the streak card, replacing v1's recent sessions list (recent sessions are now accessible via the "hold to peek" interaction on the stack, making a separate list redundant). The tip displays in Space Grotesk 13px italic, `text-secondary` color, with attribution in Space Mono 9px `text-tertiary`. Tips rotate using the same random-without-repeat logic from v1's tip rotation service. The tip area fades in last in the dashboard build sequence.

### Insights Changes

- Time period toggle: underline-style tabs (not pill/segment control). Active label and indicator use **accent** (ink Daylight, warm white Lamplight). Inactive labels use **insights-period-tab-inactive** — neutral grey with more separation from active than `text-tertiary`. Full-width **1px** baseline (`border-light`) behind the row; selected segment gets the **3px** (Lamplight) / **2px** (Daylight) accent bar drawn on top of the baseline.
- Week calendar cells: bordered, accent border on active day.
- Stat cards: paper noise texture, highlight card uses accent border. **Values:** Fraunces semibold **26pt** (Lamplight highlight **30pt** — matches structural override table). **Labels:** Space Mono **8pt** uppercase, letter-spacing **0.1em** (`variant-type-fraunces.html` `.ig-val` / `.ig-label`).

---

## Micro-Interactions

Unchanged from v1 except:
- Number count-up timing: 900ms (slightly longer, starts after stack builds)
- Theme toggle: 300-400ms transition on all themed properties (background, color, border)

---

## Mood Icons & SVG Icon Specs

Carried forward from v1 — all mood icons (dry nib, stone, seedling, infinity, 4-point star), their ink-drawn SVG rendering, and the mood color palette remain unchanged.

**Updated stroke colors for v2 tokens:**
- On dark surfaces: stroke `text` token (`#EAE2D4` in Lamplight) — replaces v1's hardcoded `#E8DFD0`
- On paper surfaces: stroke `ink-black` (`#2A2218`) — unchanged

All other SVG icon specs (stroke-width 1.4, linecap round, linejoin round, SwiftUI Shape paths) carry forward from v1.

---

## Paper Surfaces & Typewriter Text

Unchanged from v1. Paper surfaces (log sheet, timer feed, session pages) continue to use:
- `#F5F0E8` background with SVG noise at **3% opacity** (note: this is distinct from the 3.5% noise on card surfaces — paper is smoother)
- Ruled lines, red margin line, paper shadow
- Special Elite with ink variation and micro-jitter

---

## Sound Design (Deferred — V2)

Unchanged from v1.

---

## iOS Implementation Notes

These are not part of the visual spec but inform implementation:

- **Safe areas:** Nav padding and tab bar bottom padding must use `safeAreaInset` — not hardcoded values.
- **Touch targets:** All interactive elements need 44pt minimum tap area. Week dots (10px visual) should be wrapped in 44pt hit areas.
- **FAB shadow:** Use SwiftUI `.shadow()` modifier with soft radius — not hard offset.
- **Stacked-note streak card:** Implement as `ZStack` with 3 `RoundedRectangle` views, offset by 4px each.
- **SVG stack:** Implement as SwiftUI `Shape` paths or a bundled SVG asset with CSS custom property equivalents as SwiftUI color tokens.
- **Font bundling:** Add Fraunces (variable or 4 static weights), Space Grotesk (3 weights), Space Mono (2 weights) as bundled TTFs. Recommended: use the Fraunces variable font file (`Fraunces[SOFT,WONK,opsz,wght].ttf`) for automatic optical sizing. If using static weights, the optical sizing behavior is baked into each weight file.
- **Fraunces optical sizing in SwiftUI:** The variable font's `opsz` axis activates automatically when registered via `CTFontManagerRegisterFontsForURL`. SwiftUI's `Font.custom("Fraunces", size:)` will use the correct optical size for the requested point size. No special configuration needed for static weight files.
- **Tabular nums in SwiftUI:** `font-variant-numeric: tabular-nums` maps to `UIFontDescriptor` with `[UIFontDescriptor.FeatureKey.type: kNumberSpacingType, .selector: kMonospacedNumbersSelector]`. Wrap in a helper: `Font.custom("Fraunces", size: 52).monospacedDigit()` works for system fonts but for custom fonts, apply the descriptor at `UIFont` level and bridge to SwiftUI via `Font(uiFont)`.
- **Theme transition:** Use SwiftUI `.animation(.easeInOut(duration: 0.35))` on themed color properties for smooth desk-lamp transition.
- **Units:** All "px" values in this spec map directly to SwiftUI points (1:1 on @2x and @3x displays). The 8pt tab label size is intentional — Space Mono reads larger than most fonts at equivalent sizes due to its wide letter spacing and tall x-height.

---

## Reference Mockup

The final validated HTML mockup is at `variant-output/variant-type-fraunces.html`. This file demonstrates both themes (toggle via moon/sun icon), the animated SVG stack, paper noise texture, ink accent system, and all three tab screens. Use as visual reference during implementation — not as a pixel-perfect spec.
