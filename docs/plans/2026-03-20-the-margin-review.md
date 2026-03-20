# Plan Review: The Margin

> **To apply fixes:** Open new session, run:
> `Read this file, then apply the suggested fixes to /Users/cambriadavies/TheMargin/docs/plans/2026-03-20-the-margin.md`

**Reviewed:** 2026-03-20 16:19:54 GMT
**Verdict:** No

---

## Plan Review: The Margin

**Plan:** `/Users/cambriadavies/TheMargin/docs/plans/2026-03-20-the-margin.md`
**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Charts, UserNotifications, XCTest, iOS 17+

### Summary Table

| Criterion | Status | Notes |
|-----------|--------|-------|
| Parallelization | ISSUES | Mid-plan service/component work can parallelize, but Task 1 assumptions, Task 10/16 rework, and shared-file integrations block clean batching. |
| TDD Adherence | ISSUES | Task 2 is post-hoc testing, and core write flows rely on manual verification instead of RED -> GREEN coverage. |
| Type/API Match | ISSUES | Wrong repo root, iOS 18 `Tab` API on an iOS 17 project, broken `Mood.good` references, and a JSON model mismatch. |
| Library Practices | ISSUES | Several snippets are not valid SwiftUI/SwiftData as written, and some service/view integrations are fragile. |
| Security/Edge Cases | ISSUES | Core persistence has no explicit save/error path, deletion is destructive without recovery, and export/reminder edge cases are under-specified. |

### Issues Found

#### Critical (Must Fix Before Execution)

1. [Task 1, Steps 1-7] `PLAN_ROOT_MISMATCH`

Issue: The plan treats this repo like a blank directory and writes nearly all new files under `TheMargin/...`, but the actual target is already scaffolded and configured from repo-root paths via `project.yml`.

Why: Executing the plan as written will create duplicate, unreferenced files and diverge from the checked-in project structure before feature work even starts.

Fix: Rewrite all source paths to repo-root locations, remove the new-project/bootstrap work, and treat Task 1 as validation/refinement of the existing scaffold.

Suggested edit:

