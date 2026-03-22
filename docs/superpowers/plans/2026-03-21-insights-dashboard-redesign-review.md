# Plan Review: Insights Dashboard Redesign

> **To apply fixes:** Open new session, run:
> `Read this file, then apply the suggested fixes to docs/superpowers/plans/2026-03-21-insights-dashboard-redesign.md`

**Reviewed:** 2026-03-21
**Verdict:** With fixes (1-5)

---

**Plan:** `docs/superpowers/plans/2026-03-21-insights-dashboard-redesign.md`
**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Charts, XCTest (iOS 17+)

### Summary Table

| Criterion | Status | Notes |
|-----------|--------|-------|
| Parallelization | ✅ GOOD | Clean DAG. Batch 1: Tasks 1,3,4,5 (4 agents). Batch 2: Tasks 2,6 (2 agents). Batch 3: Task 7. Sequential: 8,9. |
| TDD Adherence | ⚠️ ISSUES | Structure is correct (RED-GREEN verified). Task 3 tests have weak/flaky assertions tied to `Date.now`. |
| Type/API Match | ✅ GOOD | All referenced types, methods, and view signatures match the codebase exactly. |
| Library Practices | ⚠️ ISSUES | Date equality with `==` in Charts is fragile. `date(bySetting:)` is the wrong Calendar API. |
| Security/Edge Cases | ⚠️ ISSUES | Hardcoded Sunday-first labels vs locale-aware calendar. Milestone identity uses array offset. |

### Issues Found

#### Critical (Must Fix Before Execution)

1. [Task 7, Step 1] **`date(bySetting:)` is the wrong API for building calendar dates**
   - Issue: `calendar.date(bySetting: .day, value: day, of: monthStart)!` in WritingCalendarView searches forward for the next matching day, which can produce unexpected results (e.g., jumping to next month).
   - Why: Could render wrong dates in the calendar grid, especially edge cases around month boundaries.
   - Fix: Use `calendar.date(byAdding: .day, value: day - 1, to: monthStart)!` which is unambiguous.
   - Suggested edit (WritingCalendarView, line 899 of plan):
   ```swift
   // Before
   let date = calendar.date(bySetting: .day, value: day, of: monthStart)!

   // After
   let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
   ```

2. [Tasks 4+7] **Hardcoded Sunday-first day labels mismatch locale-aware calendar**
   - Issue: `dayInitials = ["S", "M", "T", "W", "T", "F", "S"]` is hardcoded Sunday-first in DayStripView and WritingCalendarView, but `startOfWeek(for:)` respects the user's locale. In Monday-first locales, labels and days are misaligned.
   - Why: Users in non-US locales see incorrect day labels on their calendar and day strip.
   - Fix: Generate labels dynamically from `Calendar.current.veryShortWeekdaySymbols` rotated to match `firstWeekday`.
   - Suggested edit (DayStripView, line 575-576 of plan):
   ```swift
   // Before
   private let dayInitials = ["S", "M", "T", "W", "T", "F", "S"]

   // After
   private var dayInitials: [String] {
       let symbols = Calendar.current.veryShortWeekdaySymbols
       let first = Calendar.current.firstWeekday - 1
       return Array(symbols[first...]) + Array(symbols[..<first])
   }
   ```
   Apply the same fix to WritingCalendarView's `daysOfWeek`.

#### Major (Should Fix)

3. [Task 5, Step 1] **Date equality with `==` in TrendChartView is fragile**
   - Issue: `entry.date == data.last?.date` compares `Date` values using `TimeInterval` (Double). Any floating-point drift from date arithmetic could cause a mismatch, failing to annotate the last data point.
   - Why: Silent visual regression -- the last-point annotation just disappears with no error.
   - Fix: Compare by array index instead of date equality.
   - Suggested edit (TrendChartView, lines 688-703 of plan):
   ```swift
   // Before
   ForEach(data, id: \.date) { entry in
       // ...
       if entry.date == data.last?.date {
           PointMark(...)
       }
       if entry.date == data.first?.date {
           PointMark(...)
       }
   }

   // After
   ForEach(Array(data.enumerated()), id: \.element.date) { index, entry in
       // ...
       if index == data.count - 1 {
           PointMark(...)
       }
       if index == 0 {
           PointMark(...)
       }
   }
   ```

