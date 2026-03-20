# The Margin — Empty States & Soft Onboarding Specification

## Overview

This spec defines the first-launch experience and empty states for The Margin. There is no tutorial, walkthrough, or onboarding overlay. Instead, the app teaches itself through its empty states — each one uses the same paper/ink/typewriter vocabulary as the rest of the app, communicates with an evocative-then-actionable tone, and self-resolves through normal usage.

The user's first-launch journey:

1. Welcome screen → create first project
2. Dashboard with zero sessions
3. (User explores) Project detail with no sessions, Insights fully empty
4. User logs first session → empty states begin resolving

---

## Design Decisions

- **Word count goal is mandatory** on all projects (welcome screen and New Project). The stack, progress bar, and projected completion depend on it.
- **Tone: evocative + actionable.** Lead with a short literary line, follow with a subtle hint toward the next action. The app has personality but never leaves you stuck.
- **No tutorials.** No coach marks, no "Step 1 of 4", no tooltip overlays. The empty states are the onboarding.
- **Paper metaphor throughout.** Empty states use the same paper/ink/typewriter vocabulary as the rest of the app. Blank pages, not empty containers.
- **Every empty state exits itself.** Every empty state has a clear action that resolves it. No dead ends.

---

## 1. Welcome Screen (First Launch Only)

**Purpose:** Set the tone of the app and create the user's first project. Shown once, on very first launch. Never shown again.

**Layout (top to bottom, centered, on `background` color):**

- **Manuscript stack preview:** Small stack (5 pages, ~140px wide) with settle-bounce landing animation. Same jitter and physics as the dashboard stack. Establishes the visual reward immediately.
- **App name:** "The Margin" typed in Special Elite with ink variation (per-character opacity jitter). Types out letter-by-letter.
- **Quote:** *"A word after a word after a word is power."* — Newsreader italic, 16px. Attribution "— Margaret Atwood" in `text-dim`, 11px.
- **CTA line:** "Name your first project to begin." — `text-dim`, 13px.
- **Project form card:** Dark `surface` background, 8px radius. Contains:
  - Project name — underline input, Special Elite or system monospace, `text` color. Blinking amber cursor.
  - Word count goal — underline input, same styling. **Mandatory, no "optional" label.**
- **"Begin Writing" button:** Amber background (`amber`), `background` color text, Special Elite uppercase, 12px letter-spacing. 4px radius.
- **Footnote:** "You can always add more projects later." — `text-faint`, italic, 11px.

**Animation sequence (~1.6s):**

| Time | Element | Animation |
|------|---------|-----------|
| 0–600ms | Stack pages | Land one by one, settle-bounce physics (same as dashboard) |
| 600–900ms | "The Margin" | Types out letter-by-letter with ink variation |
| 900–1400ms | Quote + attribution | Fade in (300ms), attribution follows (200ms) |
| 1400–1600ms | CTA + form card | Fade up together |
| 1600ms+ | Cursor | Blinks in project name field, ready for input |

**On "Begin Writing" tap:**
- Validate: project name is non-empty, word count goal is a positive integer.
- On validation failure: the "Begin Writing" button stays inert. The empty field's underline shifts to `amber` and the cursor moves to the first invalid field. No error text, no toast — the highlight is sufficient. The button is always tappable (not disabled), so the user discovers validation by trying.
- The word count goal field should use a numeric keyboard (`.numberPad`). No character limit on project name, but truncate display at ~30 characters elsewhere in the app.
- Create `Project` in SwiftData with the provided name and goal.
- Dismiss welcome screen, reveal the dashboard with the new project selected.
- Set a flag in UserDefaults (`hasCompletedWelcome`) so this screen never shows again.

**Edge case — app is deleted and reinstalled:** SwiftData may retain data. If projects exist but `hasCompletedWelcome` is false, skip the welcome screen. If no projects exist, show it.

**Edge case — subsequent new projects:** Creating a project from the Projects tab uses the standard New/Edit Project modal, not the welcome screen. The dashboard and project detail empty states (Sections 2 and 3) apply normally when switching to a new project with zero sessions.

---

## 2. Dashboard — Zero Sessions

**Condition:** The selected project has zero sessions logged.

**Layout:** Same structure as the standard dashboard. All elements are present, just in their empty/zero state.

- **Nav bar:** Project name (from welcome) + gear icon. Normal.
- **Manuscript stack:** Single blank page, slightly curled corner. Already spec'd in the visual design document. Amber glow behind it is very faint (reduced from normal intensity).
- **"Hold to peek":** Hidden when zero sessions. Appears once 1+ sessions exist and the stack fan has something to show.
- **Stats:** Total Words: **0**, Today: **0**. Newsreader 28px, `text` color. The zeroes are shown, not dashes or blanks — the structure is visible from the start.
- **Progress bar:** 0% filled. Empty track visible. JetBrains Mono percentage label shows "0%".
- **Streak area:** The streak counter text ("14 day streak" / "best: 21") is replaced with:
  - Evocative line: **"The blank page has met its match."** — `text-dim`, 14px, italic, centered.
  - Action hint: "Tap the pen to log your first session." — `text-faint`, 11px, centered.
- **Ink dots:** Still visible below the evocative text. 7 dots, all empty (transparent with `text-faint` border). Today's dot has amber border + 6px glow — it's asking to be filled.
- **Pen FAB:** Present, normal amber, full functionality.
- **Tab bar:** Normal, all 3 tabs functional.

**Transition to populated state:** After the first session is logged and the save-to-stack animation completes, the evocative line is replaced by the standard streak counter ("1 day streak"). Today's ink dot fills amber. Stats count up. No special dismiss logic — the normal dashboard rendering handles it based on session count.

