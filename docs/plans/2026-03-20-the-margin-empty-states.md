# Empty States & Soft Onboarding — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first-launch welcome screen and empty states for dashboard, project detail, and insights — so the app teaches itself through its blank states rather than tutorials.

**Architecture:** The welcome screen is a standalone view gated by a UserDefaults flag + SwiftData project count check. Empty states are conditional branches within existing views (DashboardView, ProjectDetailView, InsightsView) that render based on session count. A `GhostChartView` component provides the silhouette placeholders for locked insights. The `Project.wordCountGoal` field changes from `Int?` to `Int` (mandatory).

**Tech Stack:** Swift, SwiftUI, SwiftData, iOS 17+

**Prerequisites:** This plan assumes the following tasks from the main implementation plan (`docs/plans/2026-03-20-the-margin.md`) are already complete:
- Task 1: Xcode project scaffold + fonts
- Task 2: SwiftData models + enums
- Task 3: Theme (MarginTheme, PaperSurface, TypewriterText)
- Task 4: Services (StreakCalculator, InsightsCalculator, TipRotationService)
- Task 5: Components (ManuscriptStackView, StreakDotsView, PenFABView, StatCardView, OdometerView)
- Task 8: DashboardView (for Task 4 of this plan)
- Task 9: ProjectDetailView, SessionPageView (for Task 5 of this plan)
- Task 12: InsightsView and all sub-views (for Task 7 of this plan)

**Execution Guardrails:** Inherits all guardrails from the main plan. Key reminders:
- Never use `DispatchQueue`. Use `Task` / `async`/`await` / `Task.sleep(for:)`.
- All animations must check `@Environment(\.accessibilityReduceMotion)` and substitute opacity transitions when Reduce Motion is enabled.
- Custom font sizes must use `@ScaledMetric` for Dynamic Type support.
- Use `.onChange(of:) { _, _ in }` two-parameter closure form (iOS 17).
- Avoid `GeometryReader` when `Canvas`, `containerRelativeFrame()`, or hardcoded values suffice.
- Always use `--quiet` flag on xcodebuild commands.
- After creating new files, run `xcodegen generate` to update the Xcode project.
- Never edit `.pbxproj` directly.

**Spec:** `docs/specs/2026-03-20-the-margin-empty-states-design.md`

**Note on main plan file structure:** This plan creates files not listed in the main plan's file structure (`Views/Welcome/WelcomeView.swift`, `Services/WelcomeGate.swift`, `Services/InsightsTier.swift`, `Views/Projects/EmptySessionPageView.swift`, `Views/Insights/GhostChartView.swift`). The main plan's file structure section should be updated to include these.

---

## File Structure

```
Models/
  Project.swift                      # MODIFY — wordCountGoal: Int? → Int

Views/
  Welcome/
    WelcomeView.swift                # CREATE — first-launch screen
  Dashboard/
    DashboardView.swift              # MODIFY — zero-session empty state
  Projects/
    ProjectDetailView.swift          # MODIFY — zero-session empty state
    EmptySessionPageView.swift       # CREATE — paper page with typed message
  Insights/
    InsightsView.swift               # MODIFY — 3-tier progressive reveal
    GhostChartView.swift             # CREATE — ghost bar/line silhouettes

ContentView.swift                    # MODIFY — welcome gate logic
TheMarginApp.swift                   # MODIFY — welcome state check

TheMarginTests/
  ModelTests/
    ProjectTests.swift               # MODIFY — update for mandatory goal
  ServiceTests/
    WelcomeGateTests.swift           # CREATE — welcome gate logic tests
    InsightsTierTests.swift          # CREATE — tier threshold tests
```

---

### Task 1: Make wordCountGoal Mandatory

**Files:**
- Modify: `Models/Project.swift`
- Modify: `TheMarginTests/ModelTests/ProjectTests.swift`

**Context:** The empty states spec changes `wordCountGoal` from `Int?` to `Int`. This affects the model, its init, computed properties (`goalProgress` loses its `nil` case), and all tests. See spec Section 5 item 1.

- [ ] **Step 1: Update the Project model**

Change `wordCountGoal` from optional to required:

