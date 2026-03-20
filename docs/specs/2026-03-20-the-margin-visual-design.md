# The Margin — Visual Design Specification

## Design Direction: "Ink Still Wet"

The Margin's visual identity is rooted in the physical materiality of writing — typewriter keys striking paper, ink that varies in density, pages accumulating into a manuscript. The aesthetic is sophisticated and literary, not nostalgic or skeuomorphic. Think Criterion Collection packaging, not a pirate treasure map. Textures are subtle — you feel paper grain more than you see it. Shadows are physically accurate, not dramatized.

---

## Color Palette

### Lamplight (Dark Theme)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#1A1A18` | App background — ink black, nearly neutral |
| `surface` | `#242422` | Cards, elevated containers |
| `surface-raised` | `#2E2E2A` | Hover states, secondary surfaces |
| `text` | `#E8DFD0` | Primary text on dark backgrounds |
| `text-dim` | `#908880` | Secondary text, labels |
| `text-faint` | `#605850` | Tertiary text, disabled states |
| `amber` | `#C4956A` | Primary accent — actions, highlights, streak |
| `amber-dim` | `rgba(196,149,106,0.15)` | Subtle amber backgrounds |
| `amber-mid` | `rgba(196,149,106,0.4)` | Medium-intensity amber |
| `amber-glow` | `rgba(196,149,106,0.08)` | Radial glow behind the stack |

### Daylight (Light Theme)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#F5F0E8` | Warm cream — like good paper stock |
| `surface` | `#FFFDF7` | Bright white surface — cards, elevated containers |
| `surface-raised` | `#F0EBE0` | Hover/pressed states, secondary surfaces |
| `text` | `#2C2418` | Rich dark brown, near-black |
| `text-dim` | `#8A7E6A` | Secondary text, labels |
| `text-faint` | `#A89E8E` | Tertiary text, disabled states |
| `amber` | `#A07850` | Accent — slightly deeper for contrast on light |
| `amber-dim` | `rgba(160,120,80,0.12)` | Subtle amber backgrounds |
| `amber-mid` | `rgba(160,120,80,0.3)` | Medium-intensity amber (calendar cells) |
| `amber-glow` | _not used_ | No radial glow in Daylight — light doesn't glow in light |

**Daylight paper:** Paper surfaces use `#FFFDF7` (the `surface` token) rather than `#F5F0E8`, so they are visually distinct from the background. Paper distinguishes itself by being slightly brighter white with a subtle border and softer shadow.

### Shared (Both Themes)

| Token | Hex | Usage |
|-------|-----|-------|
| `paper` | `#F5F0E8` | Paper surfaces (log sheet, timer paper feed, session pages) |
| `paper-dark` | `#E8E0D0` | Paper edge, dog-ear fold |
| `paper-shadow` | `#D4C8B4` | Paper drop shadow |
| `ink-black` | `#2A2218` | Heavy ink strike |
| `ink-medium` | `#4A3E30` | Medium ink |
| `ink-dark` | `#362E24` | Dark ink — third weight in typewriter variation |
| `ink-light` | `#6A5E50` | Worn/light ink, labels on paper |
| `red-margin` | `rgba(200,80,80,0.15)` | Red margin line on ruled paper |

### Theme Philosophy