---

## 3. Project Detail — No Sessions

**Condition:** A project exists but has zero sessions logged. Reached via Projects tab → tap project card.

**Layout:** Same structure as the standard project detail view.

- **Nav bar:** ← Projects (back) + Edit (right). Normal.
- **Project name:** Newsreader 22px. Normal.
- **Compact stack + stats:** Mini stack (80px wide) shows single blank page with curled corner. Stats: Total words: 0, Sessions: 0. Progress bar: 0 / [goal], 0%.
- **Session history area:** Where overlapping session pages normally stack, show a single ruled paper page with typed text:
  - Paper treatment: cream background (`paper`), grain texture, ruled lines, red margin line, dog-ear fold. Same as real session pages.
  - Typed text: **"No sessions yet. This is where your pages will live."** — Special Elite, `ink-medium` color, positioned after the red margin, line-height matching ruled lines (28px).
  - The page sits centered with generous vertical padding above and below.

**Transition to populated state:** After a session is logged for this project, the empty page is replaced by real session pages. The save-to-stack animation plays normally — the first session page simply appears where the empty page was. No special dismiss logic.

---

## 4. Insights — Progressive Reveal

The Insights tab uses three tiers based on total session count (across all projects, or filtered by selected project). Charts that need statistical significance are gated behind a session threshold.

### Tier 1: 0 Sessions

**Layout:** Fully empty, centered content.

- **Nav bar:** "Insights" title + project filter pill. Normal.
- **Ghost chart:** Bar chart silhouette at 8% opacity — 7 bars matching the "Words by day of week" chart dimensions. Fixed heights from left to right: 30%, 55%, 40%, 70%, 45%, 60%, 35% of the chart area. Same bar width and spacing as the real chart. This is a static decorative element, not data.
- **Quote:** A writing quote pulled from the bundled `WritingTip` data (random-without-repeat, same rotation as dashboard tips). Newsreader italic, 16px. Attribution below.
- **Nudge:** "Log your first session and your patterns will start to take shape." — `text-dim`, 13px, centered.

### Tier 2: 1–6 Sessions

Some sections are live, others are locked with ghost silhouettes.

**Unlocked (available with any amount of data):**
- Writing frequency calendar (week/month/year toggle) — works with 1+ sessions
- Stat cards: avg words/session, avg duration, best day of week, this week's total. Note: with 1–2 sessions, "best day" is trivially the day(s) you logged — this is fine. It becomes meaningful as data accumulates; no need to gate it separately.
- Streaks: current streak + longest streak
- Mood distribution: horizontal bars with mood icons
- Goal progress: per-project card with percentage, progress bar. **Projected completion date requires 3+ sessions** to calculate a meaningful pace — show "—" for projected date with fewer sessions.

**Locked (need 7+ sessions for statistical significance):**
- **Words by day of week** (bar chart): Ghost bar silhouette at 6% opacity, same fixed heights as the tier 1 ghost chart (30%, 55%, 40%, 70%, 45%, 60%, 35%), same bar dimensions as the real chart. Below: "N more sessions to unlock" in `text-dim`, 11px, italic. N = 7 minus current session count. Use singular "1 more session" when N = 1.
- **Words per week trend** (line chart): Ghost line silhouette at 6% opacity — a single smooth cubic bezier curve from bottom-left to top-right, same chart width and height as the real trend chart. Same "N more sessions to unlock" hint (with singular handling).

Both locked sections are rendered in their normal position in the scroll order. They show the section title label normally — only the chart content is replaced by the ghost silhouette + unlock hint.

### Tier 3: 7+ Sessions

Everything unlocked. No locked sections, no hints. All charts render with real data. When a chart appears for the first time (transitioning from locked to unlocked), the chart data animates in — bars grow from zero, line draws left-to-right. This is the steady state.

**Threshold logic:** The 7-session threshold is checked against the filtered dataset. If the user selects a specific project in the filter pill and that project has 4 sessions, the bar chart and trend line are locked even if the user has 20 sessions across all projects.

---

## Changes to Existing Spec

This spec introduces the following changes to the product and visual design specs:

1. **Word count goal is now mandatory** on all projects. The `wordCountGoal` field on `Project` changes from `Int?` to `Int`. The New/Edit Project modal should validate that a positive integer is provided. Remove "optional" labeling from the goal field everywhere it appears. The "Without a Goal" section in the visual design spec (which describes stack behavior when no goal is set) should be removed — all projects now have a goal.

2. **Welcome screen is a new screen** not in the original screen inventory. It is shown once on first launch and never again. It is not a modal — it replaces the entire app UI until the user creates their first project.

3. **Onboarding is pulled from V2+ into V1.** The "Onboarding flow / first-run experience" item in the Deferred section is resolved by this spec. It can be removed from the deferred list.

4. **Insights empty state is expanded** from a single line ("Log a few more sessions...") to the three-tier progressive reveal described above.

5. **Dashboard layout follows the implementation plan, not the original visual design spec.** The visual design spec describes a "Recent Sessions" list on the dashboard. The implementation plan replaced this with the stack fan interaction (long-press to reveal recent sessions) and ink dots for the weekly streak display. This spec's empty states assume the implementation plan's layout: no recent sessions list, stack fan with "Hold to peek" hint, and 7 ink dots. The visual design spec should be updated to match.

6. **Daily writing tip is not on the dashboard.** The product spec lists a "Daily writing tip or quote" on the dashboard. The visual design spec moved it to the timer screen only. This spec follows the visual design spec — the dashboard shows no daily tip. The Insights tier 1 empty state uses a writing quote, but this is an empty-state element, not the daily tip feature.