```swift
// Models/Project.swift — changes only

// BEFORE:
//   var wordCountGoal: Int?
// AFTER:
var wordCountGoal: Int

// BEFORE:
//   var goalProgress: Double? {
//       guard let goal = wordCountGoal, goal > 0 else { return nil }
//       return min(Double(totalWords) / Double(goal), 1.0)
//   }
// AFTER:
var goalProgress: Double {
    guard wordCountGoal > 0 else { return 0.0 }
    return min(Double(totalWords) / Double(wordCountGoal), 1.0)
}

// BEFORE:
//   init(name: String, wordCountGoal: Int? = nil, startingWordCount: Int = 0)
// AFTER:
init(name: String, wordCountGoal: Int, startingWordCount: Int = 0) {
    self.id = UUID()
    self.name = name
    self.wordCountGoal = wordCountGoal
    self.startingWordCount = startingWordCount
    self.createdAt = Date.now
    self.isArchived = false
    self.sessions = []
}
```

- [ ] **Step 2: Update ProjectTests for mandatory goal**

```swift
// TheMarginTests/ModelTests/ProjectTests.swift — update existing tests

func testTotalWordsWithNoSessions() {
    let project = Project(name: "Novel", wordCountGoal: 80000, startingWordCount: 10000)
    XCTAssertEqual(project.totalWords, 10000)
}

func testTotalWordsIncludesStartingWordCount() {
    let project = Project(name: "Novel", wordCountGoal: 80000, startingWordCount: 30000)
    let session = Session(project: project, wordCount: 500, mood: .steady)
    project.sessions = [session]
    XCTAssertEqual(project.totalWords, 30500)
}

func testGoalProgressCalculation() {
    let project = Project(name: "Novel", wordCountGoal: 80000, startingWordCount: 40000)
    XCTAssertEqual(project.goalProgress, 0.5, accuracy: 0.001)
}

// REMOVE testGoalProgressNilWhenNoGoal — no longer applicable

func testGoalProgressCapsAtOne() {
    let project = Project(name: "Short", wordCountGoal: 1000, startingWordCount: 2000)
    XCTAssertEqual(project.goalProgress, 1.0)
}
```

- [ ] **Step 3: Fix any other references to optional wordCountGoal**