The two themes represent the same physical objects under different lighting — not two separate skins. Ink on paper is identical in both themes (`ink-black`, `ink-medium`, `ink-light` don't change). Metal surfaces (platen, carriage) shift in value but not hue. The amber accent darkens slightly in Daylight for contrast. The transition feels like turning on/off a desk lamp.

### Mood Colors (Muted Ink Washes)

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
| **Typewriter** | Special Elite | 400 | Word counts, typed text on paper, project stamps, chapter tags, timer tip text |
| **Display** | Newsreader | 300–600 | Stat numbers, section titles, streak counter, headings. Use old-style numerals. |
| **Body** | Literata | 300–500 | Labels, descriptions, notes, nav text, body copy |
| **Mono** | JetBrains Mono | 300–400 | Timer digits, progress percentages, duration pills, hex values |

### Typography Rules

- **Special Elite** is used only on paper surfaces or where the typewriter metaphor applies (log form, timer paper feed, session pages, project stamps). Never on dark backgrounds as body text.
- **Newsreader** is the display serif — numbers should feel typeset, not digital. Use for word counts on dark backgrounds, stat cards, and headings.
- **Literata** is the workhorse — readable at small sizes, warm without feeling antique.
- **JetBrains Mono** is reserved for the timer screen and data annotations where precision matters.
- The "stamped but clean" feel comes from slightly heavier weight than expected, generous letter-spacing on labels, and old-style figures. Not from distressed fonts or faux-vintage effects.

---

## The Manuscript Stack

The stack is the emotional center of the app — visual proof that invisible daily work is becoming something real.

### Geometry

- Each page: rounded rectangle, paper-colored (`#F5F0E8`)
- Width: **220px** on the dashboard, 180px on project detail, 80px compact, 40px thumbnail
- Height: **7px** per page on dashboard (6px elsewhere, 3–4px at small sizes)
- **Jitter**: each page has unique translateX (±1.5px) and rotation (±0.2°) — no two pages sit identically
- Top page: slightly taller (8px) with a deeper shadow
- Paper edge: subtle gradient on the right edge simulating thickness
- Shadow under the stack: radial gradient ellipse, grounding it on a surface
- Subtle amber radial glow behind the stack on the dashboard

### Page Count

Pages are proportional to word count: **word count ÷ 250 = visual pages**. The stack grows over time as the writer logs sessions.

**Visual cap:** The stack displays a maximum of **40 visual pages** on the dashboard. Beyond 40, each visual page represents a larger word-count chunk (total words ÷ 40). This keeps the stack at a maximum height of ~280px — tall enough to feel substantial, short enough to fit on screen with stats and sessions below. The stack always looks proportionally complete: at 50% of goal, it's visibly half as tall as a full stack would be.

**Thumbnail stacks** on project cards use the same proportional logic, capped at 15 visual pages.

### Without a Goal

The stack still grows and displays total word count — there's just no progress bar or percentage.

### Empty State

A single blank page, slightly curled at the corner. Inviting, not sad.

### Build Animation (App Open)

Every time the user opens the app, the stack builds from nothing:

1. Pages land one by one with settle-bounce physics. Stagger is dynamic: 60ms for ≤20 pages, compressed to fit ~1.2s total for larger stacks (e.g., 40 pages at 30ms stagger).
2. Each page animates: `translateY(-20px) → translateY(2px) → translateY(-1px) → translateY(0)` with jitter applied, ~350ms per page
3. Stack shadow fades in at 50% build completion
4. Stats count up (ease-out cubic, ~600ms) after pages finish
5. Progress bar fills (1s ease-out) after stats
6. Streak and recent sessions fade in last

Total sequence: ~1.5 seconds. The whole dashboard choreographs itself.

### Save-to-Stack Transition (After Logging)

1. **Paper lifts** — the log sheet lifts slightly (translateY -4px, shadow deepens), 200ms
2. **Form compresses** — text fades, paper scaleY 1 → 0.08, becoming page-thickness, 400ms
3. **Page multiplies** — compressed page splits into N pages (word count ÷ 250), slight horizontal jitter, 300ms
4. **Pages cascade onto stack** — one by one (150ms stagger), each with settle-bounce. Stack page count and word total update as each page lands. Amber highlight fades to paper-white after landing.
5. **Stack settles** — brief confirmation types out in Special Elite: "Five new pages." Fades after 2 seconds. Streak counter ticks up if first session today.

Total: ~2 seconds from Save tap to settled dashboard.

---

## Screen Specifications

### 1. Dashboard (Home Tab)

**Layout (top to bottom):**

- **Nav bar**: Project selector (Special Elite uppercase, left) + settings gear icon (right). No app branding. No daily tip — the tip lives exclusively on the timer screen and the post-save confirmation. The dashboard is pure progress. Tapping the project selector opens an action sheet with the active project list.
- **Manuscript stack**: Hero element, centered, with amber radial glow. Build animation on app open.
- **Stats**: Two numbers centered below the stack — Total Words and Today — in Newsreader 28px.
- **Progress bar**: 220px wide, 4px tall, amber fill. Percentage label in JetBrains Mono.
- **Streak**: Own row below progress — "14 day streak" (Newsreader 22px amber + Literata 12px) left, "best: 21" (Literata italic) right. Thin divider line below.
- **Recent sessions**: "RECENT" label, then 4 session rows. Each row: amber dot (glowing for today, dim for past), date (Literata 13px), word count (Newsreader 17px), mood glyph.
- **Tab bar**: 3 tabs — Home, Projects, Insights. Evenly spaced.
- **Pen FAB**: 56px amber circle, bottom-right, floating above tab bar. Compose pen icon. The FAB only appears on the Home screen.

**Pen FAB Behavior:**

- Tap: popup rises above the FAB with two options — "Start Session" (timer icon, amber circle) and "Log Session" (pen icon, surface circle). No subtitles.
- Background dims (50% black overlay).
- Pen icon rotates to × for dismiss.
- Tapping outside dismisses.

### 2. Timer Screen

**Purpose:** Active writing companion — open while the user writes.

**Layout:**

- Timer digits: JetBrains Mono 56px, centered. Colon pulses (opacity animation).
- "Writing" status label: Literata 10px uppercase.
- Play/pause + stop controls: 44px circles, amber border for active, red-tinted for stop.
- **Literal typewriter carriage mechanism:**
  - Carriage rail: metal gradient bar (3px tall)
  - Carriage slider: 20px metal block that tracks typing position, slides right-to-left
  - Amber print-guide dot at the bottom of the slider (glows in Lamplight, no glow in Daylight)
  - Platen/roller: 28px cylinder with rubber texture (repeating linear gradient), realistic metal gradient
  - Platen knobs: 14px circles on each end, radial gradient for 3D appearance
  - Paper feed: cream paper emerging from under the platen, with grain texture and ruled lines
- **Typewriter tip**: Types out letter-by-letter on the paper feed in Special Elite. Ink variation on characters (nth-child color alternation). Cursor blinks twice before first character. Carriage slider moves right with each character. At line end: soft ding (if sound enabled), slider snaps back to left margin, brief pause, next line begins.
- Attribution: Literata italic, 50% opacity, below the tip.

**States:** Running → Paused → Running → Stopped → Log Session Fields (duration pre-filled)

### 3. Log Session Fields (Modal Sheet)

**Design:** The form IS a sheet of ruled paper — cream background, paper grain texture, red margin line, ruled lines. Fields exist on the paper, not in input boxes.

**Fields (top to bottom):**

- **Project stamp**: Special Elite 13px, bordered, slight rotation (-1°). Defaults to last-used project.
- **Duration pill** (if from timer): JetBrains Mono 11px, subtle background. Shown but not editable. When logging directly (not from timer), this field is omitted — duration is optional and only captured via the timer.
- **Word count** (hero field): Special Elite 42px. Blinking cursor appears on focus. Characters appear with typewriter strike animation (scale 1.15→1, translateY bounce, 60ms). Per-character ink density variation (3 weights) and micro-jitter (±0.5px Y, ±0.4° rotation).
- **Chapter/section tag**: Special Elite 14px, optional. Recent tags as quick suggestions.
- **Mood selector**: 5 circles in a row (36px each). Three moods use ink-drawn SVG icons (dry nib, stone, seedling); two use typographic glyphs (∞, ✦). Tapping triggers ink-wash fill animation (radial gradient expanding from center, 400ms). Selected state: solid mood color with icon/glyph in paper color.
- **Notes**: Special Elite 13px, line-height matching ruled lines (28px). Freeform, expandable.
- **Save button**: Special Elite 14px uppercase, ink-black background, paper color text. Ink stamp texture overlay.

**Mood Icons:**

| Mood | Icon | Type | Concept |
|------|------|------|---------|
| Dry | Pen nib (wide, with slit and breather hole) | Ink-drawn SVG | The pen that won't write — intention without ink |
| Grinding | Rounded stone (with faint surface crack) | Ink-drawn SVG | A boulder you're pushing uphill |
| Steady | Seedling with two leaves | Ink-drawn SVG | Growth made visible — showing up, building |
| Flow | ∞ (infinity) | Typographic glyph | Unbroken movement — the pen never lifts |
| Breakthrough | ✦ (4-point star) | Typographic glyph | A sharp, focused spark — something unlocked |

**SVG Icon Specs:** All ink-drawn icons use stroke-width 1.4, stroke-linecap round, stroke-linejoin round. On dark surfaces: stroke `#E8DFD0`. On paper surfaces: stroke `#2A2218`. Icons are rendered as SwiftUI `Shape` paths, not image assets, so they scale cleanly and respond to theme colors.

**Design goal:** Log a session in under 15 seconds.

### 4. Projects Tab

**Project List:**

- **Nav**: "Projects" title (Newsreader 20px, left) + "+ New" text link (Literata 12px amber, right).
- **Project cards**: Surface background, 12px radius. Each card contains:
  - Mini manuscript stack thumbnail (proportional height to word count) — left side
  - Project name (Newsreader 16px), word count (JetBrains Mono 11px), goal text, progress bar (if goal set), "Last session: [date]" italic
  - "Current" badge (amber pill) on the last-used project
  - Chevron (›) on the right
- **Archived section**: Collapsed by default. "Archived" label + count badge. Expanded: dimmed cards (60% opacity), muted stacks.

**Project Detail (Push View):**

- **Nav**: ← Projects (back), Edit (right)
- **Project name**: Newsreader 22px
- **Compact stack + stats**: Side-by-side layout. Mini stack (80px wide) on left, stats on right (total words, session count, progress bar, projected completion date).
- **Session history as pages**: Each session is a physical paper sheet:
  - Cream paper with grain texture, ruled lines, red margin line, dog-ear fold
  - Overlapping with negative margins (-24px), each slightly rotated (±1°)
  - Content: date (Special Elite uppercase), mood glyph, word count (Special Elite 28px with ink variation), chapter tag, duration pill, notes (Literata italic)
  - Session number in bottom-right corner (#23, #22...)
  - Today's page: amber left-edge glow
  - Long-press (iOS): page lifts (-6px) and straightens — like picking a page off the pile
  - Tap to edit, swipe to delete

### 5. Insights Tab

**Layout (single scrollable page, top to bottom):**

- **Nav**: "Insights" title (left) + project filter pill (right) — "All Projects ▾"
- **Writing frequency calendar**: No label — toggle (Week/Month/Year) is the entry point.
  - **Month view**: 7-column grid, cells with day numbers. Amber intensity scales with word count (4 levels: none, light, medium, heavy). Today: amber border. Legend at bottom.
  - **Week view**: Single row of 7 tall cells showing word count inside each day. Swipeable by week.
  - **Year view**: Classic heatmap — 52 columns × 7 rows, tiny cells. Month labels along top.
- **Stat cards (2×2 grid)**:
  - Avg words/session, Avg duration, Best day of week (highlighted, amber value), This week's total
- **Streaks**: Current streak (Newsreader amber) + longest streak all time. Displayed as a compact row between stat cards and the bar chart.
- **Words by day of week**: Bar chart, 7 bars. Best day in solid amber, rest in surface-raised. Values above, day labels below.
- **Words per week trend**: 8-week line chart on surface card. Amber line + gradient fill. Dashed average line with label. Key data points labeled. Current week dot with ring glow. Summary row below: +X% vs. average, this week total, avg/week.
- **Mood distribution**: Horizontal bars with mood icon, text label, bar, percentage. Muted ink-wash colors per mood.
- **Goal progress**: Card with project name (Special Elite stamp), percentage (Newsreader amber), progress bar, word count fraction, projected completion date.

**Empty state** (< 7 sessions): Encouraging message — "Log a few more sessions and your patterns will start to emerge."

### 6. Settings

Accessed via gear icon in the Home nav bar. Not a tab. (The PRD labels this as a tab, but the visual design intentionally reduces the tab bar to 3 items — Home, Projects, Insights — to keep it clean.)

Uses standard iOS form controls (toggles, pickers) on the dark `background` color. No paper metaphor — settings is a utility screen, not a writing surface.

- Daily reminder notification toggle + time picker
- Default project selection
- Data export (CSV) — via ShareLink / UIActivityViewController
- About / credits

### 7. New/Edit Project (Modal Sheet)

Uses the paper-surface treatment (same as Log Session) to stay on-brand. Fields are typed on ruled paper.

- Project name text field
- Word count goal (optional number field)
- Starting word count ("Words already written" — default 0)
- Archive toggle (edit only)

Tapping "Edit" on the Project Detail view opens this sheet pre-filled. Archive toggle is available here.

---

## Micro-Interactions

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| Typewriter character strike | scale(1.15) → scale(1), translateY(-2px) → 0 | 60ms |
| Mood ink-wash fill | Radial gradient expanding from center | 400ms |
| Page land (save/build) | translateY(-20px) → bounce → settle, with jitter | 350ms |
| Streak increment | Subtle scale pulse | 200ms |
| Timer tip typewriter | Letter-by-letter, cursor blinks 2× before start | ~3 chars/sec |
| Carriage return | Slider snaps left, brief pause | 150ms snap + 300ms pause |
| Tab switching | Crossfade, not slide | 200ms |
| Session page hover | translateY(-6px), rotation straightens | 300ms cubic-bezier |
| Progress bar fill | Width 0% → target, ease-out | 1000ms |
| Number count-up | Ease-out cubic | 400–600ms |

---

## Global Elements

### Tab Bar

- 3 tabs: Home, Projects, Insights
- Literata 9px labels
- Icons: SF Symbols — `doc.text` (Home), `books.vertical` (Projects), `chart.bar.fill` (Insights). 18px.
- Active: amber, Inactive: text-faint
- 1px top border (rgba white 4%)
- Sticky at bottom

### Pen FAB (Home Only)

- 56px amber circle, bottom-right corner
- Box shadow: `0 4px 20px rgba(196,149,106,0.35)`
- Compose pen icon (`pencil.line` SF Symbol or custom SVG), stroke `#1A1A18`
- Only appears on the Home tab

### Paper Surfaces

Anywhere paper appears (log sheet, timer feed, session pages), it uses:
- Background: `#F5F0E8` with SVG noise texture at 3% opacity
- Ruled lines: repeating-linear-gradient, blue-tinted at 6–8% opacity
- Red margin line: 1px, `rgba(200,80,80,0.15–0.2)`
- Shadow: `0 2px 6px rgba(0,0,0,0.1)` + offset paper-shadow color
- Edge highlight where paper curves over platen: white gradient fadeout

### Typewriter Text on Paper

All typed text on paper surfaces uses:
- Font: Special Elite
- Ink variation: 3 colors cycling via nth-child (`ink-black`, `ink-medium`, `ink-dark`)
- Micro-jitter: ±0.5px translateY, ±0.4° rotation per character
- No two characters sit identically

---

## Sound Design (Deferred — V2)

If sound is implemented:
- **Key strike**: Soft mechanical click on each typed character (timer tip, log form input)
- **Carriage return**: Classic bell ding + mechanical slide
- **Page land**: Soft paper-on-paper settle sound
- **Save**: Brief satisfying thud as form compresses to page
- Sounds should be subtle, warm, analog. Never digital or chirpy. Think ASMR, not notification.
