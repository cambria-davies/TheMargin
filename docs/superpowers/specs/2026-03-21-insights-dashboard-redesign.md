# Insights Dashboard Redesign

## Problem

The current Insights dashboard shows the same sections on every tab (Week/Month/Year) even though much of the data isn't relevant at every time scale. This creates redundancy (e.g., "this week" stat card overlaps with the weekly bar chart) and makes each tab feel interchangeable rather than intentional.

## Goal

Each time scope should tell a different story with insights tuned to that scale, while shared sections that are genuinely useful everywhere remain at the bottom.

The user's north star is **consistency** — am I showing up regularly? — with secondary interest in volume trends, flow-state frequency, and the long arc of their writing journey.

## Design: Hybrid Scope-Tuned Layout

The top half of each tab is unique and tells that scope's story. Stat cards and mood distribution are present on every tab but scoped to the selected time period. Streak and goal progress are shared at the bottom (not time-scoped).

### Section Placement Matrix

| Section | Week | Month | Year | Notes |
|---|---|---|---|---|
| Day strip | Anchor | — | — | New. 7 cells, exact word counts, zeros visible. |
| Calendar heatmap | — | Anchor | — | Moved from all tabs to Month only. |
| Year heatmap | — | — | Anchor | Kept. Add month labels. Fit within viewport width. |
| Trend chart | Weekly (8 wks) | Monthly | Yearly (12 mo) | Same chart style, scoped data points and labels. |
| Day-of-week bars | — | Present | — | Moved from all tabs to Month only. |
| Milestones timeline | — | — | Present | New. Auto-generated from session data. |
| Stat cards (2x2) | Scoped to week | Scoped to month | Scoped to year | Data and labels change per tab. |
| Mood distribution | Scoped to week | Scoped to month | Scoped to year | Moved from shared to scoped. |
| Streak row | Shared | Shared | Shared | Unchanged. |
| Goal progress | Shared | Shared | Shared | Unchanged. |

---

## Week View

**Question it answers:** "How is this week going?" (mid-week, forward-looking) and "How did this week go?" (end-of-week, retrospective).

### Layout (top to bottom)

1. **Day strip** — 7 cells for Sun–Sat. Each cell shows the day initial above and exact word count inside. Days with zero words show "0" at 0.35 opacity on a surface-raised background. Days with words use amber fill — intensity is relative to the max day this week (intensity = dayWords / maxDayThisWeek, clamped to [0.2, 1.0]). Today's cell has an amber border ring. Cell dimensions: equal-width flex, 10px corner radius, 12px vertical padding. Day initial in Literata 11px, word count in JetBrains Mono 14px. For counts over 9,999 use compact format (e.g., "16.6k"). This replaces the calendar grid at week scale because it makes gaps viscerally visible and shows exact numbers without tapping.

2. **Weekly trend chart** — The existing 8-week line chart, kept as-is. Amber line with gradient fill, dashed average line, current week annotated with value. Summary stats below: % vs average, this week total, avg/week. This is the most valuable chart on the dashboard — it shows trajectory over time.

