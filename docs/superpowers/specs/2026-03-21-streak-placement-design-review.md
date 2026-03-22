# Plan Review: Streak Placement Redesign

> **To apply fixes:** Open new session, run:
> `Read this file, then apply the suggested fixes to docs/superpowers/specs/2026-03-21-streak-placement-design.md`

**Reviewed:** 2026-03-21
**Verdict:** With fixes (1-6)

---

## Plan Review: Streak Placement Redesign

**Plan:** `docs/superpowers/specs/2026-03-21-streak-placement-design.md`
**Tech Stack:** Swift, SwiftUI, SwiftData, iOS 17+

### Summary Table

| Criterion | Status | Notes |
|-----------|--------|-------|
| Parallelization | GOOD | Two new components are fully independent; clean 2-batch execution |
| TDD Adherence | ISSUES | Calendar row logic needs extraction into testable pure function |
| Type/API Match | GOOD | All referenced APIs (`StreakCalculator`, `wordsByDay`, `monthStart`) verified in codebase |
| SwiftUI Practices | ISSUES | Missing Dynamic Type scaling, haptic API ambiguity, no VoiceOver labels |
| Edge Cases | ISSUES | Integer division bug, locale formula, shared logic duplication risk |

### Issues Found

#### Critical (Must Fix Before Execution)

1. **[MonthStreakSidebarView] Integer division bug in StreakBarView fill ratio**
   - Issue: The spec says `currentStreak / longestStreak` but both are `Int` in `StreakResult`. Swift integer division yields 0 for any `current < longest`.
   - Why: Every fill ratio except 0/0 and N/N will render as 0%, making the bar useless.
   - Fix: Explicitly note floating-point division and the full condition:
   - Suggested edit (in "Fill width" paragraph):
   ```
   Fill width: `current > 0 ? max(0.05, min(Double(current) / Double(longest), 1.0)) : 0.0`.
   When `longestStreak` is 0 (no history), the fill is 0%. When `current` is 0 (streak broken),
   the fill is also 0% (no sliver). The 5% minimum applies only when the user has an active streak.
   ```

2. **[MonthStreakSidebarView] Calendar row logic must be extracted as shared helper**
   - Issue: The spec says the sidebar uses "same logic the month grid uses" for row calculation, but this logic is currently inline in `WritingCalendarView.body`. Reimplementing it independently creates duplication and divergence risk.
   - Why: Any future change to calendar grid layout (spacing, row height, leading offset) must be duplicated in the sidebar, or they visually misalign.
   - Fix: Add to spec that a shared helper should be extracted, e.g.:
   - Suggested edit (new paragraph after "Checked definition"):
   ```
   **Shared calendar layout**: Extract a `MonthGridLayout` struct (or static method) that computes
   leading spaces, days in month, and row count from a `monthStart` date using the user's locale
   calendar. Both `WritingCalendarView` and `MonthStreakSidebarView` consume this shared computation.
   Formula: `leadingSpaces = (rawWeekday - calendar.firstWeekday + 7) % 7`,
   `rowCount = ceil((leadingSpaces + daysInMonth) / 7)`.
   ```

3. **[MonthStreakSidebarView] Locale-aware week start day**
   - Issue: The spec references "same logic the month grid uses" but the current grid code may use `firstWeekday - 1` which is only correct for Sunday-start locales.
   - Why: Monday-start locales (most of Europe, etc.) would get wrong leading spaces, misaligning sidebar marks with grid rows.
   - Fix: The shared helper in issue #2 must use the locale-aware formula: `(rawWeekday - calendar.firstWeekday + 7) % 7`.

#### Major (Should Fix)

4. **[Both components] No VoiceOver labels specified**
   - Issue: Neither component defines accessibility labels. The sidebar marks, flame emoji, and streak bar are all purely visual with no VoiceOver semantics.
   - Why: VoiceOver users would hear nothing meaningful. The codebase already sets accessibility labels on calendar cells (`WritingCalendarView` line 89), so this is an existing convention being violated.
   - Fix: Add accessibility section to spec:
   - Suggested edit (new section after "Appear animation" in each component):
   ```
   **Accessibility**: Each filled mark reads "Week N, wrote this week." Each empty mark reads
   "Week N, no writing." The flame reads "Current streak indicator." The entire sidebar is
   grouped as a single accessible element with label "Monthly writing activity, N of M weeks active."

   The streak bar is an accessible element with children ignored. Label: "Current streak:
   [N] days. Longest streak: [M] days." Value: "[N] of [M]."
   ```