Search for `wordCountGoal` across the codebase. Update any `if let goal = project.wordCountGoal` or `project.wordCountGoal ?? 0` patterns to use the non-optional value directly. Update the `NewProjectView` to make the goal field required with validation.

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet`
Expected: All model tests pass.

- [ ] **Step 5: Commit**

```bash
git add Models/Project.swift TheMarginTests/ModelTests/ProjectTests.swift
git commit -m "refactor: make wordCountGoal mandatory on Project"
```

---

### Task 2: Welcome Screen View

**Files:**
- Create: `Views/Welcome/WelcomeView.swift`

**Context:** First-launch screen with stack preview, typed app name, Atwood quote, and project creation form. See spec Section 1 for layout, animation timing, and validation behavior. Uses ManuscriptStackView (small, 5 pages), TypewriterText, and MarginTheme.

- [ ] **Step 1: Create WelcomeView**

```swift
// Views/Welcome/WelcomeView.swift
import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?
    @State private var projectName = ""
    @State private var goalText = ""
    @State private var showNameError = false
    @State private var showGoalError = false
    @State private var animationPhase: WelcomeAnimationPhase = .initial

    var onComplete: () -> Void

    enum Field { case name, goal }

    enum WelcomeAnimationPhase: Int, Comparable {
        case initial, stackLanding, titleTyping, quoteFade, formReveal, ready

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    var body: some View {
        ZStack {
            MarginTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Stack preview
                    if animationPhase >= .stackLanding {
                        // Use ManuscriptStackView with the main plan's API.
                        // Pass totalWords representing ~5 pages (1250 words)
                        // and use .compact size for the welcome preview.
                        ManuscriptStackView(
                            totalWords: 1250,
                            goalWords: 80000,
                            size: .compact
                        )
                        .transition(.opacity)
                    }

                    Spacer().frame(height: 16)

                    // App name with ink variation
                    if animationPhase >= .titleTyping {
                        TypewriterText(
                            "The Margin",
                            font: MarginTheme.specialElite(size: 22),
                            color: MarginTheme.text,
                            animated: !reduceMotion
                        )
                        .transition(.opacity)
                    }

                    Spacer().frame(height: 32)

                    // Atwood quote
                    if animationPhase >= .quoteFade {
                        VStack(spacing: 8) {
                            Text("\"A word after a word after a word is power.\"")
                                .font(MarginTheme.newsreader(size: 16, weight: .light))
                                .italic()
                                .foregroundStyle(MarginTheme.text)
                                .multilineTextAlignment(.center)

                            Text("— Margaret Atwood")
                                .font(MarginTheme.literata(size: 11))
                                .foregroundStyle(MarginTheme.textDim)
                        }
                        .transition(.opacity)
                    }

                    Spacer().frame(height: 24)

                    // CTA + Form
                    if animationPhase >= .formReveal {
                        WelcomeFormSection(
                            projectName: $projectName,
                            goalText: $goalText,
                            showNameError: $showNameError,
                            showGoalError: $showGoalError,
                            focusedField: $focusedField,
                            onBegin: beginWriting
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer().frame(height: 48)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { startAnimationSequence() }
    }

    private func startAnimationSequence() {
        if reduceMotion {
            // Skip choreography — show everything immediately
            animationPhase = .ready
            focusedField = .name
            return
        }

        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.6)) {
                animationPhase = .stackLanding
            }
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeOut(duration: 0.3)) {
                animationPhase = .titleTyping
            }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.5)) {
                animationPhase = .quoteFade
            }
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeOut(duration: 0.3)) {
                animationPhase = .formReveal
            }
            try? await Task.sleep(for: .milliseconds(200))
            animationPhase = .ready
            focusedField = .name
        }
    }

    private func beginWriting() {
        let name = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = Int(goalText)

        showNameError = name.isEmpty
        showGoalError = goal == nil || (goal ?? 0) <= 0

        if name.isEmpty {
            focusedField = .name
            return
        }
        if goal == nil || (goal ?? 0) <= 0 {
            focusedField = .goal
            return
        }

        let validGoal = goal!
        let project = Project(name: name, wordCountGoal: validGoal)
        modelContext.insert(project)

        UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")
        UserDefaults.standard.set(project.id.uuidString, forKey: "lastUsedProjectID")

        onComplete()
    }
}

// MARK: - Extracted sub-view per @ViewBuilder guardrail

private struct WelcomeFormSection: View {
    @Binding var projectName: String
    @Binding var goalText: String
    @Binding var showNameError: Bool
    @Binding var showGoalError: Bool
    var focusedField: FocusState<WelcomeView.Field?>.Binding
    var onBegin: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Name your first project to begin.")
                .font(MarginTheme.literata(size: 13))
                .foregroundStyle(MarginTheme.textDim)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PROJECT NAME")
                        .font(MarginTheme.literata(size: 10))
                        .tracking(1.5)
                        .foregroundStyle(MarginTheme.textDim)

                    TextField("", text: $projectName)
                        .font(MarginTheme.specialElite(size: 16))
                        .foregroundStyle(MarginTheme.text)
                        .focused(focusedField, equals: .name)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(showNameError ? MarginTheme.amber : MarginTheme.surfaceRaised)
                        }
                        .onChange(of: projectName) { _, _ in showNameError = false }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("WORD COUNT GOAL")
                        .font(MarginTheme.literata(size: 10))
                        .tracking(1.5)
                        .foregroundStyle(MarginTheme.textDim)

                    TextField("", text: $goalText)
                        .font(MarginTheme.specialElite(size: 16))
                        .foregroundStyle(MarginTheme.text)
                        .keyboardType(.numberPad)
                        .focused(focusedField, equals: .goal)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(showGoalError ? MarginTheme.amber : MarginTheme.surfaceRaised)
                        }
                        .onChange(of: goalText) { _, _ in showGoalError = false }
                }

                Button(action: onBegin) {
                    Text("BEGIN WRITING")
                        .font(MarginTheme.specialElite(size: 12))
                        .tracking(2)
                        .foregroundStyle(MarginTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(MarginTheme.amber)
                        .cornerRadius(4)
                }
            }
            .padding(24)
            .background(MarginTheme.surface)
            .cornerRadius(8)
            .frame(maxWidth: 300)

            Text("You can always add more projects later.")
                .font(MarginTheme.literata(size: 11))
                .italic()
                .foregroundStyle(MarginTheme.textFaint)
        }
    }
}
```

- [ ] **Step 2: Build to verify WelcomeView compiles**

Run: `xcodegen generate && xcodebuild -scheme TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet`
Expected: Build succeeds. (WelcomeView is not wired into the app yet — that's Task 3.)

- [ ] **Step 3: Commit**

```bash
git add Views/Welcome/WelcomeView.swift
git commit -m "feat: add WelcomeView for first-launch onboarding"
```

---

### Task 3: Welcome Gate in App Root

**Files:**
- Modify: `ContentView.swift`
- Modify: `TheMarginApp.swift`

**Context:** ContentView needs to show WelcomeView on first launch (no projects exist AND `hasCompletedWelcome` is false), then switch to the tab bar. See spec Section 1 edge cases: if projects exist but flag is false, skip welcome. If no projects, show it.

- [ ] **Step 1: Write a test for the welcome gate logic**

```swift
// TheMarginTests/ServiceTests/WelcomeGateTests.swift
import XCTest
@testable import TheMargin