3. **Stat cards (2x2 grid, scoped to this week)**
   - Avg words/session (this week's sessions only)
   - Avg duration (this week's sessions only)
   - Best day (this week)
   - Sessions this week (count, not total words — total is already in the trend chart summary)

4. **Streak row** — Current streak + longest streak. Unchanged from current.

5. **Mood distribution (scoped to this week)** — Horizontal bars showing mood breakdown for this week's sessions only.

6. **Goal progress** — Per-project cards. Unchanged from current.

### What's removed from Week view
- Calendar heatmap (moved to Month)
- Day-of-week bar chart (moved to Month — redundant with day strip, and more meaningful when aggregated over 4+ weeks)
- "This week" total stat card (replaced by session count — total is already shown in trend chart summary)

Note: The existing visual spec mentions week-swipe navigation. That remains out of scope for this redesign and can be added later.

---

## Month View

**Question it answers:** "Am I showing up consistently this month?", "What patterns are working?", and "How does this month compare to last month?"

### Layout (top to bottom)

1. **Calendar heatmap** — The existing month grid. 7-column layout with day-of-week headers, amber intensity by word count (4 levels: none, light, medium, heavy), today's cell has amber border. This is the right anchor for month scale — it shows consistency patterns at a glance.

2. **Monthly trend chart** — Same chart style as the weekly trend chart, but with monthly data points. X-axis shows month labels (Jan, Feb, Mar...). Summary stats below: % vs average, this month total, avg/month. Shows up to 24 most recent months (see Trend Chart Specification for details).

3. **Day-of-week bar chart** — Moved here from Week view. Aggregated across the full month's data so the "which day do I actually write?" pattern is statistically meaningful (4+ weeks of data). Best day in solid amber, rest in surface-raised.

4. **Stat cards (2x2 grid, scoped to this month)**
   - Avg words/session (this month's sessions only)
   - Avg duration (this month's sessions only)
   - Best day (this month)
   - Sessions this month (count)

5. **Streak row** — Unchanged.

6. **Mood distribution (scoped to this month)** — Mood breakdown for this month's sessions only.

7. **Goal progress** — Unchanged.

---

## Year View

**Question it answers:** "What does my whole writing journey look like?" with milestone markers and the long arc of improvement.

### Layout (top to bottom)

1. **Year heatmap** — 52 columns x 7 rows GitHub-style heatmap. Must include month labels along the top (currently missing). Must fit within the device viewport width — size cells accordingly rather than allowing horizontal overflow. Amber intensity by word count. Days with no words use surface-raised background.

2. **Yearly trend chart** — Same chart style, 12 monthly data points. X-axis shows all 12 months. Summary stats below: % vs average, this year total, avg/month. Shows the long arc.

3. **Milestones timeline** — New section. A vertical timeline auto-generated from the user's data. Visual: 2px left border line in amber at 0.2 opacity, 20px left padding. Each milestone has a 10px amber circle positioned on the border line, date in Literata 11px at 0.4 opacity, description in Newsreader 14px, highlighted value in amber. 18px vertical spacing between milestones. Sits on a surface-raised card with 18px padding.

   Milestone types:
   - **First session logged** — date of earliest session
   - **Longest streak records** — emitted each time the running all-time-longest streak is surpassed (e.g., streaks of 3, then 5, then 10 each produce a milestone). The first streak (length 1) does not generate a milestone since it overlaps with first session.
   - **Word count goals hit** — when a project's cumulative words cross its word count goal, with project name and target
   - **Most productive day** — the single day with the highest total word count, with the amount. Ties go to the earliest date.
   - **Biggest single session** — the session with the highest word count, with the amount. Ties go to the earliest date.

   Milestones are sorted chronologically, newest at top. Show the 5 most recent by default; if more exist, show a "Show all" link that expands the full list.

4. **Stat cards (2x2 grid, scoped to this year)**
   - Avg words/session (all sessions this year)
   - Avg duration (all sessions this year)
   - Best day (this year)
   - Sessions this year (count)

5. **Streak row** — Unchanged.

6. **Mood distribution (scoped to this year)** — Mood breakdown for this year's sessions.

7. **Goal progress** — Unchanged.

---

## Trend Chart Specification

The trend chart is the most important recurring component — it appears on all three tabs with different data granularity. The visual style is identical across all three:

- **Line style:** Amber stroke with gradient area fill below
- **Average line:** Dashed horizontal rule at the average value, with "avg X" label
- **Current period:** Annotated dot with value label above
- **First period:** Faint dot at the origin
- **Summary row below the chart:** Three stats in a horizontal layout:
  - Left: "% vs avg" (green if positive, default if negative)
  - Center: "[this period] [label]" (e.g., "19,245 THIS WEEK")
  - Right: "[avg] [label]" (e.g., "2,405 AVG / WEEK")

| Tab | Data points | X-axis labels | Period label | Avg label |
|---|---|---|---|---|
| Week | Weekly totals, 8 weeks | Week-start dates | THIS WEEK | AVG / WEEK |
| Month | Monthly totals, all months since first session | Month names | THIS MONTH | AVG / MONTH |
| Year | Monthly totals, 12 months of current year | Month names (Jan–Dec) | THIS YEAR | AVG / MONTH |

Note: Month and Year trend charts both use monthly data points but with different ranges. Month shows all historical months (capped at 24 months; if the user has more, show the most recent 24). Year shows exactly the 12 months of the current year. The Year tab's center summary stat shows the year-to-date total labeled "THIS YEAR" to differentiate it from Month's "THIS MONTH."

Months/weeks with no sessions render as zero-value data points. The chart always renders the full specified range (8 weeks for Week, up to 24 months for Month, 12 months for Year).

---

## Stat Cards Specification

The 2x2 grid appears on every tab. The data source changes based on the selected time scope.

| Card | Week | Month | Year |
|---|---|---|---|
| Top-left | Avg words/session (this week) | Avg words/session (this month) | Avg words/session (this year) |
| Top-right | Avg duration (this week) | Avg duration (this month) | Avg duration (this year) |
| Bottom-left | Best day (this week) | Best day (this month) | Best day (this year) |
| Bottom-right | Sessions this week (count) | Sessions this month (count) | Sessions this year (count) |

Note: The bottom-right card shows session count on all tabs. Total words for the period is already displayed in the trend chart summary row, so repeating it here would be redundant.

---

## Milestones Service

New pure-logic service: `MilestoneCalculator`. Takes `[Session]` and `[Project]` arrays, returns `[Milestone]`.

```swift
struct Milestone {
    let date: Date
    let kind: MilestoneKind

    /// Computed from kind — no separate storage needed.
    var description: String { ... }
    var highlightValue: String { ... }
}

enum MilestoneKind {
    case firstSession
    case streakRecord(days: Int)
    case goalReached(projectName: String, goal: Int)
    case mostProductiveDay(words: Int)
    case biggestSession(words: Int)
}
```

The calculator scans sessions sorted by date and emits milestones when thresholds are crossed. For streak records, it replays the streak history day-by-day, tracking a running max and emitting a milestone each time the max increases (skipping the initial streak of 1). It does not import SwiftData — it takes plain arrays, consistent with the existing service pattern.

---

## Scoping Behavior

When the user selects a project from the "All Projects" filter, all scoped sections (stat cards, mood distribution, trend chart, day strip/calendar/heatmap, day-of-week bars) filter to that project's sessions only. Goal progress always shows all projects with goals regardless of filter.

**Milestones and project filter:** When filtered to a specific project, milestones show only project-specific events: first session for that project, goal reached for that project, most productive day (for that project's sessions only), biggest session (for that project only). Streak records are omitted when filtering by project since streaks are inherently cross-project (they track whether you wrote anything, regardless of which project).

---

## Tiering (Unchanged)

The existing three-tier system remains:
- **Tier 0 (0 sessions):** Empty state with encouraging message
- **Tier 1 (1–6 sessions):** Locked charts with "X more sessions to unlock" labels
- **Tier 2 (7+ sessions):** Full visualization

Milestones timeline on Year view shows regardless of tier (even 1 session produces a "First session logged" milestone).

---

## Out of Scope

- Week view swipe navigation (swipe between weeks)
- Tap-to-drill-down on calendar days
- Seasonal pattern analysis
- Time-of-day analysis
- Session-level detail views from Insights