5. **[Both components] Fixed font sizes do not scale with Dynamic Type**
   - Issue: The spec defines 10px, 16px, 20pt, 22pt as fixed values. `Font.custom(name, size:)` does not automatically scale with Dynamic Type.
   - Why: Users with accessibility text sizes would find the labels unreadable. The codebase uses `@ScaledMetric` for prominent numbers in `LogSessionView` and `TimerView`.
   - Fix: Use `Font.custom(name, size:, relativeTo:)` or `@ScaledMetric` for all sizes. At minimum: streak count (16pt), labels (10pt), and sidebar width (36pt) should scale.
   - Suggested edit (for StreakBarView table):
   ```
   | "Streak" label | Literata 10pt (relativeTo: .caption2), uppercase, letter-spacing 0.5, text-faint |
   | Streak count   | JetBrains Mono 16pt (relativeTo: .body), bold, amber |
   | "days" label   | 10pt (relativeTo: .caption2), text-faint |
   ```

6. **[MonthStreakSidebarView] Haptic API should specify sensoryFeedback()**
   - Issue: The spec says `.impact(.light)` which is ambiguous between UIKit's `UIImpactFeedbackGenerator` and SwiftUI's `.sensoryFeedback()`.
   - Why: The codebase uses `.sensoryFeedback()` exclusively (6 usage sites, zero UIKit haptic usage). Using UIKit would be an architectural inconsistency.
   - Fix: Change spec to: `.sensoryFeedback(.impact(weight: .light), trigger: lastCheckmarkAppeared)`.

#### Minor (Nice to Have)

7. **[MonthStreakSidebarView] Flame visibility for zero-activity months**
   - Issue: The flame appears unconditionally at the bottom of the track. For a new user with zero sessions, showing a flame below all-empty circles is misleading.
   - Fix: Consider dimming or hiding the flame when no rows have activity.

8. **[MonthStreakSidebarView] "Interruption" bullet is unnecessary**
   - Issue: The spec says "If user switches tabs mid-animation, animation completes instantly." This is default SwiftUI behavior when a view disappears.
   - Fix: Remove this line to avoid misleading implementers into writing explicit handling.

9. **[MonthStreakSidebarView] Zero filled checkmarks and haptic**
   - Issue: The spec says haptic fires "on last filled checkmark" but does not explicitly state what happens when there are zero filled marks.
   - Fix: Add: "If no rows have activity, no haptic fires."

10. **[Both components] Testability gap**
    - Issue: The spec does not call for extracting testable logic. The calendar row "checked" calculation is non-trivial calendar math that should be a pure function with unit tests.
    - Fix: The shared layout helper from issue #2 should include a `checkedRows(wordsByDay:) -> [Bool]` method that can be unit tested independently.

### Parallelization Recommendation

**Batch 1 (2 parallel agents):**
- Agent A: Create `MonthStreakSidebarView` (new file, no dependencies)
- Agent B: Create `StreakBarView` (new file, no dependencies)

**Batch 2 (2 parallel agents):**
- Agent C: Integrate sidebar into `WritingCalendarView.monthView` (depends on A)
- Agent D: Integrate bar into week view + remove streak row from `InsightsView` (depends on B)

**Batch 3 (sequential):**
- `xcodegen generate` + build verification

**Max concurrent agents:** 2

### Verdict

**Ready to execute?** With fixes (1-6)

**Reasoning:** The spec is well-scoped and the API references all check out against the codebase. However, three critical issues (integer division bug, shared calendar logic extraction, locale-aware formula) would cause real bugs if implemented as-is. The major issues (VoiceOver labels, Dynamic Type, haptic API) are accessibility and convention gaps that should be addressed before implementation to avoid rework. None of the fixes change the spec's architecture or scope -- they refine implementation details.

---

## Next Steps

**Review saved to:** `docs/superpowers/specs/2026-03-21-streak-placement-design-review.md`

**Options:**

1. **Apply fixes now** - Edit the spec to address issues 1-6
2. **Save & fix later** - Open new session to apply fixes
3. **Proceed anyway** - Execute spec despite issues (not recommended for Critical)

Which option?