final class WelcomeGateTests: XCTestCase {
    func testShouldShowWelcomeWhenNoProjectsAndNoFlag() {
        // No projects, hasCompletedWelcome = false → show welcome
        XCTAssertTrue(WelcomeGate.shouldShowWelcome(projectCount: 0, hasCompletedFlag: false))
    }

    func testShouldSkipWelcomeWhenProjectsExist() {
        // Projects exist but flag is false (reinstall) → skip welcome
        XCTAssertFalse(WelcomeGate.shouldShowWelcome(projectCount: 1, hasCompletedFlag: false))
    }

    func testShouldSkipWelcomeWhenFlagIsSet() {
        // Flag is set → skip welcome
        XCTAssertFalse(WelcomeGate.shouldShowWelcome(projectCount: 0, hasCompletedFlag: true))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TheMarginTests/WelcomeGateTests --quiet`
Expected: FAIL — `WelcomeGate` does not exist.

- [ ] **Step 3: Implement WelcomeGate**

```swift
// Services/WelcomeGate.swift
enum WelcomeGate {
    static func shouldShowWelcome(projectCount: Int, hasCompletedFlag: Bool) -> Bool {
        !hasCompletedFlag && projectCount == 0
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TheMarginTests/WelcomeGateTests --quiet`
Expected: PASS

- [ ] **Step 5: Update ContentView with welcome gate**

```swift
// ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var projects: [Project]
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false
    @State private var showingWelcome: Bool?

    private var shouldShowWelcome: Bool {
        WelcomeGate.shouldShowWelcome(
            projectCount: projects.count,
            hasCompletedFlag: hasCompletedWelcome
        )
    }

    var body: some View {
        Group {
            if showingWelcome ?? shouldShowWelcome {
                WelcomeView {
                    withAnimation {
                        hasCompletedWelcome = true
                        showingWelcome = false
                    }
                }
            } else {
                TabView {
                    Text("Dashboard")
                        .tabItem { Label("Home", systemImage: "doc.text") }

                    Text("Projects")
                        .tabItem { Label("Projects", systemImage: "books.vertical") }

                    Text("Insights")
                        .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                }
            }
        }
        .onAppear {
            if showingWelcome == nil {
                showingWelcome = shouldShowWelcome
            }
        }
    }
}
```

- [ ] **Step 6: Build and run**

Run: `xcodegen generate && xcodebuild -scheme TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet`
Expected: Build succeeds. On first launch, WelcomeView appears. After creating a project, tab bar appears.

- [ ] **Step 7: Commit**

```bash
git add Services/WelcomeGate.swift ContentView.swift TheMarginTests/ServiceTests/WelcomeGateTests.swift
git commit -m "feat: add welcome gate — show onboarding on first launch"
```

---

### Task 4: Dashboard Zero-Session Empty State

**Files:**
- Modify: `Views/Dashboard/DashboardView.swift`

**Context:** When the selected project has zero sessions, the dashboard shows zeroed stats, a single blank page on the stack, the evocative message "The blank page has met its match." instead of the streak counter, and empty ink dots with today's dot glowing amber. "Hold to peek" is hidden. See spec Section 2.

**Prerequisite:** DashboardView must already exist from the main plan (Task 8). This task adds the empty state conditional branches.

- [ ] **Step 1: Add empty state logic to DashboardView**

The dashboard checks `project.sessions.isEmpty` (or `project.sessions.count == 0`) to switch between empty and populated states. Key conditional areas:

```swift
// In DashboardView.swift — add these conditional branches:

// 1. Hide "Hold to peek" when no sessions
if !project.sessions.isEmpty {
    Text("Hold to peek")
        .font(MarginTheme.literata(size: 10))
        .italic()
        .foregroundStyle(MarginTheme.textFaint)
}

// 2. Streak area — evocative text vs streak counter
if project.sessions.isEmpty {
    VStack(spacing: 8) {
        Text("The blank page has met its match.")
            .font(MarginTheme.literata(size: 14))
            .italic()
            .foregroundStyle(MarginTheme.textDim)

        Text("Tap the pen to log your first session.")
            .font(MarginTheme.literata(size: 11))
            .foregroundStyle(MarginTheme.textFaint)
    }
    .multilineTextAlignment(.center)
} else {
    // Normal streak counter (Newsreader 36px amber + "day streak")
    StreakCounterView(sessions: project.sessions)
}

// 3. ManuscriptStackView handles empty state internally:
//    pageCount == 0 renders a single blank page with curled corner.
//    This should already be implemented in the ManuscriptStackView component.
//    Verify it works with project.visualPageCount == 0.

// 4. Stats show "0" naturally — OdometerView(value: 0) renders "0".
//    No special case needed.

// 5. Progress bar shows 0% naturally — goalProgress returns 0.0 when totalWords is 0.
//    No special case needed.

// 6. StreakDotsView shows all empty dots naturally.
//    Today's dot has amber glow by default.
//    No special case needed if the component already handles this.
```

- [ ] **Step 2: Build and verify**

Run: `xcodegen generate && xcodebuild -scheme TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet`
Expected: Build succeeds. Launch the app, create a project via welcome → dashboard shows empty state with evocative text, zeroed stats, single blank page.

- [ ] **Step 3: Commit**

```bash
git add Views/Dashboard/DashboardView.swift
git commit -m "feat: add dashboard zero-session empty state"
```

---

### Task 5: Project Detail Empty State

**Files:**
- Create: `Views/Projects/EmptySessionPageView.swift`
- Modify: `Views/Projects/ProjectDetailView.swift`

**Context:** When a project has no sessions, the session history area shows a single ruled paper page with "No sessions yet. This is where your pages will live." typed on it. Uses PaperSurface modifier. See spec Section 3.

**Prerequisite:** ProjectDetailView must already exist from the main plan (Task 9). This task adds the EmptySessionPageView and wires it in.

- [ ] **Step 1: Create EmptySessionPageView**

```swift
// Views/Projects/EmptySessionPageView.swift
import SwiftUI

struct EmptySessionPageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TypewriterText(
                "No sessions yet.\nThis is where your pages will live.",
                font: MarginTheme.specialElite(size: 13),
                color: MarginTheme.inkMedium,
                animated: false
            )
            .lineSpacing(28 - 13) // match ruled line height
        }
        .padding(.top, 32)
        .padding(.leading, 60) // past red margin
        .padding(.trailing, 24)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .modifier(PaperSurface(showRuledLines: true, showRedMargin: true, showDogEar: true))
    }
}
```

- [ ] **Step 2: Wire into ProjectDetailView**

```swift
// In ProjectDetailView.swift — session history section:

if project.sessions.isEmpty {
    EmptySessionPageView()
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
} else {
    // Normal session pages (overlapping paper sheets)
    ForEach(project.sessions.sorted(by: { $0.date > $1.date })) { session in
        SessionPageView(session: session)
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodegen generate && xcodebuild -scheme TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet`
Expected: Build succeeds. Navigate to a project with no sessions → empty paper page appears with typed message.

- [ ] **Step 4: Commit**

```bash
git add Views/Projects/EmptySessionPageView.swift Views/Projects/ProjectDetailView.swift
git commit -m "feat: add project detail empty state with paper page"
```

---

### Task 6: Ghost Chart Component

**Files:**
- Create: `Views/Insights/GhostChartView.swift`
- Create: `TheMarginTests/ServiceTests/InsightsTierTests.swift`

**Context:** Ghost bar and line silhouettes used in Insights empty states (tiers 1 and 2). Fixed bar heights: 30%, 55%, 40%, 70%, 45%, 60%, 35%. Ghost line is a smooth cubic bezier curve. Both at configurable opacity (8% for tier 1, 6% for tier 2). Also includes the "N more sessions to unlock" label. See spec Section 4.

- [ ] **Step 1: Write tests for InsightsTier logic**

```swift
// TheMarginTests/ServiceTests/InsightsTierTests.swift
import XCTest
@testable import TheMargin

final class InsightsTierTests: XCTestCase {
    func testTierOneWithZeroSessions() {
        XCTAssertEqual(InsightsTier.forSessionCount(0), .empty)
    }

    func testTierTwoWithFewSessions() {
        XCTAssertEqual(InsightsTier.forSessionCount(1), .partial)
        XCTAssertEqual(InsightsTier.forSessionCount(6), .partial)
    }

    func testTierThreeWithEnoughSessions() {
        XCTAssertEqual(InsightsTier.forSessionCount(7), .full)
        XCTAssertEqual(InsightsTier.forSessionCount(100), .full)
    }

    func testSessionsToUnlock() {
        XCTAssertEqual(InsightsTier.sessionsToUnlock(currentCount: 3), 4)
        XCTAssertEqual(InsightsTier.sessionsToUnlock(currentCount: 6), 1)
        XCTAssertEqual(InsightsTier.sessionsToUnlock(currentCount: 7), 0)
    }

    func testUnlockLabelSingular() {
        XCTAssertEqual(InsightsTier.unlockLabel(currentCount: 6), "1 more session to unlock")
    }

    func testUnlockLabelPlural() {
        XCTAssertEqual(InsightsTier.unlockLabel(currentCount: 3), "4 more sessions to unlock")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodegen generate && xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TheMarginTests/InsightsTierTests --quiet`
Expected: FAIL — `InsightsTier` does not exist.

- [ ] **Step 3: Implement InsightsTier**

```swift
// Services/InsightsTier.swift
enum InsightsTier: Equatable {
    case empty    // 0 sessions
    case partial  // 1–6 sessions
    case full     // 7+ sessions

    static let unlockThreshold = 7

    static func forSessionCount(_ count: Int) -> InsightsTier {
        switch count {
        case 0: .empty
        case 1..<unlockThreshold: .partial
        default: .full
        }
    }

    static func sessionsToUnlock(currentCount: Int) -> Int {
        max(unlockThreshold - currentCount, 0)
    }

    static func unlockLabel(currentCount: Int) -> String {
        let remaining = sessionsToUnlock(currentCount: currentCount)
        return remaining == 1
            ? "1 more session to unlock"
            : "\(remaining) more sessions to unlock"
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TheMarginTests/InsightsTierTests --quiet`
Expected: All PASS.

- [ ] **Step 5: Create GhostChartView**

```swift
// Views/Insights/GhostChartView.swift
import SwiftUI

struct GhostChartView: View {
    enum Style {
        case bars
        case line
    }

    let style: Style
    let opacity: Double
    let unlockLabel: String?

    private let barHeights: [CGFloat] = [0.30, 0.55, 0.40, 0.70, 0.45, 0.60, 0.35]

    var body: some View {
        VStack(spacing: 12) {
            switch style {
            case .bars:
                ghostBars
            case .line:
                ghostLine
            }

            if let label = unlockLabel {
                Text(label)
                    .font(MarginTheme.literata(size: 11))
                    .italic()
                    .foregroundStyle(MarginTheme.textDim)
            }
        }
    }

    private var ghostBars: some View {
        Canvas { context, size in
            let barCount = CGFloat(barHeights.count)
            let spacing = size.width * 0.04
            let totalSpacing = spacing * (barCount - 1)
            let barWidth = (size.width - totalSpacing) / barCount
            for (i, height) in barHeights.enumerated() {
                let x = CGFloat(i) * (barWidth + spacing)
                let barHeight = size.height * height
                let rect = CGRect(x: x, y: size.height - barHeight, width: barWidth, height: barHeight)
                let path = RoundedRectangle(cornerRadius: 2).path(in: rect)
                context.fill(path, with: .color(MarginTheme.text.opacity(opacity)))
            }
        }
        .frame(height: 80)
    }

    private var ghostLine: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height * 0.8))
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.2),
                control1: CGPoint(x: size.width * 0.33, y: size.height * 0.6),
                control2: CGPoint(x: size.width * 0.66, y: size.height * 0.3)
            )
            context.stroke(path, with: .color(MarginTheme.text.opacity(opacity)), lineWidth: 2)
        }
        .frame(height: 50)
    }
}
```

- [ ] **Step 6: Build to verify**

Run: `xcodegen generate && xcodebuild -scheme TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet`
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
git add Services/InsightsTier.swift Views/Insights/GhostChartView.swift TheMarginTests/ServiceTests/InsightsTierTests.swift
git commit -m "feat: add InsightsTier logic and GhostChartView component"
```