4. [Task 3, Step 1] **Flaky time-dependent test assertions**
   - Issue: `testSessionCount` uses `XCTAssertGreaterThanOrEqual(weekCount, 1)` -- this is so loose it would pass with a broken implementation. `testThisMonthTotal` assumes 60 days ago is a different month, which fails near month boundaries in February.
   - Why: Tests that can't catch regressions provide false confidence.
   - Fix: Use fixed reference dates instead of `Date.now`-relative arithmetic, or tighten assertions. Create a `makeSession(on date: Date, ...)` helper that accepts absolute dates.
   - Suggested edit (InsightsCalculatorTests, plan line 425-434):
   ```swift
   // Before
   func testSessionCount() {
       let sessions = [
           makeSession(daysAgo: 0, wordCount: 500),
           makeSession(daysAgo: 1, wordCount: 800),
           makeSession(daysAgo: 10, wordCount: 300),
       ]
       let weekCount = InsightsCalculator.sessionCount(sessions, period: .week)
       XCTAssertGreaterThanOrEqual(weekCount, 1)
   }

   // After -- use exact session count for deterministic test
   func testSessionCount() {
       let calendar = Calendar.current
       let today = calendar.startOfDay(for: .now)
       let weekStart = calendar.startOfWeek(for: today)
       // Place sessions precisely: one today (in week), one before week start (out of week)
       let inWeek = Session(project: makeProject(), date: today, wordCount: 500, mood: .steady)
       let outOfWeek = Session(project: makeProject(), date: calendar.date(byAdding: .day, value: -1, to: weekStart)!, wordCount: 300, mood: .steady)
       let weekCount = InsightsCalculator.sessionCount([inWeek, outOfWeek], period: .week)
       XCTAssertEqual(weekCount, 1)
   }
   ```

5. [Task 6, Step 1] **MilestonesTimelineView uses array offset as ForEach identity**
   - Issue: `ForEach(Array(visibleMilestones.enumerated()), id: \.offset)` uses the enumeration index as the SwiftUI view identity. This works for the current show/hide toggle but is fragile if milestones ever change order or are filtered dynamically.
   - Why: Incorrect view identity causes wrong animations and potential state corruption.
   - Fix: Make `Milestone` conform to `Identifiable` with a stable ID.
   - Suggested edit (Models/Milestone.swift):
   ```swift
   // Add to Milestone struct
   struct Milestone: Equatable, Identifiable {
       let date: Date
       let kind: MilestoneKind

       var id: String {
           "\(date.timeIntervalSince1970)-\(kind)"
       }
       // ... rest of struct
   }
   ```
   Then update MilestonesTimelineView:
   ```swift
   // Before
   ForEach(Array(visibleMilestones.enumerated()), id: \.offset) { _, milestone in

   // After
   ForEach(visibleMilestones) { milestone in
   ```
   Note: `MilestoneKind` already conforms to `Equatable`. For the `id` string approach to work, `MilestoneKind` would also need a string representation. Alternatively, use `Hashable` conformance.

#### Minor (Nice to Have)

6. [Task 1] **Missing tests for Milestone computed properties**
   - Issue: `Milestone.description` and `highlightValue` have 5-case switch logic with no test coverage. CLAUDE.md says to test computed properties on models.
   - Fix: Add 2-3 test methods to MilestoneCalculatorTests verifying representative outputs.

7. [Task 4, Step 1] **`formatCompact` is untested business logic in a view**
   - Issue: DayStripView contains `formatCompact(_:)` with number formatting logic (10000 -> "10.0k"). This is business logic embedded in a view where it can't be unit tested.
   - Fix: Extract to a utility function or make it a static method on a helper enum that can be tested.

8. [Task 3, Step 3] **`InsightsPeriod` should explicitly declare `Hashable`**
   - Issue: Plain enums are implicitly Hashable, but explicit conformance makes the intent clear and enables `CaseIterable` for the picker.
   - Fix: `enum InsightsPeriod: Hashable, CaseIterable { case week, month, year }`

9. [Task 7, Step 3] **`#Predicate { !$0.isArchived }` may crash on iOS 17.0-17.1**
   - Issue: Negation in `#Predicate` had known bugs in early iOS 17 releases.
   - Fix: Use `$0.isArchived == false` for broader compatibility.

### Verdict

**Ready to execute?** With fixes (1-5)

**Reasoning:** The plan is well-structured with correct TDD flow, clean parallelization, and all type/API references verified against the codebase. The 2 critical issues (wrong Calendar API and locale-hardcoded day labels) would produce user-visible bugs. The 3 major issues (fragile date equality, flaky tests, unstable view identity) are correctness risks that should be addressed before implementation. The minor issues are quality improvements that can be addressed during or after implementation.

---

## Next Steps

**Review saved to:** `docs/superpowers/plans/2026-03-21-insights-dashboard-redesign-review.md`

**Options:**

1. **Apply fixes now** - Edit the plan file to address issues 1-5
2. **Save & fix later** - Open new session to apply fixes
3. **Proceed anyway** - Execute plan despite issues (not recommended for Critical)

Which option?