```md
### Task 1: Validate Existing Project Scaffold + Fonts

**Files:**
- Verify: `TheMargin.xcodeproj`
- Verify/Modify: `project.yml`
- Modify: `TheMarginApp.swift`
- Modify: `ContentView.swift`
- Verify: `Resources/Fonts/*.ttf`
- Verify: `Info.plist`

**Context:** This repository is already scaffolded. Do not create a new Xcode project, do not create a nested `TheMargin/` source directory, and do not run `git init`. Work in the repo-root paths already configured by `project.yml`.
```

2. [Task 1 Step 3; Task 3 Step 4] `IOS17_TAB_API_MISMATCH`

Issue: The plan uses `Tab("...", systemImage: ...)` even though the project deployment target is iOS 17.

Why: That API is not valid for the stated target, so the plan introduces compile failures into the baseline scaffold.

Fix: Use the existing iOS 17-compatible `.tabItem { Label(...) }` pattern everywhere the plan currently uses `Tab(...)`.

Suggested edit:

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "doc.text") }

            ProjectsListView()
                .tabItem { Label("Projects", systemImage: "books.vertical") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
    }
}
```

3. [Task 5 Step 1; Task 11 Step 1] `MOOD_ENUM_MISMATCH`

Issue: The plan’s tests reference `Mood.good`, but the enum defined earlier only contains `dry`, `grinding`, `steady`, `flow`, and `breakthrough`.

Why: The RED phase is broken by a compile-time typo instead of an intentional failing behavior test.

Fix: Replace every `.good` reference with a real enum case, or rename the enum consistently if `good` was the intended vocabulary.

Suggested edit:

```swift
private func makeSession(
    daysAgo: Int,
    wordCount: Int,
    mood: Mood = .steady,
    durationSeconds: Int? = nil
) -> Session { ... }

vm.selectedMood = .steady
XCTAssertEqual(dist[.steady], 0.25, accuracy: 0.01)
```

4. [Task 11 Step 3; Task 13 Steps 3-4] `PERSISTENCE_WITHOUT_SAVE`

Issue: The create/edit/delete flows mutate `ModelContext` and dismiss immediately, but never call `try context.save()` or expose a user-visible error path.

Why: This is the app’s core data path. The UI can imply success while data is still unsaved or has failed to persist.

Fix: Make persistence methods throwing, call `try context.save()`, surface failure UI, and add tests that cover save failure and invalid data.

Suggested edit:

```swift
func save(project: Project, context: ModelContext) throws {
    guard let wordCount = parsedWordCount, let mood = selectedMood else {
        throw ValidationError.invalidInput
    }

    let session = Session(
        project: project,
        wordCount: wordCount,
        notes: notes.isEmpty ? nil : notes,
        mood: mood,
        durationSeconds: prefilledDurationSeconds,
        chapterTag: chapterTag.isEmpty ? nil : chapterTag
    )

    context.insert(session)
    try context.save()
}
```

5. [Task 13 Step 2; Task 13 Step 4] `DESTRUCTIVE_DELETE_NO_RECOVERY`

Issue: Session deletion is currently a raw drag-threshold gesture that immediately deletes data.

Why: For a local-only writing tracker, accidental deletion with no confirmation or undo is too risky.

Fix: Replace the direct delete gesture with a confirmation step or swipe action plus undo/recovery handling, and save explicitly after deletion.

Suggested edit:

```md
- Replace the custom drag-to-delete implementation with a standard swipe action or explicit delete affordance.
- Require confirmation before deletion.
- Call `try modelContext.save()` after delete and show an error if persistence fails.
- Add an integration test case for delete + cancel + confirm.
```

#### Major (Should Fix)

6. [Task 2, Steps 1-7] `FOUNDATIONAL_TDD_GAP`

Issue: Task 2 implements enums/models first, then writes tests afterward.

Why: This is post-hoc verification, not RED -> fail -> GREEN, and it weakens the foundation the rest of the plan depends on.

Fix: Reorder Task 2 so the model behavior tests come first, fail first, and then drive the minimal implementation.

Suggested edit:

```md
Task 2 order:
1. Write failing tests for `Project`, `Session`, and `WritingTip` behavior.
2. Run tests and confirm failure.
3. Implement `Mood`, `TipCategory`, `Project`, `Session`, and `WritingTip`.
4. Re-run tests and make them pass.
5. Re-enable `.modelContainer`.
```

7. [Task 10 Step 1; Task 16 Steps 4-6] `DASHBOARD_SPEC_CONFLICT`

Issue: The spec says the stack fan replaces the recent sessions list, but Task 10 still builds a flat “Recent Sessions” section that Task 16 later removes.

Why: The plan bakes avoidable rework into the dashboard path and makes parallel execution harder.

Fix: Resolve the dashboard layout at Task 10. Remove the recent list there and define the `ManuscriptStackView` inputs needed for fan interaction up front.

Suggested edit:

```md
Update Task 10 context and implementation:
- Remove the flat "Recent Sessions" list entirely.
- Pass the top 5 recent sessions into `ManuscriptStackView`.
- Add a callback for tapping a fanned page.
- Keep Task 16 focused on animation/choreography, not dashboard structure rewrites.
```

8. [Task 5 Step 3] `PROJECTION_LOGIC_TEST_MISMATCH`

Issue: `InsightsCalculator.projectedCompletionDate` divides by the exclusive day span between first and last session, but its own test assumes an inclusive 10-day pace.

Why: The plan’s implementation and test disagree, so one of them must fail.

Fix: Define the pace model explicitly. Either use distinct writing days or use an inclusive span (`daySpan + 1`) if that matches the desired behavior.

9. [Task 6 Steps 6-7] `TIP_DATA_AND_SEEDING_MISMATCH`

Issue: The repo already contains `Resources/writing-tips.json`, but its shape does not match the plan’s proposed `WritingTip`/`TipCategory` decoder. The plan also suggests seeding in `TheMarginApp.init()` without first owning a `ModelContainer`.

Why: Tip seeding will either decode the wrong schema or encourage an invalid app setup.

Fix: Decide whether to consume the existing JSON shape or replace that file deliberately, and construct/store a `ModelContainer` in `TheMarginApp` before seeding `container.mainContext`.

Suggested edit:

```md
- Align `WritingTip` loading with the checked-in JSON schema, or replace the bundled JSON in the same task.
- Change `TheMarginApp` to own a `ModelContainer` instance.
- Seed tips from `container.mainContext` in `init`, then inject `.modelContainer(container)`.
```

10. [Task 8 Step 1; Task 9 Step 1] `INVALID_SWIFTUI_SNIPPETS`

Issue: The plan includes at least two invalid SwiftUI snippets: `@Environment` declared inside `body`, and `MarginTheme.text` used like a static property even though `text` is instance state.

Why: These will not compile as written and will interrupt execution flow.

Fix: Declare environment properties on the view type and use `@Environment(\.marginTheme) private var theme` consistently in components.

11. [Task 15 Step 1; Task 6 Step 5] `EXPORT_AND_REMINDER_EDGE_CASES`

Issue: `ShareLink(item: csvData)` produces a poor CSV export UX, reminder UI state is not reconciled with actual notification state, and the CSV generator does not account for spreadsheet formula injection or richer backup needs.

Why: Export and reminder behavior will feel unreliable and can mishandle user data.

Fix: Share a named `.csv` file URL or `FileDocument`, hydrate reminder state on open, check scheduled notifications/authorization, and harden CSV escaping beyond commas/quotes/newlines.

#### Minor (Nice to Have)

12. [Task 16 Step 8] `AUDIO_FORMAT_CHOICE`

Issue: The plan specifies `.mp3` assets for low-latency polyphonic playback via `AVAudioEngine`.

Fix: Prefer predecoded PCM assets (`.wav`/`.caf`) buffered ahead of playback.

13. [Task 17 Step 2] `HAPPY_PATH_ONLY_VERIFICATION`

Issue: The final verification checklist is almost entirely happy-path.

Fix: Add explicit checks for denied notifications, stale `lastUsedProjectID`, delete cancel/confirm paths, dirty-form dismissals, empty export, and save failures.

### Verdict

**Ready to execute?** No

**Reasoning:** The plan is not execution-safe yet because it mismatches the current repository layout, contains compile-time API/type errors, and leaves the core data paths without durable save/error handling. Once those blockers are corrected, the remaining task graph can be parallelized cleanly.

---

## Next Steps

**Review saved to:** `/Users/cambriadavies/TheMargin/docs/plans/2026-03-20-the-margin-review.md`

**Options:**

1. **Apply fixes now** - Edit the plan file to address these issues.
2. **Save & fix later** - Open a new session and apply the review later.
3. **Proceed anyway** - Execute the current plan despite these blockers.