---

### Task 7: Insights Progressive Reveal

**Files:**
- Modify: `Views/Insights/InsightsView.swift`

**Context:** InsightsView renders differently based on the session count of the filtered dataset. Tier 1 (0 sessions): centered ghost chart + quote + nudge. Tier 2 (1–6): calendar, stat cards, streaks, mood unlocked; bar chart + trend locked with ghost silhouettes. Tier 3 (7+): everything unlocked. See spec Section 4.

**Prerequisite:** InsightsView and its child views (WritingCalendarView, DayOfWeekChartView, WeeklyTrendChartView, MoodDistributionView, GoalProgressCardView, StatCardView) must already exist from the main plan (Task 12). This task adds the tier-based conditional rendering.

**Note:** `filteredSessions` must respect the project filter pill — the tier is computed per-filter, not globally. The spec also calls for charts to animate in (bars grow, line draws) on the first Tier 2 → Tier 3 transition; this animation is deferred and can be added as a follow-up polish task.

- [ ] **Step 1: Add tier logic to InsightsView**

```swift
// In InsightsView.swift — add tier-based rendering:

// At the top of the view body, compute the tier:
let sessionCount = filteredSessions.count
let tier = InsightsTier.forSessionCount(sessionCount)

// Then use it to conditionally render sections:

switch tier {
case .empty:
    // Tier 1: centered empty state
    VStack(spacing: 24) {
        Spacer()

        GhostChartView(style: .bars, opacity: 0.08, unlockLabel: nil)
            .padding(.horizontal, 40)

        if let tip = currentTip {
            VStack(spacing: 8) {
                Text("\"\(tip.text)\"")
                    .font(MarginTheme.newsreader(size: 16, weight: .light))
                    .italic()
                    .foregroundStyle(MarginTheme.text)
                    .multilineTextAlignment(.center)

                if let attribution = tip.attribution {
                    Text("— \(attribution)")
                        .font(MarginTheme.literata(size: 11))
                        .foregroundStyle(MarginTheme.textFaint)
                }
            }
            .padding(.horizontal, 32)
        }

        Text("Log your first session and your patterns will start to take shape.")
            .font(MarginTheme.literata(size: 13))
            .foregroundStyle(MarginTheme.textDim)
            .multilineTextAlignment(.center)

        Spacer()
    }

case .partial:
    // Tier 2: mix of unlocked sections and locked ghost charts
    ScrollView {
        VStack(spacing: 12) {
            // UNLOCKED
            WritingCalendarView(sessions: filteredSessions)
            StatCardsGridView(sessions: filteredSessions)
            StreakSummaryView(sessions: filteredSessions)

            // LOCKED — words by day
            lockedChartSection(
                title: "WORDS BY DAY OF WEEK",
                style: .bars,
                sessionCount: sessionCount
            )

            // LOCKED — weekly trend
            lockedChartSection(
                title: "WORDS PER WEEK",
                style: .line,
                sessionCount: sessionCount
            )

            // UNLOCKED
            MoodDistributionView(sessions: filteredSessions)
            GoalProgressCardView(
                project: selectedProject,
                sessions: filteredSessions,
                showProjectedDate: sessionCount >= 3
            )
        }
        .padding(.horizontal, 16)
    }

case .full:
    // Tier 3: everything unlocked
    ScrollView {
        VStack(spacing: 12) {
            WritingCalendarView(sessions: filteredSessions)
            StatCardsGridView(sessions: filteredSessions)
            StreakSummaryView(sessions: filteredSessions)
            DayOfWeekChartView(sessions: filteredSessions)
            WeeklyTrendChartView(sessions: filteredSessions)
            MoodDistributionView(sessions: filteredSessions)
            GoalProgressCardView(
                project: selectedProject,
                sessions: filteredSessions,
                showProjectedDate: true
            )
        }
        .padding(.horizontal, 16)
    }
}
```

