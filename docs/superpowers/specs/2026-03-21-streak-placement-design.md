# Streak Placement Redesign

## Problem

The streak display is a standalone text row buried below stat cards in the Insights tab — position 4 of 6 in the layout. It's disconnected from the calendar, which is the view that actually shows whether the writer showed up. The streak number has no spatial relationship to the data it summarizes.

## Goal

Anchor the streak display directly to the calendar views so "I showed up" and "here's my streak" are visually linked. Different representations for different time scales: vertical sidebar for month, horizontal bar for week, nothing for year (milestones cover the long arc).

## Design

### Month View — Vertical Streak Sidebar

The calendar grid gets a companion column on the trailing edge.

**Layout**: `HStack` of calendar grid (flex) + 36pt-wide sidebar. The sidebar contains:

- A vertical track (6pt wide, amber gradient top-to-bottom, rounded 3pt caps) spanning the height of the calendar rows
- One circular mark per calendar row (week), vertically centered on its corresponding grid row
- Filled marks: 20pt amber circle with checkmark glyph, for weeks where ≥1 session exists
- Empty marks: 20pt circle with surface-raised fill and subtle border (#444), for weeks with no sessions
- Flame emoji (22pt) at the bottom of the track

**"Checked" definition**: A calendar row gets a checkmark if the user logged ≥1 writing session during any day visible in that row. Calculated from the `wordsByDay` dictionary — if any date in the row has a value > 0, the week is checked.

This is purely a visual indicator — it does not affect `StreakCalculator` logic, which remains day-based.

**Appear animation**: Track appears immediately on view appear. Checkmarks pop in top-to-bottom with spring scale (0 → 1), using `.spring(duration: 0.35, bounce: 0.3)` and ~0.08s stagger between each. The last filled checkmark triggers `.impact(.light)` haptic. Empty marks fade in at reduced opacity without spring. Total animation duration ~0.4s for a full month.

**Reduce Motion**: All marks appear instantly, no stagger or spring. Haptic still fires.

### Week View — Horizontal Streak Bar

A compact progress bar sits directly below the day strip, inside the same visual group.

**Layout**: `HStack` with:

| Element | Spec |
|---------|------|
| "Streak" label | Literata 10px, uppercase, letter-spacing 0.5, text-faint color |
| Track | Flex width, 6pt tall, surface-raised background, 3pt corner radius |
| Fill | Amber gradient (amber-mid → amber), left-aligned, 3pt corner radius |
| Streak count | JetBrains Mono 16px, bold, amber color |
| "days" label | 10px, text-faint color |

**Fill width**: `currentStreak / longestStreak`, clamped to `[0.05, 1.0]`. The 5% minimum ensures there's always a visible sliver when a streak exists. When `longestStreak` is 0 (no history), the fill is 0%.

**Appear animation**: Bar width animates from 0% to current value with `.smooth(duration: 0.5)`. The count label uses `.contentTransition(.numericText)` for a rolling number effect.

**Reduce Motion**: Bar appears at full width instantly. No fill animation.

### Year View

No streak display. The milestones timeline (from the insights dashboard redesign) covers streak achievements at the year scale.

### What's Removed

The current standalone "Streak row" in `InsightsView` (current streak number + "current streak" label + longest streak in italic) is removed from its position below stat cards. Streak information now lives exclusively in the month and week anchor views.

The `StreakDotsView` component on the Dashboard remains unchanged — this redesign only affects the Insights tab.

## New Components

### `MonthStreakSidebarView`

- **Location**: `Components/MonthStreakSidebarView.swift`
- **Inputs**: `wordsByDay: [Date: Int]`, `monthStart: Date` (first day of the displayed month)
- **Responsibility**: Derives calendar row ranges from `monthStart` (same logic the month grid uses to compute leading offset and day count), determines which rows have activity by checking `wordsByDay` for any value > 0 in each row's date range, then renders the vertical track, positioned checkmarks, and flame. Manages appear animation state.
- **Width**: Fixed 36pt

### `StreakBarView`

- **Location**: `Components/StreakBarView.swift`
- **Inputs**: `current: Int`, `longest: Int`
- **Responsibility**: Renders the horizontal bar with animated fill and streak count.
- **Height**: ~30pt (bar + label padding)

## Data Flow

No new services or model changes required.

- `MonthStreakSidebarView` takes `wordsByDay` and `monthStart` (both already available in `WritingCalendarView.monthView`). It derives calendar row date ranges internally using the same calendar math the month grid uses (first weekday offset, days in month), then checks each row for activity (any date with words > 0).
- `StreakBarView` reads `current` and `longest` from `StreakCalculator.calculate(sessionDates:)`, which is already called in `InsightsView`.
- The `WritingCalendarView` gains both components as children — the sidebar is embedded in the month view's layout, the bar is appended below the week view's day strip.

## Animation Specs

### Sidebar Checkmark Pop (Month)

| Property | From | To | Curve | Duration |
|----------|------|----|-------|----------|
| scale | 0 | 1 | .spring(duration: 0.35, bounce: 0.3) | — |

- **Stagger**: 0.08s between each checkmark, top to bottom
- **Haptic**: `.impact(.light)` on last filled checkmark
- **Interruption**: If user switches tabs mid-animation, animation completes instantly
- **Reduce Motion**: Instant, no spring or stagger

### Bar Fill (Week)

| Property | From | To | Curve | Duration |
|----------|------|----|-------|----------|
| fill width | 0% | current% | .smooth | 0.5s |

- **Content transition**: `.numericText` on the count label
- **Haptic**: None
- **Reduce Motion**: Instant full width

## Relationship to Insights Dashboard Redesign Spec

This spec supersedes the insights dashboard redesign spec's treatment of streaks. The redesign spec lists "Streak row | Shared | Shared | Shared | Unchanged" — that row is now removed in favor of the calendar-anchored components described here. The redesign spec's Section Placement Matrix should be updated to reflect: streak sidebar on Month, streak bar on Week, no streak on Year.

## Scope Boundaries

- **In scope**: Moving streak from standalone row to calendar-anchored views, new sidebar and bar components, appear animations
- **Out of scope**: Streak update animation after session save (separate session — interacts with existing save animation on Dashboard), changes to Dashboard streak display, changes to StreakCalculator logic