- [ ] **Step 2: Add locked chart section helper**

```swift
// In InsightsView.swift — private helper:

private func lockedChartSection(
    title: String,
    style: GhostChartView.Style,
    sessionCount: Int
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(MarginTheme.literata(size: 9))
            .tracking(1)
            .foregroundStyle(MarginTheme.textFaint)

        GhostChartView(
            style: style,
            opacity: 0.06,
            unlockLabel: InsightsTier.unlockLabel(currentCount: sessionCount)
        )
    }
    .padding(16)
    .background(MarginTheme.surface)
    .cornerRadius(12)
}
```

- [ ] **Step 3: Update GoalProgressCardView for projected date gating**

Add a `showProjectedDate: Bool` parameter to GoalProgressCardView. When false, show "—" instead of the projected completion date. This gates the projection behind 3+ sessions as specified.

- [ ] **Step 4: Build and verify**

Run: `xcodegen generate && xcodebuild -scheme TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet`
Expected: Build succeeds. With 0 sessions: centered ghost chart + quote. With 1–6: mixed. With 7+: all charts.

- [ ] **Step 5: Commit**

```bash
git add Views/Insights/InsightsView.swift Views/Insights/GoalProgressCardView.swift
git commit -m "feat: add insights progressive reveal with 3-tier empty states"
```

---

### Task 8: Integration Verification

**Files:** None — this is a manual verification task.

**Context:** Verify the full first-launch flow end-to-end: welcome screen → create project → dashboard empty state → navigate to project detail → navigate to insights. Then log a session and verify empty states resolve.

- [ ] **Step 1: Reset app state for clean test**

Delete the app from the simulator to clear SwiftData and UserDefaults:

```bash
xcrun simctl erase booted
```

- [ ] **Step 2: Build and launch**

Run: `xcodegen generate && xcodebuild -scheme TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet`
Launch in simulator.

- [ ] **Step 3: Verify welcome screen**

1. App opens to WelcomeView (not tab bar)
2. Stack preview animates in, title types, quote fades, form reveals
3. Tap "Begin Writing" with empty fields → amber underline on project name field
4. Enter project name + word count goal → tap "Begin Writing" → transitions to dashboard

- [ ] **Step 4: Verify dashboard empty state**

1. Single blank page on manuscript stack
2. Stats show "0" for Total Words and Today
3. Progress bar at 0%
4. "The blank page has met its match." + "Tap the pen to log your first session."
5. Ink dots all empty, today's dot has amber glow
6. No "Hold to peek" text
7. Pen FAB visible and functional

- [ ] **Step 5: Verify project detail empty state**

1. Navigate to Projects tab → tap the project
2. Mini stack shows single blank page
3. Stats at zero, progress bar empty
4. Paper page with "No sessions yet. This is where your pages will live."

- [ ] **Step 6: Verify insights tiers**

1. Navigate to Insights tab → tier 1 (ghost chart, quote, nudge text)
2. Log 1 session via pen FAB → return to Insights → tier 2 (calendar + stats unlocked, charts locked with "6 more sessions" label)
3. Dashboard should now show streak counter instead of evocative text, "Hold to peek" visible

- [ ] **Step 7: Verify reinstall edge case**

1. Close the app
2. Clear UserDefaults only (not SwiftData): set `hasCompletedWelcome` to false programmatically or via debug menu
3. Relaunch → should skip welcome (projects exist) and go directly to tab bar

- [ ] **Step 8: Commit any fixes**

```bash
git add -A
git commit -m "fix: integration fixes for empty states flow"
```
