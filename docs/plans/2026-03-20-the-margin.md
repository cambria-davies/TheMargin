# The Margin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native iOS writing tracker app with session logging, timed writing sessions, manuscript progress visualization, streaks, and pattern insights.

**Architecture:** MVVM with SwiftUI + SwiftData. Models are `@Model` classes with `@Query`-driven reactive views. Business logic (streak calculation, insights aggregation, tip rotation) lives in testable service classes. The design system (color tokens, typography, paper textures) is centralized in a theme module. No third-party dependencies — only Apple frameworks + bundled Google Fonts.

**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Charts, UserNotifications, iOS 17+

**Specs:**
- Product: `docs/specs/2026-03-20-the-margin-design.md`
- Visual: `docs/specs/2026-03-20-the-margin-visual-design.md`
- Animations & Interactions: see below

## Execution Guardrails

- Treat all source paths in this plan as repo-root relative, matching `project.yml`. If an older snippet still shows `TheMargin/...`, strip that prefix.
- This repository is already scaffolded. Do not create a new Xcode project, do not create a nested `TheMargin/` source directory, and do not run `git init`.
- Target iOS 17-compatible APIs throughout. Use `.tabItem { Label(...) }` for the tab bar rather than the newer `Tab(...)` API.
- For implementation tasks, follow RED -> GREEN -> REFACTOR before moving to the next task. Tests must fail for the intended reason before the production code is written.
- All `@Observable` classes must be marked `@MainActor`.
- Never use Grand Central Dispatch (`DispatchQueue`). Use `Task` / `async`/`await` / `Task.sleep(for:)`.
- Never use `String(format:)` for number/time formatting. Use `Duration.formatted()` or `FormatStyle` APIs.
- Prefer `Date.now` over `Date()`.
- Prefer `String.replacing(_:with:)` over `String.replacingOccurrences(of:with:)`.
- Use `@Entry` macro for custom `EnvironmentValues` keys instead of the legacy `EnvironmentKey` pattern.
- Use `.sensoryFeedback()` modifier instead of `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`.
- All animations must check `@Environment(\.accessibilityReduceMotion)` and substitute opacity transitions when Reduce Motion is enabled.
- Custom font sizes must use `@ScaledMetric` for Dynamic Type support.
- Icon-only buttons must always include a text label for VoiceOver (use `.labelStyle(.iconOnly)` to hide it visually).
- Tappable elements must use `Button`, not `onTapGesture()`, unless tap location/count is needed.
- Avoid `GeometryReader` when `Canvas`, `containerRelativeFrame()`, or hardcoded values suffice.
- Extract `@ViewBuilder` methods/computed properties returning `some View` into separate `View` structs.

---

## Animations & Interactions Spec

Detailed animation timing, interaction design, and iOS-specific features refined through interactive prototyping. These specs supplement and override the visual design spec where they conflict.

### Carriage Mechanism (Timer Screen)

| Element | Spec |
|---------|------|
| Per-character slider | Mechanical precision — step-locked, no CSS transition, discrete positions |
| Typing speed | 110ms ±15ms base interval (~9 chars/sec), subtle random jitter per character |
| Character appearance | Strike impact — scale(1.12)→1.0, translateY(-1px)→0, 50ms ease-out, fully opaque from frame one |
| Ink variation | 3 weights (ink-black `#2A2218`, ink-medium `#4A3E30`, ink-dark `#362E24`), weighted random distribution (60/25/15), non-deterministic per render |
| Micro-jitter | ±0.5px translateY, ±0.4° rotation per character |
| Cursor | Blinks twice (530ms interval) before first character only, then disappears. The amber print-guide dot on the carriage slider is the sole position indicator during typing |
| Carriage return | Fast mechanical slide, 80ms ease-in (accelerating — like releasing stored tension) |
| Carriage return sequence | 30ms hold at end of line → bell ding → 60ms gap → 80ms slide left → 120ms pause → next line begins |
| Paper feed | Paper rises **above** the platen — text accumulates upward out of the machine. Completed lines stay visible. The strike point is fixed just above the platen |
| Sounds | Real typewriter recordings (CC0 public domain), sourced from Freesound: [Hermes Baby by evsecrets (#334458)](https://freesound.org/people/evsecrets/sounds/334458/) and [Typewriter by exterminat (#164807)](https://freesound.org/people/exterminat/sounds/164807/). Key strike: played with pitch variation 0.94–1.08× and volume variation per character. Bell: real margin bell. Carriage return: real recording at 1.3× playback speed. For iOS: bundle as predecoded `.caf` assets, then play via `AVAudioEngine` for low-latency polyphonic playback |

### Manuscript Stack

| Element | Spec |
|---------|------|
| Page land physics | Paper drop: translateY(-20px) → +2px overshoot → -1px bounce → 0 settle. Duration: 350ms (180ms drop, 100ms bounce-back, 70ms settle) |
| Stagger curve | **Decelerating** — fast at bottom, deliberate at top. Quadratic ease-out: `t = 1 - (1 - i/n)^2.2` mapped to 800ms total build time |
| Page jitter | ±1.5px translateX, ±0.2° rotation per page — seeded per page index for consistency |
| Page geometry | 240px wide (scaled up from original 220px), 9px tall per page (scaled up from 7px). Top page: 10px tall with deeper shadow |
| Pages overlap | -1px negative margin between pages, 0.5px subtle box-shadow — reads as solid stack |
| Stack pages | Clean blank paper — no ruled lines or red margin (manuscript pages, not notebook) |
| Shadow/glow | Radial shadow beneath stack + amber radial glow behind. Both fade in at 50% build completion |
| Visual cap | Max 40 visual pages on dashboard, 15 on project cards. Stagger interval adapts: `800ms ÷ pageCount`, min 15ms |
| Empty state | Single blank page, slightly curled corner |

### Stack Fan Interaction (NEW — replaces recent sessions list)

The manuscript stack on the dashboard is interactive. Long-pressing fans out the top pages to reveal recent session data, replacing the flat "Recent" session list from the original spec.

| Element | Spec |
|---------|------|
| Trigger | `UILongPressGestureRecognizer`, 300ms minimum press duration |
| Fan style | Cascade overlap — pages spread vertically with ~60% overlap, showing a data strip on each page |
| Pages shown | Top 5 most recent sessions |
| Order | Reverse chronological — today/most recent on top |
| Content per page | Date (Special Elite 11px uppercase), word count (Special Elite 15px), mood glyph (13px). Minimal — just enough to identify the session |
| Fan animation | 350ms spring, margin-top transitions from -44px (collapsed) to -26px (fanned) |
| Data reveal | Session data fades in with 250ms transition, 100ms delay after fan starts |
| Collapse | Tap anywhere outside, or tap the stack again. Same 350ms spring back |
| Discoverability | "Hold to peek" text (10px, dim) below the stack shadow. Fades out when fanned |
| Today indicator | Today's session date label renders in amber (#C4956A) instead of ink color |
| Tap fanned page | Navigates to edit that session |

**Dashboard layout change:** With the stack fan replacing the session list, the dashboard is simplified to: project selector → manuscript stack (centered, scaled up) → "Hold to peek" → stats (Total Words, Today) → progress bar → streak with ink dots. Content is vertically centered with generous spacing.

### Streak Display (NEW — ink dots)

| Element | Spec |
|---------|------|
| Layout | Large streak number (Newsreader 36px amber) with "day streak" (10px, dim) centered below it. To the right: 7 ink dots + "best: N" |
| Ink dots | 7 circular dots representing the current week (Mon–Sun). 12px diameter, 8px gap |
| Active dot | Filled amber (#C4956A) — user wrote that day |
| Empty dot | Transparent with 1.5px border (#3E3A34) — user didn't write |
| Today dot | Filled amber with 6px box-shadow glow (rgba(196,149,106,0.5)) |
| Spacing | 44px margin-top above the streak row, creating clear separation from the progress bar |

### Choreography — Dashboard Open

Full orchestrated sequence plays every app open. Tight 1.5s timeline:

| Time | Element | Animation |
|------|---------|-----------|
| 0–800ms | Stack build | Pages land one by one, decelerating stagger. Shadow/glow at 50% |
| 800–1300ms | Stats odometer | Digits roll per-column, right-to-left, 500ms cubic-bezier(0.2,0,0.1,1) |
| 900–1300ms | Progress bar | Width 0%→target, 800ms ease-out (overlaps with stats) |
| 1100–1300ms | Streak | Fade in, 200ms |
| 1200–1400ms | Ink dots | Fade in, staggered |
| 1300–1500ms | Pen FAB | Scale 0→1, 200ms spring |

**Tab switching:** Instant swap, no animation. Tab highlight is the only feedback.

### Choreography — Save-to-Stack

Full 5-step ceremony. The one dramatic moment in the app (~2.8s total):

**Phase 1 — Form Transforms (0–900ms)**

| Time | Step | Animation |
|------|------|-----------|
| 0ms | Paper lifts | translateY(-4px), shadow deepens, 200ms ease-out |
| 200ms | Form compresses | Text fades (300ms), paper scaleY 1→0.08 (400ms ease-in-out) |
| 600ms | Pages split | Compressed page splits into N pages (wordCount ÷ 250) with horizontal jitter, 300ms |

**Phase 2 — Pages Land (900–1700ms)**

| Time | Step | Animation |
|------|------|-----------|
| 900ms | Pages cascade | One by one, 180ms stagger, each with settle-bounce (280ms). Pages start amber-highlighted, fade to paper-white after landing |
| 1000ms | Stats odometer | Ticks up in real-time as each page lands — word total increments during cascade |
| 900ms | Progress bar | Fills simultaneously with cascade, 800ms ease-out |

**Phase 3 — Confirmation (1700–2800ms)**

| Time | Step | Animation |
|------|------|-----------|
| 1700ms | Typewritten confirmation | "N new pages." types out letter-by-letter in Special Elite (110ms/char) with key strike sounds. No writing tip — keep focus on progress |
| 2200ms | Streak pulse | Scale 1→1.15→1, 300ms ease-out. Number increments if first session today |
| 2400ms | Confirmation fades | 400ms opacity transition |

### Paper & Ink

| Element | Spec |
|---------|------|
| Paper grain | SVG noise texture at 3% opacity. "Feel not see" — barely perceptible, prevents flat-CSS feel |
| Ruled lines | Only on log form, timer paper feed, and session pages in project detail. NOT on manuscript stack pages |
| Mood ink-wash fill | Ink drop spread: radial fill from center with feathered edge (box-shadow blur), 400ms ease-out deceleration. Glyph inverts to paper color 100ms after ink starts spreading. Deselect collapses ink back to center |
| Mood colors | Dry: #7A5C50, Grinding: #8A8070, Steady: #A09060, Flow: #C4956A, Breakthrough: #D4A85C |
| Word count input (log form) | Heavy strike: scale(1.15)→1.0, translateY(-2px)→0, 60ms. Key strike sound + `.sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.4))` haptic per digit. Blinking cursor at insertion point. Ink variation + jitter applied |
| Timer tip vs. log input | Timer tip is passive (scale 1.12, no sound). Log input is user-initiated (scale 1.15, sound + haptic). Active interactions are more dramatic |

### iOS-Specific Features

**Haptic feedback (all low effort):**

| Interaction | Haptic |
|-------------|--------|
| Stack page lands (build + save) | `.sensoryFeedback(.impact(weight: .light))` per page, `.impact(weight: .medium)` on last page. Rhythm matches deceleration curve |
| Save-to-stack sequence | `.impact(weight: .light)` on paper lift, `.impact(flexibility: .rigid)` on compress, `.impact(weight: .light)` per cascade page, `.sensoryFeedback(.success)` on confirmation |
| Timer carriage return | `.impact(flexibility: .rigid)` on bell ding, `.impact(weight: .light)` on carriage slide |
| Mood selection | `.impact(weight: .medium)` on select, `.impact(weight: .light)` on deselect |
| Word count digit input | `.impact(weight: .light)` per keystroke (paired with key strike sound) |

**Gestures:**

| Interaction | Gesture |
|-------------|---------|
| Stack fan | UILongPressGestureRecognizer (300ms) to fan, tap to collapse |
| Log form dismiss | UIPanGestureRecognizer — paper slides off bottom with slight rotation. Velocity-dependent: fast swipe sends it flying, slow drag lets you pull back. Interactive dismiss |

---

## File Structure

```
TheMarginApp.swift                         # App entry, ModelContainer, font registration
ContentView.swift                          # 3-tab root (Home, Projects, Insights)

Models/
├── Project.swift                          # @Model — project entity
├── Session.swift                          # @Model — writing session entity
├── WritingTip.swift                       # @Model — bundled tips/quotes
├── Mood.swift                             # Enum with glyph, color, display name
├── TipCategory.swift                      # Enum: craft, quote
└── SchemaVersioning.swift                 # VersionedSchema + SchemaMigrationPlan

Services/
├── StreakCalculator.swift                 # Consecutive-day streak from sessions
├── InsightsCalculator.swift               # Aggregations: averages, best day, trends
├── TipRotationService.swift               # Random-without-repeat daily tip
├── NotificationService.swift              # Schedule/cancel daily reminders
├── CSVExportService.swift                 # Generate CSV string from sessions
└── TypewriterAudioEngine.swift            # AVAudioEngine for key strike/bell/carriage sounds

Theme/
├── MarginTheme.swift                      # Color tokens (Lamplight/Daylight), font helpers
├── PaperSurface.swift                     # ViewModifier: paper bg, ruled lines, red margin
├── TypewriterText.swift                   # View: ink variation + micro-jitter per character
└── StableRNG.swift                        # Deterministic PRNG for stable procedural textures

Components/
├── ManuscriptStackView.swift              # Stack visualization (all sizes) + fan interaction
├── MoodSelectorView.swift                 # 5-mood selector with ink-wash animation
├── MoodGlyphView.swift                    # Single mood glyph rendering
├── PenFABView.swift                       # Floating action button + popup
├── StatCardView.swift                     # Reusable stat display card
├── OdometerView.swift                     # Typewriter digit roller for stat numbers
├── StreakDotsView.swift                   # Ink dot weekly streak display
├── TypewriterConfirmation.swift           # Letter-by-letter typed confirmation text
└── TimerButton.swift                      # Extracted timer control button

Views/
├── Dashboard/
│   └── DashboardView.swift                # Home tab — stack, stats, streak (no session list)
├── Timer/
│   ├── TimerView.swift                    # Timer screen with carriage mechanism
│   └── TimerViewModel.swift               # Timer state machine (run/pause/stop)
├── LogSession/
│   ├── LogSessionView.swift               # Paper-styled log form
│   └── LogSessionViewModel.swift          # Form state, validation, save
├── Projects/
│   ├── ProjectsListView.swift             # Projects tab — card list
│   ├── ProjectDetailView.swift            # Push view — stack, stats, session pages
│   ├── ProjectCardView.swift              # Single project card
│   ├── SessionPageView.swift              # Session rendered as paper page
│   └── NewProjectView.swift               # Create/edit project modal
├── Insights/
│   ├── InsightsView.swift                 # Insights tab — scrollable stats page
│   ├── WritingCalendarView.swift          # Week/month/year frequency calendar
│   ├── DayOfWeekChartView.swift           # 7-bar chart (Swift Charts)
│   ├── WeeklyTrendChartView.swift         # 8-week line chart (Swift Charts)
│   ├── MoodDistributionView.swift         # Horizontal bar breakdown
│   └── GoalProgressCardView.swift         # Goal % + projected completion
└── Settings/
    └── SettingsView.swift                 # Settings screen (gear icon destination)

Resources/
├── Fonts/                                 # .ttf files for all 4 font families
├── Audio/                                 # Typewriter sounds (CC0, sliced from Freesound)
│   ├── key-strike.caf                     # Single key press (~100ms), from exterminat #164807
│   ├── bell.caf                           # Margin bell (~400ms), from evsecrets #334458
│   └── carriage-return.caf               # Carriage return (~250ms), from evsecrets #334458
├── writing-tips.json                      # Bundled tips/quotes
└── Assets.xcassets/                       # Colors, app icon

TheMarginTests/
├── ModelTests/
│   ├── ProjectTests.swift                # Project computed properties
│   └── SessionTests.swift                # Session creation, relationships
├── ServiceTests/
│   ├── StreakCalculatorTests.swift        # Edge cases: gaps, timezone, empty
│   ├── InsightsCalculatorTests.swift     # Averages, best day, trends, projections
│   ├── TipRotationServiceTests.swift    # Random-without-repeat cycling
│   └── CSVExportServiceTests.swift      # Export format, escaping, encoding
└── ViewModelTests/
    ├── TimerViewModelTests.swift         # State transitions, elapsed time
    └── LogSessionViewModelTests.swift   # Validation, save behavior
```

---

### Task 1: Validate Existing Project Scaffold + Fonts

**Files:**
- Verify: `TheMargin.xcodeproj`
- Verify/Modify: `project.yml`
- Verify/Modify: `TheMarginApp.swift`
- Verify/Modify: `ContentView.swift`
- Verify: `Resources/Fonts/*.ttf`
- Verify/Modify: `Info.plist`

**Context:** This repository is already scaffolded and configured from repo-root paths via `project.yml`. Do not create a new Xcode project, do not create a nested `TheMargin/` source directory, and do not run `git init`. This task validates the checked-in scaffold, confirms the bundled fonts/config, and refines the root tab skeleton so the baseline matches the project target.

- [ ] **Step 1: Validate the checked-in project configuration**

Confirm that `project.yml`, `TheMargin.xcodeproj`, `TheMarginApp.swift`, `ContentView.swift`, and `Info.plist` already align with:
- iOS deployment target `17.0`
- repo-root source paths
- the existing `TheMargin` and `TheMarginTests` targets
- SwiftData wiring temporarily commented or staged until models exist

- [ ] **Step 2: Verify bundled fonts and Info.plist/project settings**

Confirm the checked-in Google Fonts are present and registered:
- [Special Elite](https://fonts.google.com/specimen/Special+Elite) — Regular only
- [Newsreader](https://fonts.google.com/specimen/Newsreader) — Light (300), Regular (400), SemiBold (600)
- [Literata](https://fonts.google.com/specimen/Literata) — Light (300), Regular (400), Medium (500)
- [JetBrains Mono](https://fonts.google.com/specimen/JetBrains+Mono) — Light (300), Regular (400)

Fonts should live in `Resources/Fonts/` and be registered via `Info.plist`/`project.yml`:

```xml
<key>UIAppFonts</key>
<array>
    <string>SpecialElite-Regular.ttf</string>
    <string>Newsreader-Light.ttf</string>
    <string>Newsreader-Regular.ttf</string>
    <string>Newsreader-SemiBold.ttf</string>
    <string>Literata-Light.ttf</string>
    <string>Literata-Regular.ttf</string>
    <string>Literata-Medium.ttf</string>
    <string>JetBrainsMono-Light.ttf</string>
    <string>JetBrainsMono-Regular.ttf</string>
</array>
```

- [ ] **Step 3: Set up the tab bar skeleton in ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
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
```

- [ ] **Step 4: Configure TheMarginApp.swift with ModelContainer**

```swift
import SwiftUI
import SwiftData

@main
struct TheMarginApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // .modelContainer(for: [Project.self, Session.self, WritingTip.self], migrationPlan: MarginMigrationPlan.self)
        // Uncomment once models + SchemaVersioning exist (Task 2).
    }
}
```

This should match the existing checked-in scaffold: keep the model container commented until the models exist, rather than breaking the baseline build.

- [ ] **Step 5: Delete the template Item.swift if it exists**

- [ ] **Step 6: Build and run to verify the tab bar renders**

Build from the existing scaffold and verify the 3-tab skeleton renders from repo-root sources. Restore `.modelContainer` once Task 2 is complete.

- [ ] **Step 7: Commit**

```bash
git add project.yml TheMarginApp.swift ContentView.swift Info.plist Resources/Fonts/
git commit -m "feat: validate existing scaffold, fonts, and root tab shell"
```

---

### Task 2: SwiftData Models + Enums

**Files:**
- Create: `Models/Mood.swift`
- Create: `Models/TipCategory.swift`
- Create: `Models/Project.swift`
- Create: `Models/Session.swift`
- Create: `Models/WritingTip.swift`
- Create: `TheMarginTests/ModelTests/ProjectTests.swift`
- Create: `TheMarginTests/ModelTests/SessionTests.swift`

**Context:** Data model from product spec "Data Model" section. `Project` has a `startingWordCount` field for pre-existing progress. `totalWords` is computed as `startingWordCount + sum(sessions.wordCount)`. Mood uses a mix of ink-drawn SVG icons (dry nib, stone, seedling) and typographic glyphs (∞, ✦) with muted ink-wash colors from visual spec.

**Execution order for this task:** Write the failing `Project` and `Session` behavior tests first, run them to confirm RED, then implement the enums/models shown below, rerun the tests to GREEN, and only then re-enable `.modelContainer` in `TheMarginApp.swift`.

- [ ] **Step 1: Write Mood enum**

```swift
// TheMargin/Models/Mood.swift
import SwiftUI

enum Mood: String, Codable, CaseIterable {
    case dry, grinding, steady, flow, breakthrough

    /// For moods with typographic glyphs (flow, breakthrough).
    /// SVG-based moods (dry, grinding, steady) use MoodIconView instead.
    var glyph: String {
        switch self {
        case .dry: "✎"           // fallback — prefer MoodIconView for SVG nib
        case .grinding: "▪"      // fallback — prefer MoodIconView for SVG stone
        case .steady: "⌇"       // fallback — prefer MoodIconView for SVG seedling
        case .flow: "∞"
        case .breakthrough: "✦"
        }
    }

    /// Whether this mood uses an ink-drawn SVG icon (true) or a typographic glyph (false).
    var usesSVGIcon: Bool {
        switch self {
        case .dry, .grinding, .steady: true
        case .flow, .breakthrough: false
        }
    }

    var displayName: String {
        switch self {
        case .dry: "Dry"
        case .grinding: "Grinding"
        case .steady: "Steady"
        case .flow: "Flow"
        case .breakthrough: "Breakthrough"
        }
    }

    var color: Color {
        switch self {
        case .dry: Color(hex: 0x7A5C50)
        case .grinding: Color(hex: 0x8A8070)
        case .steady: Color(hex: 0xA09060)
        case .flow: Color(hex: 0xC4956A)
        case .breakthrough: Color(hex: 0xD4A85C)
        }
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
```

- [ ] **Step 2: Write TipCategory enum**

```swift
// TheMargin/Models/TipCategory.swift
enum TipCategory: String, Codable {
    case craft, quote
}
```

- [ ] **Step 3: Write Project model**

```swift
// TheMargin/Models/Project.swift
import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var wordCountGoal: Int?
    var startingWordCount: Int
    var createdAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \Session.project)
    var sessions: [Session]

    var totalWords: Int {
        startingWordCount + sessions.reduce(0) { $0 + $1.wordCount }
    }

    var wordsToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        return sessions
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.wordCount }
    }

    var goalProgress: Double? {
        guard let goal = wordCountGoal, goal > 0 else { return nil }
        return min(Double(totalWords) / Double(goal), 1.0)
    }

    var visualPageCount: Int {
        max(totalWords / 250, totalWords > 0 ? 1 : 0)
    }

    init(
        name: String,
        wordCountGoal: Int? = nil,
        startingWordCount: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.wordCountGoal = wordCountGoal
        self.startingWordCount = startingWordCount
        self.createdAt = Date.now
        self.isArchived = false
        self.sessions = []
    }
}
```

- [ ] **Step 4: Write Session model**

```swift
// TheMargin/Models/Session.swift
import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var project: Project?
    var date: Date
    var wordCount: Int
    var notes: String?
    var mood: Mood
    var durationSeconds: Int?
    var chapterTag: String?

    init(
        project: Project,
        date: Date = .now,
        wordCount: Int,
        notes: String? = nil,
        mood: Mood,
        durationSeconds: Int? = nil,
        chapterTag: String? = nil
    ) {
        self.id = UUID()
        self.project = project
        self.date = date
        self.wordCount = wordCount
        self.notes = notes
        self.mood = mood
        self.durationSeconds = durationSeconds
        self.chapterTag = chapterTag
    }
}
```

- [ ] **Step 5: Write WritingTip model**

```swift
// TheMargin/Models/WritingTip.swift
import Foundation
import SwiftData

@Model
final class WritingTip {
    var id: UUID
    var text: String
    var attribution: String?
    var category: TipCategory

    init(text: String, attribution: String? = nil, category: TipCategory) {
        self.id = UUID()
        self.text = text
        self.attribution = attribution
        self.category = category
    }
}
```

- [ ] **Step 5b: Create SchemaVersioning with VersionedSchema and SchemaMigrationPlan**

SwiftData will crash on launch if the on-disk schema doesn't match the model definitions and no migration plan is provided. Set this up now — before any data is persisted — so every future schema change is a lightweight migration instead of a "delete the app" moment.

```swift
// Models/SchemaVersioning.swift
import SwiftData

enum MarginSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Project.self, Session.self, WritingTip.self]
    }
}

enum MarginMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MarginSchemaV1.self]
    }

    // No migration stages yet — V1 is the initial schema.
    // When V2 arrives, add MarginSchemaV2 and a .migrate(from:to:) stage here.
    static var stages: [MigrationStage] {
        []
    }
}
```

**Why this matters:** During development, you *will* add fields (e.g. a `genre` on Project, or a `wordCountDelta` on Session). Without a migration plan, SwiftData can't reconcile the old on-disk schema with the new model. The app crashes on launch, and the only fix is deleting app data. With `VersionedSchema` in place from day one, adding a field is: (1) create `MarginSchemaV2` with the new models, (2) add a `.lightweight` migration stage, (3) update `ModelContainer`. No data loss.

**How future schema changes work:**

```swift
// Example: adding Session.wordCountDelta in a future task
enum MarginSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Project.self, Session.self, WritingTip.self]
    }
}

enum MarginMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MarginSchemaV1.self, MarginSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: MarginSchemaV1.self, toVersion: MarginSchemaV2.self)]
    }
}
```

For non-lightweight migrations (renaming, splitting, or transforming data), use `.custom(fromVersion:toVersion:willMigrate:didMigrate:)` with a closure that performs the data transform.

- [ ] **Step 6: Write failing tests for Project computed properties**

```swift
// TheMarginTests/ModelTests/ProjectTests.swift
import XCTest
@testable import TheMargin

final class ProjectTests: XCTestCase {
    func testTotalWordsIncludesStartingWordCount() {
        let project = Project(name: "Novel", startingWordCount: 30000)
        let session = Session(project: project, wordCount: 500, mood: .steady)
        project.sessions = [session]
        XCTAssertEqual(project.totalWords, 30500)
    }

    func testTotalWordsWithNoSessions() {
        let project = Project(name: "Novel", startingWordCount: 10000)
        XCTAssertEqual(project.totalWords, 10000)
    }

    func testGoalProgressCalculation() {
        let project = Project(name: "Novel", wordCountGoal: 80000, startingWordCount: 40000)
        XCTAssertEqual(project.goalProgress, 0.5, accuracy: 0.001)
    }

    func testGoalProgressNilWhenNoGoal() {
        let project = Project(name: "Blog")
        XCTAssertNil(project.goalProgress)
    }

    func testGoalProgressCapsAtOne() {
        let project = Project(name: "Short", wordCountGoal: 1000, startingWordCount: 2000)
        XCTAssertEqual(project.goalProgress, 1.0)
    }

    func testVisualPageCount() {
        let project = Project(name: "Novel", startingWordCount: 10000)
        XCTAssertEqual(project.visualPageCount, 40) // 10000 / 250
    }

    func testVisualPageCountMinimumOne() {
        let project = Project(name: "Started")
        let session = Session(project: project, wordCount: 100, mood: .grinding)
        project.sessions = [session]
        XCTAssertEqual(project.visualPageCount, 1) // 100 / 250 rounds to 0, but > 0 words → 1
    }

    func testVisualPageCountZeroWhenEmpty() {
        let project = Project(name: "Empty")
        XCTAssertEqual(project.visualPageCount, 0)
    }
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `Cmd+U` in Xcode or `xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16'`

Expected: All 8 tests pass.

- [ ] **Step 8: Uncomment the .modelContainer line in TheMarginApp.swift**

Now that models and `SchemaVersioning` exist, restore the model container with the migration plan. Build and run — app should launch with the 3-tab skeleton.

```swift
.modelContainer(for: [Project.self, Session.self, WritingTip.self], migrationPlan: MarginMigrationPlan.self)
```

- [ ] **Step 9: Commit**

```bash
git add Models/ TheMarginTests/ModelTests/ TheMarginApp.swift
git commit -m "feat: add SwiftData models (Project, Session, WritingTip) with test-first coverage"
```

---

### Task 3: Theme / Design System

**Files:**
- Create: `Theme/MarginTheme.swift`
- Create: `Theme/PaperSurface.swift`
- Create: `Theme/TypewriterText.swift`

**Context:** Visual spec defines two themes (Lamplight dark, Daylight light) as the same objects under different lighting. Color tokens in "Color Palette" section. Typography rules in "Typography" section. Paper surfaces in "Global Elements > Paper Surfaces". TypewriterText in "Global Elements > Typewriter Text on Paper". Use `@Environment(\.colorScheme)` to switch themes automatically.

- [ ] **Step 1: Create MarginTheme with color tokens and font helpers**

```swift
// TheMargin/Theme/MarginTheme.swift
import SwiftUI

struct MarginTheme {
    let colorScheme: ColorScheme

    // MARK: - Theme-adaptive colors
    var background: Color {
        colorScheme == .dark ? Color(hex: 0x1A1A18) : Color(hex: 0xF5F0E8)
    }
    var surface: Color {
        colorScheme == .dark ? Color(hex: 0x242422) : Color(hex: 0xFFFDF7)
    }
    var surfaceRaised: Color {
        colorScheme == .dark ? Color(hex: 0x2E2E2A) : Color(hex: 0xF0EBE0)
    }
    var text: Color {
        colorScheme == .dark ? Color(hex: 0xE8DFD0) : Color(hex: 0x2C2418)
    }
    var textDim: Color {
        colorScheme == .dark ? Color(hex: 0x908880) : Color(hex: 0x8A7E6A)
    }
    var textFaint: Color {
        colorScheme == .dark ? Color(hex: 0x605850) : Color(hex: 0xA89E8E)
    }
    var amber: Color {
        colorScheme == .dark ? Color(hex: 0xC4956A) : Color(hex: 0xA07850)
    }
    var amberDim: Color {
        colorScheme == .dark
            ? Color(hex: 0xC4956A, opacity: 0.15)
            : Color(hex: 0xA07850, opacity: 0.12)
    }
    var amberMid: Color {
        colorScheme == .dark
            ? Color(hex: 0xC4956A, opacity: 0.4)
            : Color(hex: 0xA07850, opacity: 0.3)
    }

    // MARK: - Shared (theme-independent)
    static let paper = Color(hex: 0xF5F0E8)
    static let paperDark = Color(hex: 0xE8E0D0)
    static let paperShadow = Color(hex: 0xD4C8B4)
    static let inkBlack = Color(hex: 0x2A2218)
    static let inkMedium = Color(hex: 0x4A3E30)
    static let inkDark = Color(hex: 0x362E24)
    static let inkLight = Color(hex: 0x6A5E50)
    static let redMargin = Color(red: 200/255, green: 80/255, blue: 80/255, opacity: 0.15)

    // MARK: - Ink variation colors (for typewriter text)
    static let inkVariation: [Color] = [inkBlack, inkMedium, inkDark]
}

// MARK: - Font helpers
extension Font {
    static func typewriter(_ size: CGFloat) -> Font {
        .custom("SpecialElite-Regular", size: size)
    }
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String = switch weight {
        case .light: "Newsreader-Light"
        case .semibold: "Newsreader-SemiBold"
        default: "Newsreader-Regular"
        }
        return .custom(name, size: size)
    }
    static func literata(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String = switch weight {
        case .light: "Literata-Light"
        case .medium: "Literata-Medium"
        default: "Literata-Regular"
        }
        return .custom(name, size: size)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String = switch weight {
        case .light: "JetBrainsMono-Light"
        default: "JetBrainsMono-Regular"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Environment key
extension EnvironmentValues {
    @Entry var marginTheme = MarginTheme(colorScheme: .dark)
}
```

**Note:** The environment key lets views access `@Environment(\.marginTheme) var theme`. Inject it at the root in `ContentView` based on `@Environment(\.colorScheme)`.

- [ ] **Step 2: Create PaperSurface ViewModifier**

```swift
// TheMargin/Theme/PaperSurface.swift
import SwiftUI

struct PaperSurface: ViewModifier {
    let ruledLines: Bool
    let redMargin: Bool

    init(ruledLines: Bool = true, redMargin: Bool = true) {
        self.ruledLines = ruledLines
        self.redMargin = redMargin
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    MarginTheme.paper
                    // Paper grain noise texture — seeded RNG for stable grain across renders
                    Canvas { context, size in
                        var rng = StableRNG(seed: 42)
                        let dotCount = Int(size.width * size.height * 0.003)
                        for _ in 0..<dotCount {
                            let x = CGFloat.random(in: 0...size.width, using: &rng)
                            let y = CGFloat.random(in: 0...size.height, using: &rng)
                            let opacity = Double.random(in: 0.02...0.06, using: &rng)
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                with: .color(.black.opacity(opacity))
                            )
                        }
                    }

                    if ruledLines {
                        RuledLinesCanvas()
                    }
                    if redMargin {
                        HStack {
                            Rectangle()
                                .fill(MarginTheme.redMargin)
                                .frame(width: 1)
                                .padding(.leading, 40)
                            Spacer()
                        }
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 4))
            .shadow(color: MarginTheme.paperShadow.opacity(0.3), radius: 3, y: 2)
    }
}

/// Deterministic PRNG for stable procedural textures across renders.
struct StableRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Ruled lines drawn via Canvas (avoids GeometryReader layout side-effects).
struct RuledLinesCanvas: View {
    let lineSpacing: Double = 28

    var body: some View {
        Canvas { context, size in
            let lineCount = Int(size.height / lineSpacing)
            for i in 1...max(lineCount, 1) {
                let y = Double(i) * lineSpacing
                let path = Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.blue.opacity(0.07)), lineWidth: 0.5)
            }
        }
    }
}

extension View {
    func paperSurface(ruledLines: Bool = true, redMargin: Bool = true) -> some View {
        modifier(PaperSurface(ruledLines: ruledLines, redMargin: redMargin))
    }
}
```

- [ ] **Step 3: Create TypewriterText view**

```swift
// TheMargin/Theme/TypewriterText.swift
import SwiftUI

struct TypewriterText: View {
    let text: String
    let fontSize: CGFloat

    /// Seeded jitter per character index — stable across renders.
    private func jitterY(for index: Int) -> Double {
        let seed = Double(index * 7 + 3)
        return sin(seed) * 0.5
    }

    private func jitterRotation(for index: Int) -> Double {
        let seed = Double(index * 13 + 7)
        return sin(seed) * 0.4
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .font(.typewriter(fontSize))
                    .foregroundStyle(MarginTheme.inkVariation[index % 3])
                    .rotationEffect(.degrees(jitterRotation(for: index)))
                    .offset(y: jitterY(for: index))
            }
        }
    }
}
```

- [ ] **Step 4: Inject theme at the root of ContentView**

Update `ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem { Label("Home", systemImage: "doc.text") }

            Text("Projects")
                .tabItem { Label("Projects", systemImage: "books.vertical") }

            Text("Insights")
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
        .tint(MarginTheme(colorScheme: colorScheme).amber)
        .environment(\.marginTheme, MarginTheme(colorScheme: colorScheme))
    }
}
```

- [ ] **Step 5: Build and verify fonts render in a preview**

Create a temporary preview in `MarginTheme.swift` that renders sample text in all 4 font families. Verify each font loads correctly in the canvas. Remove the preview after verification.

- [ ] **Step 6: Commit**

```bash
git add Theme/ ContentView.swift
git commit -m "feat: add design system — color tokens, typography, paper surface, typewriter text"
```

---

### Task 4: Services — Streak Calculator

**Files:**
- Create: `TheMargin/Services/StreakCalculator.swift`
- Create: `TheMarginTests/ServiceTests/StreakCalculatorTests.swift`

**Context:** Streak = consecutive calendar days (device timezone) with at least one session. Count backward from today. Also compute longest streak ever. See product spec "Derived Data" section.

- [ ] **Step 1: Write failing tests**

```swift
// TheMarginTests/ServiceTests/StreakCalculatorTests.swift
import XCTest
@testable import TheMargin

final class StreakCalculatorTests: XCTestCase {
    private let calendar = Calendar.current

    private func date(daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: .now))!
    }

    func testCurrentStreakConsecutiveDays() {
        let dates = [date(daysAgo: 0), date(daysAgo: 1), date(daysAgo: 2)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 3)
    }

    func testCurrentStreakBreaksOnGap() {
        let dates = [date(daysAgo: 0), date(daysAgo: 1), date(daysAgo: 3)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 2)
    }

    func testCurrentStreakZeroWhenNoSessionToday() {
        let dates = [date(daysAgo: 2), date(daysAgo: 3)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 0)
    }

    func testCurrentStreakCountsYesterdayIfNoSessionToday() {
        // If user hasn't written today yet, streak from yesterday still counts
        // but current streak shows as the consecutive days ending yesterday
        let dates = [date(daysAgo: 1), date(daysAgo: 2), date(daysAgo: 3)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        // Streak is 3 days (yesterday, day before, day before that)
        // but marked as "at risk" since today hasn't been logged yet
        XCTAssertEqual(result.current, 3)
        XCTAssertTrue(result.atRisk)
    }

    func testLongestStreakFindsHistoricalMax() {
        // Current streak is 1 (today only), but there was a 5-day streak in the past
        let dates = [
            date(daysAgo: 0),
            date(daysAgo: 10), date(daysAgo: 11), date(daysAgo: 12),
            date(daysAgo: 13), date(daysAgo: 14)
        ]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.longest, 5)
    }

    func testMultipleSessionsSameDayCountAsOne() {
        let dates = [date(daysAgo: 0), date(daysAgo: 0), date(daysAgo: 1)]
        let result = StreakCalculator.calculate(sessionDates: dates)
        XCTAssertEqual(result.current, 2)
    }

    func testEmptySessionDates() {
        let result = StreakCalculator.calculate(sessionDates: [])
        XCTAssertEqual(result.current, 0)
        XCTAssertEqual(result.longest, 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test` — Expected: compile errors (StreakCalculator doesn't exist).

- [ ] **Step 3: Implement StreakCalculator**

```swift
// TheMargin/Services/StreakCalculator.swift
import Foundation

struct StreakResult {
    let current: Int
    let longest: Int
    let atRisk: Bool // true if streak is alive but today hasn't been logged
}

enum StreakCalculator {
    static func calculate(sessionDates: [Date]) -> StreakResult {
        guard !sessionDates.isEmpty else {
            return StreakResult(current: 0, longest: 0, atRisk: false)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Deduplicate to unique calendar days, sorted descending
        let uniqueDays = Set(sessionDates.map { calendar.startOfDay(for: $0) })
            .sorted(by: >)

        // Calculate all streaks
        var streaks: [Int] = []
        var currentRun = 1

        for i in 1..<uniqueDays.count {
            let expected = calendar.date(byAdding: .day, value: -1, to: uniqueDays[i - 1])!
            if calendar.isDate(uniqueDays[i], inSameDayAs: expected) {
                currentRun += 1
            } else {
                streaks.append(currentRun)
                currentRun = 1
            }
        }
        streaks.append(currentRun)

        let longest = streaks.max() ?? 0

        // Current streak: must include today or yesterday
        let mostRecent = uniqueDays[0]
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let includesCurrent = calendar.isDate(mostRecent, inSameDayAs: today)
            || calendar.isDate(mostRecent, inSameDayAs: yesterday)

        let currentStreak = includesCurrent ? streaks[0] : 0
        let atRisk = !calendar.isDate(mostRecent, inSameDayAs: today)
            && calendar.isDate(mostRecent, inSameDayAs: yesterday)

        return StreakResult(
            current: currentStreak,
            longest: longest,
            atRisk: atRisk
        )
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add TheMargin/Services/StreakCalculator.swift TheMarginTests/ServiceTests/StreakCalculatorTests.swift
git commit -m "feat: add streak calculator with current/longest/at-risk logic"
```

---

### Task 5: Services — Insights Calculator

**Files:**
- Create: `TheMargin/Services/InsightsCalculator.swift`
- Create: `TheMarginTests/ServiceTests/InsightsCalculatorTests.swift`

**Context:** Aggregation queries for the Insights tab. See product spec "Pattern Insights" user stories. Computes: average words/session, average duration, best day of week, words-per-week trend, mood distribution, projected completion date, words by day for calendar views.

- [ ] **Step 1: Write failing tests**

```swift
// TheMarginTests/ServiceTests/InsightsCalculatorTests.swift
import XCTest
@testable import TheMargin

final class InsightsCalculatorTests: XCTestCase {
    private let calendar = Calendar.current

    private func makeSession(
        daysAgo: Int,
        wordCount: Int,
        mood: Mood = .steady,
        durationSeconds: Int? = nil
    ) -> Session {
        let project = Project(name: "Test")
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date.now)!
        return Session(
            project: project,
            date: date,
            wordCount: wordCount,
            mood: mood,
            durationSeconds: durationSeconds
        )
    }

    func testAverageWordsPerSession() {
        let sessions = [
            makeSession(daysAgo: 0, wordCount: 500),
            makeSession(daysAgo: 1, wordCount: 1000),
            makeSession(daysAgo: 2, wordCount: 750),
        ]
        let result = InsightsCalculator.averageWordsPerSession(sessions)
        XCTAssertEqual(result, 750)
    }

    func testAverageDurationExcludesUntimedSessions() {
        let sessions = [
            makeSession(daysAgo: 0, wordCount: 500, durationSeconds: 3600),
            makeSession(daysAgo: 1, wordCount: 500, durationSeconds: 1800),
            makeSession(daysAgo: 2, wordCount: 500, durationSeconds: nil),
        ]
        let result = InsightsCalculator.averageDurationSeconds(sessions)
        XCTAssertEqual(result, 2700) // (3600 + 1800) / 2
    }

    func testMoodDistribution() {
        let sessions = [
            makeSession(daysAgo: 0, wordCount: 500, mood: .flow),
            makeSession(daysAgo: 1, wordCount: 500, mood: .flow),
            makeSession(daysAgo: 2, wordCount: 500, mood: .steady),
            makeSession(daysAgo: 3, wordCount: 500, mood: .dry),
        ]
        let dist = InsightsCalculator.moodDistribution(sessions)
        XCTAssertEqual(dist[.flow], 0.5, accuracy: 0.01)
        XCTAssertEqual(dist[.steady], 0.25, accuracy: 0.01)
        XCTAssertEqual(dist[.dry], 0.25, accuracy: 0.01)
    }

    func testProjectedCompletionDate() {
        // 10 sessions over 10 days, avg 500 words/day, 25000 remaining
        let sessions = (0..<10).map { makeSession(daysAgo: $0, wordCount: 500) }
        let project = Project(name: "Novel", wordCountGoal: 30000, startingWordCount: 0)
        project.sessions = sessions
        let projected = InsightsCalculator.projectedCompletionDate(for: project)
        XCTAssertNotNil(projected)
        // 5000 written, 25000 remaining, 500/day pace → ~50 days from now
        let daysUntil = calendar.dateComponents([.day], from: Date.now, to: projected!).day!
        XCTAssertEqual(daysUntil, 50, accuracy: 2)
    }

    func testEmptySessionsReturnZeros() {
        XCTAssertEqual(InsightsCalculator.averageWordsPerSession([]), 0)
        XCTAssertNil(InsightsCalculator.averageDurationSeconds([]))
        XCTAssertTrue(InsightsCalculator.moodDistribution([]).isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement InsightsCalculator**

```swift
// TheMargin/Services/InsightsCalculator.swift
import Foundation

enum InsightsCalculator {
    static func averageWordsPerSession(_ sessions: [Session]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.wordCount } / sessions.count
    }

    static func averageDurationSeconds(_ sessions: [Session]) -> Int? {
        let timed = sessions.compactMap(\.durationSeconds)
        guard !timed.isEmpty else { return nil }
        return timed.reduce(0, +) / timed.count
    }

    static func bestDayOfWeek(_ sessions: [Session]) -> Int? {
        guard !sessions.isEmpty else { return nil }
        let calendar = Calendar.current
        var totals: [Int: Int] = [:] // weekday (1=Sun) → total words
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            totals[weekday, default: 0] += session.wordCount
        }
        return totals.max(by: { $0.value < $1.value })?.key
    }

    static func wordsByDayOfWeek(_ sessions: [Session]) -> [Int: Int] {
        let calendar = Calendar.current
        var totals: [Int: Int] = [:]
        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            totals[weekday, default: 0] += session.wordCount
        }
        return totals
    }

    static func wordsPerWeekTrend(_ sessions: [Session], weeks: Int = 8) -> [(weekStart: Date, words: Int)] {
        let calendar = Calendar.current
        let today = Date.now
        var result: [(weekStart: Date, words: Int)] = []

        for weeksAgo in (0..<weeks).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today)!
            let start = calendar.startOfWeek(for: weekStart)
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            let weekWords = sessions
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.wordCount }
            result.append((weekStart: start, words: weekWords))
        }
        return result
    }

    static func moodDistribution(_ sessions: [Session]) -> [Mood: Double] {
        guard !sessions.isEmpty else { return [:] }
        var counts: [Mood: Int] = [:]
        for session in sessions {
            counts[session.mood, default: 0] += 1
        }
        return counts.mapValues { Double($0) / Double(sessions.count) }
    }

    static func projectedCompletionDate(for project: Project) -> Date? {
        guard let goal = project.wordCountGoal, goal > 0 else { return nil }
        let remaining = goal - project.totalWords
        guard remaining > 0 else { return nil }

        let sessions = project.sessions.sorted(by: { $0.date < $1.date })
        guard sessions.count >= 2 else { return nil }

        let calendar = Calendar.current
        let firstDate = sessions.first!.date
        let lastDate = sessions.last!.date
        // Use an inclusive span so 10 daily sessions across 10 dates yields a 10-day pace.
        let daySpan = max((calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0) + 1, 1)
        let totalWritten = sessions.reduce(0) { $0 + $1.wordCount }
        let wordsPerDay = Double(totalWritten) / Double(daySpan)

        guard wordsPerDay > 0 else { return nil }
        let daysRemaining = Int(ceil(Double(remaining) / wordsPerDay))
        return calendar.date(byAdding: .day, value: daysRemaining, to: Date.now)
    }

    static func wordsByDay(_ sessions: [Session]) -> [Date: Int] {
        let calendar = Calendar.current
        var result: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            result[day, default: 0] += session.wordCount
        }
        return result
    }

    static func thisWeekTotal(_ sessions: [Session]) -> Int {
        let calendar = Calendar.current
        let weekStart = calendar.startOfWeek(for: .now)
        return sessions
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.wordCount }
    }
}

// MARK: - Calendar helper
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Commit**

```bash
git add Services/InsightsCalculator.swift TheMarginTests/ServiceTests/InsightsCalculatorTests.swift
git commit -m "feat: add insights calculator — averages, trends, mood distribution, projections"
```

---

### Task 6: Services — Tip Rotation + CSV Export

**Files:**
- Create: `Services/TipRotationService.swift`
- Create: `Services/CSVExportService.swift`
- Verify/Modify: `Resources/writing-tips.json`
- Create: `TheMarginTests/ServiceTests/TipRotationServiceTests.swift`
- Create: `TheMarginTests/ServiceTests/CSVExportServiceTests.swift`

**Context:** Tips rotate random-without-repeat (cycle through all before reshuffling). The repo already contains `Resources/writing-tips.json`; align the app model/decoder with that checked-in schema or replace the file deliberately in this task. CSV export should produce a file compatible with the user's existing Google Sheets workflow (columns: Date, Project, Word Count, Mood, Chapter, Duration, Notes) and must harden against spreadsheet formula injection.

- [ ] **Step 1: Write failing tests for TipRotationService**

```swift
// TheMarginTests/ServiceTests/TipRotationServiceTests.swift
import XCTest
@testable import TheMargin

final class TipRotationServiceTests: XCTestCase {
    func testReturnsTipFromPool() {
        let tips = (1...10).map { WritingTip(text: "Tip \($0)", category: .craft) }
        let service = TipRotationService(tips: tips)
        let tip = service.tipForToday()
        XCTAssertNotNil(tip)
        XCTAssertTrue(tips.contains(where: { $0.text == tip!.text }))
    }

    func testCyclesThroughAllBeforeRepeating() {
        let tips = (1...5).map { WritingTip(text: "Tip \($0)", category: .craft) }
        let service = TipRotationService(tips: tips)
        var seen: Set<String> = []
        for _ in 0..<5 {
            let tip = service.nextTip()
            XCTAssertFalse(seen.contains(tip!.text), "Saw \(tip!.text) twice before cycling")
            seen.insert(tip!.text)
        }
        XCTAssertEqual(seen.count, 5)
    }

    func testEmptyPoolReturnsNil() {
        let service = TipRotationService(tips: [])
        XCTAssertNil(service.tipForToday())
    }
}
```

- [ ] **Step 2: Write failing tests for CSVExportService**

```swift
// TheMarginTests/ServiceTests/CSVExportServiceTests.swift
import XCTest
@testable import TheMargin

final class CSVExportServiceTests: XCTestCase {
    func testCSVHeaderRow() {
        let csv = CSVExportService.generate(sessions: [])
        XCTAssertTrue(csv.hasPrefix("Date,Project,Word Count,Mood,Chapter,Duration (min),Notes"))
    }

    func testCSVRowFormat() {
        let project = Project(name: "Novel")
        let session = Session(
            project: project,
            date: ISO8601DateFormatter().date(from: "2026-03-15T10:00:00Z")!,
            wordCount: 1200,
            notes: "Good session",
            mood: .flow,
            durationSeconds: 3600,
            chapterTag: "Ch. 5"
        )
        let csv = CSVExportService.generate(sessions: [session])
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3) // header + 1 row + trailing newline
        XCTAssertTrue(lines[1].contains("Novel"))
        XCTAssertTrue(lines[1].contains("1200"))
        XCTAssertTrue(lines[1].contains("Flow"))
        XCTAssertTrue(lines[1].contains("Ch. 5"))
        XCTAssertTrue(lines[1].contains("60")) // 3600 seconds = 60 min
    }

    func testCSVEscapesCommasInNotes() {
        let project = Project(name: "Novel")
        let session = Session(
            project: project,
            wordCount: 500,
            notes: "Wrote about love, loss, and hope",
            mood: .steady
        )
        let csv = CSVExportService.generate(sessions: [session])
        XCTAssertTrue(csv.contains("\"Wrote about love, loss, and hope\""))
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

- [ ] **Step 4: Implement TipRotationService**

```swift
// TheMargin/Services/TipRotationService.swift
import Foundation

class TipRotationService {
    private let tips: [WritingTip]
    private var shuffled: [WritingTip] = []
    private var index: Int = 0

    private static let lastTipDateKey = "lastTipDate"
    private static let lastTipIndexKey = "lastTipIndex"

    init(tips: [WritingTip]) {
        self.tips = tips
        reshuffle()
    }

    func tipForToday() -> WritingTip? {
        guard !tips.isEmpty else { return nil }

        let today = Calendar.current.startOfDay(for: .now)
        let defaults = UserDefaults.standard

        if let lastDate = defaults.object(forKey: Self.lastTipDateKey) as? Date,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            let savedIndex = defaults.integer(forKey: Self.lastTipIndexKey)
            if savedIndex < shuffled.count {
                return shuffled[savedIndex]
            }
        }

        let tip = nextTip()
        defaults.set(today, forKey: Self.lastTipDateKey)
        defaults.set(index - 1, forKey: Self.lastTipIndexKey)
        return tip
    }

    func nextTip() -> WritingTip? {
        guard !tips.isEmpty else { return nil }
        if index >= shuffled.count {
            reshuffle()
        }
        let tip = shuffled[index]
        index += 1
        return tip
    }

    private func reshuffle() {
        shuffled = tips.shuffled()
        index = 0
    }
}
```

- [ ] **Step 5: Implement CSVExportService**

```swift
// TheMargin/Services/CSVExportService.swift
import Foundation

enum CSVExportService {
    static func generate(sessions: [Session]) -> String {
        var csv = "Date,Project,Word Count,Mood,Chapter,Duration (min),Notes\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let sorted = sessions.sorted(by: { $0.date > $1.date })

        for session in sorted {
            let date = dateFormatter.string(from: session.date)
            let project = escapeCSV(session.project?.name ?? "Unknown")
            let words = "\(session.wordCount)"
            let mood = session.mood.displayName
            let chapter = escapeCSV(session.chapterTag ?? "")
            let duration = session.durationSeconds.map { "\($0 / 60)" } ?? ""
            let notes = escapeCSV(session.notes ?? "")

            csv += "\(date),\(project),\(words),\(mood),\(chapter),\(duration),\(notes)\n"
        }
        return csv
    }

    private static func escapeCSV(_ value: String) -> String {
        let guardedValue: String
        if let first = value.first, ["=", "+", "-", "@"].contains(String(first)) {
            guardedValue = "'\(value)"
        } else {
            guardedValue = value
        }

        if guardedValue.contains(",") || guardedValue.contains("\"") || guardedValue.contains("\n") {
            return "\"\(guardedValue.replacing("\"", with: "\"\""))\""
        }
        return guardedValue
    }
}
```

- [ ] **Step 6: Align the bundled writing tips JSON with the checked-in schema**

Keep or update `Resources/writing-tips.json` so it matches a deliberate schema. The checked-in file currently looks like this:

```json
[
  {
    "type": "quote",
    "text": "The first draft is just you telling yourself the story.",
    "author": "Terry Pratchett",
    "source": null,
    "tags": ["process", "first draft"]
  }
]
```

If you replace the file with a simpler schema, do it in this task and update the decoder/tests in lockstep. Do not leave the bundled JSON and `WritingTip` decoder disagreeing.

- [ ] **Step 7: Add tip loading logic to TheMarginApp.swift**

Own the `ModelContainer` in `TheMarginApp`, seed through `container.mainContext`, and save after insertion:

```swift
@main
struct TheMarginApp: App {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(
            for: Project.self, Session.self, WritingTip.self,
            migrationPlan: MarginMigrationPlan.self
        )
        Self.seedTipsIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

static func seedTipsIfNeeded(context: ModelContext) {
    let descriptor = FetchDescriptor<WritingTip>()
    let count = (try? context.fetchCount(descriptor)) ?? 0
    guard count == 0 else { return }

    guard let url = Bundle.main.url(forResource: "writing-tips", withExtension: "json"),
          let data = try? Data(contentsOf: url) else { return }

    struct TipJSON: Decodable {
        let type: String
        let text: String
        let author: String?
        let source: String?
        let tags: [String]
    }

    guard let tips = try? JSONDecoder().decode([TipJSON].self, from: data) else { return }
    for tip in tips {
        let category = TipCategory(rawValue: tip.type == "quote" ? "quote" : "craft") ?? .craft
        let attribution = [tip.author, tip.source].compactMap { $0 }.joined(separator: " — ")
        context.insert(
            WritingTip(
                text: tip.text,
                attribution: attribution.isEmpty ? nil : attribution,
                category: category
            )
        )
    }
    try? context.save()
}
```

This avoids the invalid "seed in `init` without owning the container" setup and keeps bundled data/schema in one place.

- [ ] **Step 8: Run all tests to verify they pass**

- [ ] **Step 9: Commit**

```bash
git add Services/ TheMarginTests/ServiceTests/ Resources/writing-tips.json TheMarginApp.swift
git commit -m "feat: add tip rotation (random-without-repeat) and CSV export services"
```

---

### Task 7: Services — Notifications

**Files:**
- Create: `Services/NotificationService.swift`

**Context:** Daily reminder notification service. Schedule at user-selected time, cancel on toggle off, and expose read helpers so Settings can reflect real authorization + pending reminder state when reopened. Uses `UserNotifications`. No unit tests required if the API surface stays thin and deterministic.

- [ ] **Step 1: Implement NotificationService**

```swift
// Services/NotificationService.swift
import UserNotifications

enum NotificationService {
    struct ReminderState {
        let isAuthorized: Bool
        let isScheduled: Bool
        let hour: Int?
        let minute: Int?
    }

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func scheduleDailyReminder(at hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to write"
        content.body = "Your manuscript is waiting."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)

        try await center.add(request)
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    }

    static func currentReminderState() async -> ReminderState {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
        let reminder = requests.first(where: { $0.identifier == "daily-reminder" })
        let trigger = reminder?.trigger as? UNCalendarNotificationTrigger

        return ReminderState(
            isAuthorized: settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional,
            isScheduled: reminder != nil,
            hour: trigger?.dateComponents.hour,
            minute: trigger?.dateComponents.minute
        )
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Services/NotificationService.swift
git commit -m "feat: add daily reminder notification service"
```

---

### Task 8: Shared Components — Manuscript Stack

**Files:**
- Create: `TheMargin/Components/ManuscriptStackView.swift`

**Context:** The emotional center of the app. See visual spec "The Manuscript Stack" section for geometry, jitter, page count formula, and visual cap (max 40 pages on dashboard, 15 for thumbnails). Sizes: 220px dashboard, 180px detail, 80px compact, 40px thumbnail. Page height: 7px dashboard, 6px detail, 3-4px small. Build animation is implemented separately in Task 14.

- [ ] **Step 1: Implement ManuscriptStackView**

```swift
// TheMargin/Components/ManuscriptStackView.swift
import SwiftUI

struct ManuscriptStackView: View {
    @Environment(\.colorScheme) private var colorScheme
    let totalWords: Int
    let goalWords: Int?
    let size: StackSize

    enum StackSize {
        case dashboard  // 220px wide, 7px pages, max 40
        case detail     // 180px wide, 6px pages, max 40
        case compact    // 80px wide, 4px pages, max 20
        case thumbnail  // 40px wide, 3px pages, max 15

        var width: CGFloat {
            switch self {
            case .dashboard: 220
            case .detail: 180
            case .compact: 80
            case .thumbnail: 40
            }
        }

        var pageHeight: CGFloat {
            switch self {
            case .dashboard: 7
            case .detail: 6
            case .compact: 4
            case .thumbnail: 3
            }
        }

        var maxPages: Int {
            switch self {
            case .dashboard, .detail: 40
            case .compact: 20
            case .thumbnail: 15
            }
        }

        var jitterRange: CGFloat {
            switch self {
            case .dashboard, .detail: 1.5
            case .compact: 0.8
            case .thumbnail: 0.4
            }
        }

        var rotationRange: Double {
            switch self {
            case .dashboard, .detail: 0.2
            case .compact, .thumbnail: 0.1
            }
        }
    }

    private var visualPages: Int {
        let raw = totalWords / 250
        guard raw > 0 || totalWords > 0 else { return 0 }
        return max(min(raw, size.maxPages), totalWords > 0 ? 1 : 0)
    }

    // Stable jitter per page index (seeded, not random per render)
    private func jitterX(for index: Int) -> CGFloat {
        let seed = Double(index * 7 + 3)
        return CGFloat(sin(seed) * Double(size.jitterRange))
    }

    private func jitterRotation(for index: Int) -> Double {
        let seed = Double(index * 13 + 7)
        return sin(seed) * size.rotationRange
    }

    let showGlow: Bool

    init(totalWords: Int, goalWords: Int? = nil, size: StackSize, showGlow: Bool = false) {
        self.totalWords = totalWords
        self.goalWords = goalWords
        self.size = size
        self.showGlow = showGlow
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Amber radial glow (dashboard only, Lamplight only)
            if showGlow && visualPages > 0 {
                if colorScheme == .dark {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xC4956A, opacity: 0.08), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: size.width * 0.8
                            )
                        )
                        .frame(width: size.width * 1.5, height: CGFloat(visualPages) * size.pageHeight * 1.5)
                        .blur(radius: 20)
                }
            }

            // Shadow under the stack
            if visualPages > 0 {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.black.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.6
                        )
                    )
                    .frame(width: size.width * 1.1, height: 12)
                    .offset(y: 6)
            }

            // Pages
            VStack(spacing: 0) {
                ForEach(0..<visualPages, id: \.self) { index in
                    let isTop = index == visualPages - 1
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [MarginTheme.paper, MarginTheme.paperDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: size.width,
                            height: isTop ? size.pageHeight + 1 : size.pageHeight
                        )
                        .shadow(
                            color: .black.opacity(isTop ? 0.12 : 0.05),
                            radius: isTop ? 2 : 0.5,
                            y: isTop ? -1 : -0.5
                        )
                        .offset(x: jitterX(for: index))
                        .rotationEffect(.degrees(jitterRotation(for: index)))
                }
            }
        }
        .frame(width: size.width + 10) // padding for jitter
    }
}

// MARK: - Empty state
extension ManuscriptStackView {
    @ViewBuilder
    static func emptyState(size: StackSize) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 2)
                .fill(MarginTheme.paper)
                .frame(width: size.width, height: size.pageHeight * 3)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            // Dog-ear fold
            Triangle()
                .fill(MarginTheme.paperDark)
                .frame(width: 10, height: 10)
        }
        .frame(width: size.width + 10)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
```

- [ ] **Step 2: Add SwiftUI preview for visual verification**

Add a `#Preview` block showing the stack at all 4 sizes with sample word counts (0, 1000, 20000, 80000).

- [ ] **Step 3: Commit**

```bash
git add Components/ManuscriptStackView.swift
git commit -m "feat: add manuscript stack component with jitter, sizes, and empty state"
```

---

### Task 9: Shared Components — Mood Selector, FAB, Stat Card

**Files:**
- Create: `TheMargin/Components/MoodGlyphView.swift`
- Create: `TheMargin/Components/MoodSelectorView.swift`
- Create: `TheMargin/Components/PenFABView.swift`
- Create: `TheMargin/Components/StatCardView.swift`

**Context:** Mood selector uses 3 ink-drawn SVG icons (dry nib, stone, seedling) and 2 typographic glyphs (∞, ✦) with ink-wash fill animation (400ms). See visual spec "Log Session Fields > Mood Icons" and "Mood Selector". Pen FAB is 56px amber circle with compose pen icon; taps to reveal popup. See visual spec "Pen FAB Behavior". StatCard is a reusable card for the Insights 2x2 grid.

- [ ] **Step 1: Implement MoodGlyphView**

```swift
// TheMargin/Components/MoodGlyphView.swift
import SwiftUI

struct MoodGlyphView: View {
    let mood: Mood
    let isSelected: Bool
    let size: CGFloat
    @Environment(\.marginTheme) private var theme

    var body: some View {
        ZStack {
            // Ink-wash fill: radial gradient expanding from center
            Circle()
                .fill(mood.color)
                .scaleEffect(isSelected ? 1.0 : 0.3)
                .opacity(isSelected ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4), value: isSelected)

            Circle()
                .stroke(mood.color.opacity(0.6), lineWidth: 1.5)
                .opacity(isSelected ? 0 : 1)

            // SVG-based moods use custom Shape paths; typographic moods use Text
            if mood.usesSVGIcon {
                MoodIconShape(mood: mood)
                    .stroke(
                        isSelected ? MarginTheme.paper : theme.text,
                        style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.5, height: size * 0.5)
            } else {
                Text(mood.glyph)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(isSelected ? MarginTheme.paper : theme.text)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Custom Shape that draws ink-style SVG icons for dry (nib), grinding (stone), steady (seedling).
/// Paths are normalized to a 24×24 viewBox and scaled by the frame.
struct MoodIconShape: Shape {
    let mood: Mood

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24.0
        var p = Path()
        switch mood {
        case .dry:
            // Wide pen nib with slit and breather hole
            p.move(to: CGPoint(x: 12*s, y: 20*s))
            p.addCurve(to: CGPoint(x: 7.5*s, y: 12.5*s),
                       control1: CGPoint(x: 9.5*s, y: 17*s),
                       control2: CGPoint(x: 8*s, y: 15*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 4*s),
                       control1: CGPoint(x: 8*s, y: 10*s),
                       control2: CGPoint(x: 10*s, y: 7*s))
            p.addCurve(to: CGPoint(x: 16.5*s, y: 12.5*s),
                       control1: CGPoint(x: 14*s, y: 7*s),
                       control2: CGPoint(x: 16*s, y: 10*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 20*s),
                       control1: CGPoint(x: 16*s, y: 15*s),
                       control2: CGPoint(x: 14.5*s, y: 17*s))
            // Slit
            p.move(to: CGPoint(x: 12*s, y: 20*s))
            p.addLine(to: CGPoint(x: 12*s, y: 14.5*s))
            // Breather hole
            p.addEllipse(in: CGRect(x: 10.8*s, y: 11.3*s, width: 2.4*s, height: 2.4*s))
        case .grinding:
            // Rounded stone
            p.move(to: CGPoint(x: 5*s, y: 16*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 19*s),
                       control1: CGPoint(x: 6*s, y: 19*s),
                       control2: CGPoint(x: 8*s, y: 19*s))
            p.addCurve(to: CGPoint(x: 19*s, y: 16*s),
                       control1: CGPoint(x: 16*s, y: 19*s),
                       control2: CGPoint(x: 18*s, y: 19*s))
            p.addCurve(to: CGPoint(x: 18*s, y: 9*s),
                       control1: CGPoint(x: 20*s, y: 12*s),
                       control2: CGPoint(x: 20*s, y: 10*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 5*s),
                       control1: CGPoint(x: 16*s, y: 7*s),
                       control2: CGPoint(x: 14*s, y: 5*s))
            p.addCurve(to: CGPoint(x: 6*s, y: 9*s),
                       control1: CGPoint(x: 10*s, y: 5*s),
                       control2: CGPoint(x: 8*s, y: 7*s))
            p.addCurve(to: CGPoint(x: 5*s, y: 16*s),
                       control1: CGPoint(x: 4*s, y: 10*s),
                       control2: CGPoint(x: 4*s, y: 12*s))
        case .steady:
            // Seedling with two leaves
            p.move(to: CGPoint(x: 12*s, y: 19*s))
            p.addLine(to: CGPoint(x: 12*s, y: 11*s))
            // Left leaf
            p.move(to: CGPoint(x: 12*s, y: 14*s))
            p.addCurve(to: CGPoint(x: 8*s, y: 7*s),
                       control1: CGPoint(x: 9*s, y: 13*s),
                       control2: CGPoint(x: 7*s, y: 10*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 14*s),
                       control1: CGPoint(x: 11*s, y: 7*s),
                       control2: CGPoint(x: 12*s, y: 11*s))
            // Right leaf
            p.move(to: CGPoint(x: 12*s, y: 11*s))
            p.addCurve(to: CGPoint(x: 16*s, y: 4*s),
                       control1: CGPoint(x: 15*s, y: 10*s),
                       control2: CGPoint(x: 17*s, y: 7*s))
            p.addCurve(to: CGPoint(x: 12*s, y: 11*s),
                       control1: CGPoint(x: 13*s, y: 4*s),
                       control2: CGPoint(x: 12*s, y: 8*s))
        default:
            break // Flow and Breakthrough use Text, not Shape
        }
        return p
    }
}
```

- [ ] **Step 2: Implement MoodSelectorView with ink-wash animation**

```swift
// TheMargin/Components/MoodSelectorView.swift
import SwiftUI

struct MoodSelectorView: View {
    @Binding var selected: Mood?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Mood.allCases, id: \.self) { mood in
                Button {
                    withAnimation(.easeOut(duration: 0.4)) {
                        selected = mood
                    }
                } label: {
                    MoodGlyphView(
                        mood: mood,
                        isSelected: selected == mood,
                        size: 36
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.displayName)
                .sensoryFeedback(
                    selected == mood ? .impact(weight: .medium) : .impact(weight: .light),
                    trigger: selected
                )
            }
        }
    }
}
```

- [ ] **Step 3: Implement PenFABView**

```swift
// TheMargin/Components/PenFABView.swift
import SwiftUI

struct PenFABView: View {
    @State private var isExpanded = false
    let onStartSession: () -> Void
    let onLogSession: () -> Void

    @Environment(\.marginTheme) private var theme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Dimming overlay
            if isExpanded {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(duration: 0.3)) { isExpanded = false } }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Dismiss menu")
            }

            VStack(spacing: 12) {
                if isExpanded {
                    // Start Session option
                    Button("Start Timed Session", systemImage: "timer") {
                        withAnimation(.spring(duration: 0.3)) { isExpanded = false }
                        onStartSession()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(theme.amber))
                    .foregroundStyle(Color(hex: 0x1A1A18))
                    .transition(.scale.combined(with: .opacity))

                    // Log Session option
                    Button("Log Session", systemImage: "pencil.line") {
                        withAnimation(.spring(duration: 0.3)) { isExpanded = false }
                        onLogSession()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(theme.surface))
                    .foregroundStyle(theme.text)
                    .transition(.scale.combined(with: .opacity))
                }

                // Main FAB
                Button(isExpanded ? "Close Menu" : "New Session", systemImage: isExpanded ? "xmark" : "pencil.line") {
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: 0x1A1A18))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(theme.amber)
                        .shadow(color: theme.amber.opacity(0.35), radius: 10, y: 4)
                )
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.spring(duration: 0.3), value: isExpanded)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
}
```

- [ ] **Step 4: Implement StatCardView**

```swift
// TheMargin/Components/StatCardView.swift
import SwiftUI

struct StatCardView: View {
    let label: String
    let value: String
    let isHighlighted: Bool

    @Environment(\.marginTheme) private var theme

    init(label: String, value: String, isHighlighted: Bool = false) {
        self.label = label
        self.value = value
        self.isHighlighted = isHighlighted
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.display(22))
                .foregroundStyle(isHighlighted ? theme.amber : theme.text)
            Text(label.uppercased())
                .font(.literata(9, weight: .medium))
                .foregroundStyle(theme.textDim)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

- [ ] **Step 5: Add previews for all components**

- [ ] **Step 6: Commit**

```bash
git add Components/
git commit -m "feat: add mood selector, pen FAB, and stat card components"
```

---

### Task 10: Dashboard View

**Files:**
- Create: `Views/Dashboard/DashboardView.swift`
- Modify: `ContentView.swift` — wire DashboardView into Home tab

**Context:** See visual spec "Dashboard (Home Tab)" for exact layout. Project selector in nav bar (left), gear icon (right). Stack centered. Stats below. Streak row. The interactive manuscript stack replaces the old flat recent-sessions list: pass the top 5 recent sessions into `ManuscriptStackView`, surface the "Hold to peek" hint here, and wire a tap callback for fanned pages so Task 16 only adds animation/choreography rather than restructuring the dashboard later. The daily tip does NOT appear on the dashboard — it's exclusive to the timer screen per the visual spec nav bar note.

- [ ] **Step 1: Implement DashboardView**

```swift
// TheMargin/Views/Dashboard/DashboardView.swift
import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.marginTheme) private var theme
    @Query(filter: #Predicate<Project> { !$0.isArchived },
           sort: \Project.createdAt)
    private var projects: [Project]
    @Query(sort: \Session.date, order: .reverse)
    private var allSessions: [Session]

    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @State private var showProjectPicker = false
    @State private var showTimerScreen = false
    @State private var showLogSession = false
    @State private var showSettings = false
    @State private var selectedSessionForEdit: Session?

    private var currentProject: Project? {
        projects.first(where: { $0.id.uuidString == lastUsedProjectID }) ?? projects.first
    }

    private var recentSessions: [Session] {
        Array(allSessions.prefix(5))
    }

    private var streak: StreakResult {
        StreakCalculator.calculate(sessionDates: allSessions.map(\.date))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Manuscript Stack
                        if let project = currentProject {
                            ManuscriptStackView(
                                totalWords: project.totalWords,
                                goalWords: project.wordCountGoal,
                                size: .dashboard,
                                recentSessions: recentSessions,
                                onSessionTap: { session in
                                    selectedSessionForEdit = session
                                }
                            )
                            .padding(.top, 16)

                            Text("Hold to peek")
                                .font(.literata(10, weight: .medium))
                                .foregroundStyle(theme.textFaint)
                                .tracking(1.5)

                            // Stats
                            HStack(spacing: 32) {
                                VStack(spacing: 2) {
                                    Text("\(project.totalWords)")
                                        .font(.display(28))
                                        .foregroundStyle(theme.text)
                                    Text("TOTAL")
                                        .font(.literata(10, weight: .medium))
                                        .foregroundStyle(theme.textDim)
                                        .tracking(1.5)
                                }
                                VStack(spacing: 2) {
                                    Text("\(project.wordsToday)")
                                        .font(.display(28))
                                        .foregroundStyle(theme.text)
                                    Text("TODAY")
                                        .font(.literata(10, weight: .medium))
                                        .foregroundStyle(theme.textDim)
                                        .tracking(1.5)
                                }
                            }

                            // Progress bar (if goal set)
                            if let progress = project.goalProgress {
                                VStack(spacing: 4) {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.surfaceRaised)
                                            .frame(width: 220, height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.amber)
                                            .frame(width: 220 * progress, height: 4)
                                    }

                                    Text("\(Int(progress * 100))%")
                                        .font(.mono(11))
                                        .foregroundStyle(theme.textDim)
                                }
                            }
                        } else {
                            ManuscriptStackView.emptyState(size: .dashboard)
                                .padding(.top, 16)
                            Text("Create a project to get started")
                                .font(.literata(14))
                                .foregroundStyle(theme.textDim)
                        }

                        // Streak
                        HStack {
                            HStack(spacing: 4) {
                                Text("\(streak.current)")
                                    .font(.display(22))
                                    .foregroundStyle(theme.amber)
                                Text("day streak")
                                    .font(.literata(12))
                                    .foregroundStyle(theme.textDim)
                            }
                            Spacer()
                            Text("best: \(streak.longest)")
                                .font(.literata(12))
                                .italic()
                                .foregroundStyle(theme.textFaint)
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 80) // space for FAB
                    }
                }

                // Pen FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PenFABView(
                            onStartSession: { showTimerScreen = true },
                            onLogSession: { showLogSession = true }
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showProjectPicker = true
                    } label: {
                        Text(currentProject?.name.uppercased() ?? "NO PROJECT")
                            .font(.typewriter(13))
                            .foregroundStyle(theme.text)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(theme.textDim)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.textDim)
                    }
                }
            }
            .confirmationDialog("Select Project", isPresented: $showProjectPicker) {
                ForEach(projects) { project in
                    Button(project.name) {
                        lastUsedProjectID = project.id.uuidString
                    }
                }
            }
            .fullScreenCover(isPresented: $showTimerScreen) {
                Text("Timer — Task 12") // placeholder
            }
            .sheet(isPresented: $showLogSession) {
                Text("Log Session — Task 11") // placeholder
            }
            .sheet(isPresented: $showSettings) {
                Text("Settings — Task 15") // placeholder
            }
            .sheet(item: $selectedSessionForEdit) { session in
                LogSessionView(editingSession: session)
            }
        }
    }
}
```

- [ ] **Step 2: Wire DashboardView into ContentView**

Replace the `Text("Dashboard")` placeholder in ContentView's Home tab with `DashboardView()`.

- [ ] **Step 3: Build and run — verify dashboard renders with empty state**

- [ ] **Step 4: Commit**

```bash
git add Views/Dashboard/ ContentView.swift
git commit -m "feat: add dashboard view with manuscript fan, streak, and FAB"
```

---

### Task 11: Log Session Flow

**Files:**
- Create: `Views/LogSession/LogSessionViewModel.swift`
- Create: `Views/LogSession/LogSessionView.swift`
- Create: `TheMarginTests/ViewModelTests/LogSessionViewModelTests.swift`

**Context:** The core interaction — must be loggable in under 15 seconds. The form IS a sheet of ruled paper. See visual spec "Log Session Fields" for exact layout. Project defaults to last-used. Word count is the hero field (Special Elite 42px). Mood selector uses ink-wash glyphs. Save creates or updates a `Session` in SwiftData, must call `try context.save()`, and must surface a user-visible error instead of dismissing optimistically.

- [ ] **Step 1: Write failing tests for LogSessionViewModel**

```swift
// TheMarginTests/ViewModelTests/LogSessionViewModelTests.swift
import XCTest
@testable import TheMargin

final class LogSessionViewModelTests: XCTestCase {
    func testCanSaveRequiresWordCountAndMood() {
        let vm = LogSessionViewModel()
        XCTAssertFalse(vm.canSave)

        vm.wordCountText = "500"
        XCTAssertFalse(vm.canSave)

        vm.selectedMood = .steady
        XCTAssertTrue(vm.canSave)
    }

    func testWordCountParsing() {
        let vm = LogSessionViewModel()
        vm.wordCountText = "1,200"
        XCTAssertEqual(vm.parsedWordCount, 1200)

        vm.wordCountText = "abc"
        XCTAssertNil(vm.parsedWordCount)
    }

    func testCanSaveRequiresPositiveWordCount() {
        let vm = LogSessionViewModel()
        vm.wordCountText = "0"
        vm.selectedMood = .steady
        XCTAssertFalse(vm.canSave)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Add RED cases for:
- save failure propagation (`save(...)` throws instead of returning `false`)
- edit/update of an existing `Session`
- stale `lastUsedProjectID` fallback to the first available active project

- [ ] **Step 3: Implement LogSessionViewModel**

```swift
// Views/LogSession/LogSessionViewModel.swift
import SwiftUI
import SwiftData

enum LogSessionValidationError: LocalizedError {
    case invalidInput

    var errorDescription: String? {
        "Enter a positive word count and select a mood before saving."
    }
}

@MainActor @Observable
class LogSessionViewModel {
    var wordCountText: String = ""
    var selectedMood: Mood?
    var notes: String = ""
    var chapterTag: String = ""
    var prefilledDurationSeconds: Int?

    var parsedWordCount: Int? {
        let cleaned = wordCountText.replacing(",", with: "")
        return Int(cleaned)
    }

    var canSave: Bool {
        guard let wc = parsedWordCount, wc > 0, selectedMood != nil else { return false }
        return true
    }

    func save(project: Project, editing session: Session? = nil, context: ModelContext) throws {
        guard let wordCount = parsedWordCount, let mood = selectedMood, wordCount > 0 else {
            throw LogSessionValidationError.invalidInput
        }

        let target = session ?? Session(
            project: project,
            wordCount: wordCount,
            notes: notes.isEmpty ? nil : notes,
            mood: mood,
            durationSeconds: prefilledDurationSeconds,
            chapterTag: chapterTag.isEmpty ? nil : chapterTag
        )

        target.project = project
        target.wordCount = wordCount
        target.notes = notes.isEmpty ? nil : notes
        target.mood = mood
        target.durationSeconds = prefilledDurationSeconds
        target.chapterTag = chapterTag.isEmpty ? nil : chapterTag

        if session == nil {
            context.insert(target)
        }

        try context.save()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Implement LogSessionView**

```swift
// Views/LogSession/LogSessionView.swift
import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var wordCountSize: Double = 42
    @Query(filter: #Predicate<Project> { !$0.isArchived })
    private var projects: [Project]

    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @State private var vm = LogSessionViewModel()
    @State private var selectedProjectID: String = ""
    @State private var saveErrorMessage: String?
    @State private var showSaveError = false
    @FocusState private var wordCountFocused: Bool

    var editingSession: Session? = nil
    var prefilledDuration: Int?

    private var selectedProject: Project? {
        projects.first(where: { $0.id.uuidString == selectedProjectID })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Project stamp
                    HStack {
                        Menu {
                            ForEach(projects) { project in
                                Button(project.name) {
                                    selectedProjectID = project.id.uuidString
                                }
                            }
                        } label: {
                            Text(selectedProject?.name.uppercased() ?? "SELECT PROJECT")
                                .font(.typewriter(13))
                                .foregroundStyle(MarginTheme.inkLight)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(MarginTheme.inkLight.opacity(0.3), lineWidth: 1)
                                )
                                .rotationEffect(.degrees(-1))
                        }

                        Spacer()

                        // Duration pill (if from timer)
                        if let duration = vm.prefilledDurationSeconds {
                            Text(formatDuration(duration))
                                .font(.mono(11))
                                .foregroundStyle(MarginTheme.inkLight)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(MarginTheme.paperDark.opacity(0.5))
                                .clipShape(.capsule)
                        }
                    }
                    .padding(.horizontal, 48) // past the red margin line
                    .padding(.top, 20)

                    // Word count (hero field)
                    TextField("0", text: $vm.wordCountText)
                        .font(.typewriter(wordCountSize))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($wordCountFocused)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 48)

                    Text("WORDS")
                        .font(.literata(10, weight: .medium))
                        .foregroundStyle(MarginTheme.inkLight)
                        .tracking(2)
                        .frame(maxWidth: .infinity)

                    // Chapter tag
                    TextField("Chapter or section (optional)", text: $vm.chapterTag)
                        .font(.typewriter(14))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .padding(.horizontal, 48)
                        .padding(.top, 20)

                    // Mood selector
                    MoodSelectorView(selected: $vm.selectedMood)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)

                    // Notes
                    TextField("Notes...", text: $vm.notes, axis: .vertical)
                        .font(.typewriter(13))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .lineSpacing(15) // match ruled lines (28px line height)
                        .lineLimit(3...8)
                        .padding(.horizontal, 48)
                        .padding(.bottom, 24)

                    // Save button
                    Button {
                        if let project = selectedProject {
                            do {
                                try vm.save(project: project, editing: editingSession, context: modelContext)
                                lastUsedProjectID = project.id.uuidString
                                dismiss()
                            } catch {
                                saveErrorMessage = error.localizedDescription
                                showSaveError = true
                            }
                        }
                    } label: {
                        Text(editingSession == nil ? "SAVE" : "UPDATE")
                            .font(.typewriter(14))
                            .foregroundStyle(MarginTheme.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MarginTheme.inkBlack)
                            .clipShape(.rect(cornerRadius: 6))
                    }
                    .disabled(!vm.canSave || selectedProject == nil)
                    .opacity(vm.canSave && selectedProject != nil ? 1.0 : 0.4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .paperSurface()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MarginTheme.inkLight)
                }
            }
        }
        .onAppear {
            if let editingSession {
                selectedProjectID = editingSession.project?.id.uuidString ?? ""
                vm.wordCountText = String(editingSession.wordCount)
                vm.selectedMood = editingSession.mood
                vm.notes = editingSession.notes ?? ""
                vm.chapterTag = editingSession.chapterTag ?? ""
                vm.prefilledDurationSeconds = editingSession.durationSeconds
            } else {
                selectedProjectID = projects.contains(where: { $0.id.uuidString == lastUsedProjectID })
                    ? lastUsedProjectID
                    : (projects.first?.id.uuidString ?? "")
                vm.prefilledDurationSeconds = prefilledDuration
            }
            wordCountFocused = true
        }
        .alert("Couldn’t Save Session", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Unknown save error")
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }
}
```

- [ ] **Step 6: Wire LogSessionView into DashboardView**

Replace the `Text("Log Session — Task 11")` placeholder in `DashboardView`:

```swift
.sheet(isPresented: $showLogSession) {
    LogSessionView()
}
```

- [ ] **Step 7: Build and run — verify log session form opens and saves**

Create a test project first (manually via debug or a temporary button). Log a session, force a save failure once, and verify:
- successful save updates the dashboard stack/fan state
- failed save keeps the sheet open and shows an error
- editing an existing session updates the page in place

- [ ] **Step 8: Commit**

```bash
git add Views/LogSession/ TheMarginTests/ViewModelTests/LogSessionViewModelTests.swift Views/Dashboard/DashboardView.swift
git commit -m "feat: add log session form with durable save and edit flow"
```

---

### Task 12: Timer Screen

**Files:**
- Create: `Views/Timer/TimerViewModel.swift`
- Create: `Views/Timer/TimerView.swift`
- Create: `TheMarginTests/ViewModelTests/TimerViewModelTests.swift`

**Context:** Active writing companion. See visual spec "Timer Screen" for layout — timer digits (JetBrains Mono 56px), play/pause/stop controls, typewriter carriage mechanism with paper feed. Tip types letter-by-letter in Special Elite on the paper feed. States: Running → Paused → Running → Stopped → LogSessionView (duration pre-filled). The full carriage mechanism (platen, rails, slider) is complex — implement the typing animation and basic carriage structure first, refine visually later.

- [ ] **Step 1: Write failing tests for TimerViewModel**

```swift
// TheMarginTests/ViewModelTests/TimerViewModelTests.swift
import XCTest
@testable import TheMargin

final class TimerViewModelTests: XCTestCase {
    func testInitialStateIsReady() {
        let vm = TimerViewModel()
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.elapsedSeconds, 0)
    }

    func testStartTransitionsToRunning() {
        let vm = TimerViewModel()
        vm.start()
        XCTAssertEqual(vm.state, .running)
    }

    func testPauseTransitionsToPaused() {
        let vm = TimerViewModel()
        vm.start()
        vm.pause()
        XCTAssertEqual(vm.state, .paused)
    }

    func testResumeTransitionsToRunning() {
        let vm = TimerViewModel()
        vm.start()
        vm.pause()
        vm.resume()
        XCTAssertEqual(vm.state, .running)
    }

    func testStopTransitionsToStopped() {
        let vm = TimerViewModel()
        vm.start()
        vm.stop()
        XCTAssertEqual(vm.state, .stopped)
    }

    func testFormattedTimeDisplay() {
        let vm = TimerViewModel()
        vm.elapsedSeconds = 3661 // 1:01:01
        XCTAssertEqual(vm.formattedTime, "1:01:01")

        vm.elapsedSeconds = 125 // 2:05
        XCTAssertEqual(vm.formattedTime, "2:05")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement TimerViewModel**

```swift
// TheMargin/Views/Timer/TimerViewModel.swift
import Foundation
import SwiftUI

@MainActor @Observable
class TimerViewModel {
    enum State: Equatable {
        case ready, running, paused, stopped
    }

    var state: State = .ready
    var elapsedSeconds: Int = 0
    var typedText: String = ""
    var carriagePosition: Double = 0  // 0.0 to 1.0 — tracks typing position for carriage slider
    var cursorVisible: Bool = true

    private var timerTask: Task<Void, Never>?
    private var typewriterTask: Task<Void, Never>?
    private var cursorTask: Task<Void, Never>?
    private var fullTipText: String = ""
    private var tipCharIndex: Int = 0
    private let charsPerLine = 35  // approximate chars before carriage return

    var formattedTime: String {
        let duration = Duration.seconds(elapsedSeconds)
        if elapsedSeconds >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 1)))
        }
        return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }

    func start() {
        state = .running
        startTimers()
    }

    func pause() {
        state = .paused
        timerTask?.cancel()
        typewriterTask?.cancel()
    }

    func resume() {
        state = .running
        startTimers()
    }

    func stop() {
        state = .stopped
        timerTask?.cancel()
        typewriterTask?.cancel()
        cursorTask?.cancel()
    }

    func loadTip(_ tip: WritingTip?) {
        guard let tip else { return }
        fullTipText = tip.text
        if let attr = tip.attribution {
            fullTipText += "\n— \(attr)"
        }
        tipCharIndex = 0
        typedText = ""
        carriagePosition = 0

        // Cursor blinks twice before first character
        cursorVisible = true
        cursorTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                cursorVisible.toggle()
            }
        }
    }

    private func startTimers() {
        // Elapsed timer — ticks every second
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard state == .running else { continue }
                elapsedSeconds += 1
            }
        }

        // Typewriter — ~3 chars/sec (330ms per char)
        // Delay start by 1.6s so cursor blinks twice first
        guard tipCharIndex < fullTipText.count else { return }
        typewriterTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            await beginTyping()
        }
    }

    private func beginTyping() async {
        while !Task.isCancelled, tipCharIndex < fullTipText.count {
            try? await Task.sleep(for: .milliseconds(330))
            guard state == .running else { continue }

            let index = fullTipText.index(
                fullTipText.startIndex,
                offsetBy: tipCharIndex
            )
            let char = fullTipText[index]
            typedText += String(char)
            tipCharIndex += 1

            // Track carriage position
            let posInLine = tipCharIndex % charsPerLine
            if posInLine == 0 && tipCharIndex > 0 {
                // Carriage return: snap to 0, brief pause
                withAnimation(.easeOut(duration: 0.15)) {
                    carriagePosition = 0
                }
            } else {
                carriagePosition = Double(posInLine) / Double(charsPerLine)
            }
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Implement TimerView**

```swift
// TheMargin/Views/Timer/TimerView.swift
import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.marginTheme) private var theme
    @Query private var tips: [WritingTip]
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: Double = 56

    @State private var vm = TimerViewModel()
    @State private var tipService: TipRotationService?
    @State private var showLogSession = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Timer display
                    VStack(spacing: 4) {
                        Text(vm.state == .paused ? "PAUSED" : "WRITING")
                            .font(.literata(10, weight: .medium))
                            .foregroundStyle(theme.textFaint)
                            .tracking(2)

                        Text(vm.formattedTime)
                            .font(.mono(timerFontSize))
                            .foregroundStyle(theme.text)
                            .monospacedDigit()
                    }

                    // Controls
                    HStack(spacing: 24) {
                        switch vm.state {
                        case .ready:
                            TimerButton(label: "Start", icon: "play.fill", tint: theme.amber, action: vm.start)
                        case .running:
                            TimerButton(label: "Pause", icon: "pause.fill", tint: theme.amber, action: vm.pause)
                            TimerButton(label: "Stop", icon: "stop.fill", tint: Color(hex: 0x7A5C50), action: vm.stop)
                        case .paused:
                            TimerButton(label: "Resume", icon: "play.fill", tint: theme.amber, action: vm.resume)
                            TimerButton(label: "Stop", icon: "stop.fill", tint: Color(hex: 0x7A5C50), action: vm.stop)
                        case .stopped:
                            EmptyView()
                        }
                    }

                    // Typewriter carriage mechanism + paper feed
                    if !vm.typedText.isEmpty || vm.state == .running {
                        VStack(spacing: 0) {
                            // Carriage rail with slider
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // Rail
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: 0x4A4540), Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                                                startPoint: .top, endPoint: .bottom
                                            )
                                        )
                                        .frame(height: 3)

                                    // Carriage slider — tracks typing position
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: 0x8A8070), Color(hex: 0x6A6055), Color(hex: 0x4A4540)],
                                                startPoint: .top, endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 20, height: 15)
                                        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                                        .overlay(alignment: .bottom) {
                                            // Amber print-guide dot
                                            Circle()
                                                .fill(theme.amber)
                                                .frame(width: 3, height: 3)
                                                .shadow(color: theme.amber.opacity(0.4), radius: 2)
                                                .offset(y: 3)
                                        }
                                        .offset(x: vm.carriagePosition * (geo.size.width - 20))
                                        .animation(.linear(duration: 0.1), value: vm.carriagePosition)
                                }
                                .frame(height: 15)
                            }
                            .frame(height: 15)
                            .padding(.horizontal, 16)

                            // Platen / roller
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: 0x1A1714), Color(hex: 0x2E2822),
                                            Color(hex: 0x3A342C), Color(hex: 0x2E2822),
                                            Color(hex: 0x1A1714)
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(height: 24)
                                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                                .overlay {
                                    // Platen knobs
                                    HStack {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                                                    center: UnitPoint(x: 0.4, y: 0.35),
                                                    startRadius: 0, endRadius: 8
                                                )
                                            )
                                            .frame(width: 14, height: 14)
                                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                                            .offset(x: -3)
                                        Spacer()
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [Color(hex: 0x8A8070), Color(hex: 0x4A4540)],
                                                    center: UnitPoint(x: 0.4, y: 0.35),
                                                    startRadius: 0, endRadius: 8
                                                )
                                            )
                                            .frame(width: 14, height: 14)
                                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                                            .offset(x: 3)
                                    }
                                }
                                .padding(.top, 5)

                            // Paper feed emerging from platen
                            VStack(alignment: .leading) {
                                TypewriterText(text: vm.typedText, fontSize: 14)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 120)
                            .paperSurface(ruledLines: true, redMargin: true)
                            .offset(y: -5) // Tuck paper under platen
                        }
                        .padding(.horizontal, 12)
                        .transition(.opacity)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.textDim)
                }
            }
        }
        .onAppear {
            let service = TipRotationService(tips: tips)
            tipService = service
            vm.loadTip(service.nextTip())
            vm.start()
        }
        .onChange(of: vm.state) { _, newState in
            if newState == .stopped {
                showLogSession = true
            }
        }
        .sheet(isPresented: $showLogSession, onDismiss: { dismiss() }) {
            LogSessionView(prefilledDuration: vm.elapsedSeconds)
        }
    }

}

/// Extracted view for timer control buttons — each file should contain one type.
/// In the actual project, place this in its own file: Components/TimerButton.swift
struct TimerButton: View {
    let label: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(label, systemImage: icon, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 20))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .stroke(tint.opacity(0.5), lineWidth: 1.5)
            )
    }
}
```

- [ ] **Step 6: Wire TimerView into DashboardView**

Replace the timer placeholder in `DashboardView`:

```swift
.fullScreenCover(isPresented: $showTimerScreen) {
    TimerView()
}
```

- [ ] **Step 7: Build and run — verify timer starts, pauses, stops, and transitions to log form**

- [ ] **Step 8: Commit**

```bash
git add Views/Timer/ TheMarginTests/ViewModelTests/TimerViewModelTests.swift Views/Dashboard/DashboardView.swift
git commit -m "feat: add timer screen with typewriter tip animation and play/pause/stop"
```

---

### Task 13: Projects Tab + Detail + New/Edit

**Files:**
- Create: `Views/Projects/ProjectsListView.swift`
- Create: `Views/Projects/ProjectCardView.swift`
- Create: `Views/Projects/ProjectDetailView.swift`
- Create: `Views/Projects/SessionPageView.swift`
- Create: `Views/Projects/NewProjectView.swift`
- Modify: `ContentView.swift` — wire ProjectsListView into Projects tab

**Context:** See visual spec "Projects Tab" and "Project Detail". Project cards have mini stack thumbnails. Project detail has compact stack + stats + session history as overlapping paper pages. New/edit uses paper surface. Session pages: cream paper, ruled lines, red margin, dog-ear fold, overlapping with negative margins. Deletion must use a standard swipe action plus confirmation and explicit save, not an immediate drag gesture.

- [ ] **Step 1: Implement ProjectCardView**

```swift
// TheMargin/Views/Projects/ProjectCardView.swift
import SwiftUI

struct ProjectCardView: View {
    let project: Project
    let isCurrent: Bool

    @Environment(\.marginTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            // Mini stack thumbnail
            ManuscriptStackView(
                totalWords: project.totalWords,
                goalWords: project.wordCountGoal,
                size: .thumbnail
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.display(16))
                        .foregroundStyle(theme.text)
                    if isCurrent {
                        Text("Current")
                            .font(.literata(9, weight: .medium))
                            .foregroundStyle(theme.amber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.amberDim)
                            .clipShape(.capsule)
                    }
                }
                Text("\(project.totalWords) words")
                    .font(.mono(11))
                    .foregroundStyle(theme.textDim)
                if let goal = project.wordCountGoal {
                    ProgressView(value: project.goalProgress ?? 0)
                        .tint(theme.amber)
                    Text("Goal: \(goal)")
                        .font(.literata(10))
                        .foregroundStyle(theme.textFaint)
                }
                if let lastSession = project.sessions.sorted(by: { $0.date > $1.date }).first {
                    Text("Last session: \(lastSession.date, style: .date)")
                        .font(.literata(10))
                        .italic()
                        .foregroundStyle(theme.textFaint)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(theme.textFaint)
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Implement SessionPageView**

```swift
// Views/Projects/SessionPageView.swift
import SwiftUI

struct SessionPageView: View {
    let session: Session
    let sessionNumber: Int
    let isToday: Bool
    let onRequestDelete: () -> Void

    @State private var isLifted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.date, format: .dateTime.month(.abbreviated).day())
                    .font(.typewriter(11))
                    .foregroundStyle(MarginTheme.inkLight)
                    .textCase(.uppercase)
                Spacer()
                Text(session.mood.glyph)
                    .foregroundStyle(session.mood.color)
            }

            // Word count with TypewriterText ink variation
            TypewriterText(text: "\(session.wordCount)", fontSize: 28)

            HStack {
                if let tag = session.chapterTag {
                    Text(tag)
                        .font(.typewriter(11))
                        .foregroundStyle(MarginTheme.inkLight)
                }
                if let duration = session.durationSeconds {
                    Text("\(duration / 60) min")
                        .font(.mono(10))
                        .foregroundStyle(MarginTheme.inkLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MarginTheme.paperDark.opacity(0.5))
                        .clipShape(.capsule)
                }
            }

            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.literata(12))
                    .italic()
                    .foregroundStyle(MarginTheme.inkMedium)
                    .lineLimit(2)
            }

            HStack {
                Spacer()
                Text("#\(sessionNumber)")
                    .font(.literata(10))
                    .foregroundStyle(MarginTheme.inkLight.opacity(0.5))
            }
        }
        .padding(16)
        .padding(.leading, 28) // red margin offset
        .paperSurface()
        // Dog-ear fold in top-right corner
        .overlay(alignment: .topTrailing) {
            Triangle()
                .fill(MarginTheme.paperDark)
                .frame(width: 22, height: 22)
        }
        // Today's amber left-edge glow
        .overlay(alignment: .leading) {
            if isToday {
                Rectangle()
                    .fill(Color(hex: 0xC4956A).opacity(0.3))
                    .frame(width: 3)
            }
        }
        // Long-press lift gesture — page lifts and straightens
        .offset(y: isLifted ? -6 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLifted)
        .onLongPressGesture(minimumDuration: 0.3) {
            // Long press completed — could open edit sheet
        } onPressingChanged: { pressing in
            isLifted = pressing
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onRequestDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
```

- [ ] **Step 3: Implement NewProjectView**

```swift
// Views/Projects/NewProjectView.swift
import SwiftUI
import SwiftData

struct NewProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingProject: Project?

    @State private var name: String = ""
    @State private var goalText: String = ""
    @State private var startingText: String = "0"
    @State private var isArchived: Bool = false
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Project name", text: $name)
                        .font(.typewriter(18))
                        .foregroundStyle(MarginTheme.inkBlack)
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORD COUNT GOAL (OPTIONAL)")
                            .font(.literata(9, weight: .medium))
                            .foregroundStyle(MarginTheme.inkLight)
                            .tracking(1)
                        TextField("e.g. 80000", text: $goalText)
                            .font(.typewriter(16))
                            .foregroundStyle(MarginTheme.inkBlack)
                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORDS ALREADY WRITTEN")
                            .font(.literata(9, weight: .medium))
                            .foregroundStyle(MarginTheme.inkLight)
                            .tracking(1)
                        TextField("0", text: $startingText)
                            .font(.typewriter(16))
                            .foregroundStyle(MarginTheme.inkBlack)
                            .keyboardType(.numberPad)
                    }

                    if editingProject != nil {
                        Toggle("Archived", isOn: $isArchived)
                            .font(.literata(14))
                            .foregroundStyle(MarginTheme.inkMedium)
                    }
                }
                .padding(.horizontal, 48)
            }
            .paperSurface()
            .navigationTitle(editingProject == nil ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let project = editingProject {
                    name = project.name
                    goalText = project.wordCountGoal.map(String.init) ?? ""
                    startingText = String(project.startingWordCount)
                    isArchived = project.isArchived
                }
            }
            .alert("Couldn't Save Project", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "Unknown save error")
            }
        }
    }

    private func save() {
        let goal = Int(goalText.replacing(",", with: ""))
        let starting = Int(startingText.replacing(",", with: "")) ?? 0

        do {
            if let project = editingProject {
                project.name = name
                project.wordCountGoal = goal
                project.startingWordCount = starting
                project.isArchived = isArchived
            } else {
                let project = Project(
                    name: name,
                    wordCountGoal: goal,
                    startingWordCount: starting
                )
                modelContext.insert(project)
            }
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 4: Implement ProjectDetailView**

```swift
// Views/Projects/ProjectDetailView.swift
import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @Environment(\.marginTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var showEditProject = false
    @State private var sessionPendingDelete: Session?
    @State private var deleteErrorMessage: String?
    @State private var editingSession: Session?

    private var sortedSessions: [Session] {
        project.sessions.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Compact stack + stats
                HStack(alignment: .top, spacing: 20) {
                    ManuscriptStackView(
                        totalWords: project.totalWords,
                        goalWords: project.wordCountGoal,
                        size: .compact
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(project.totalWords) words")
                            .font(.display(20))
                            .foregroundStyle(theme.text)
                        Text("\(project.sessions.count) sessions")
                            .font(.literata(13))
                            .foregroundStyle(theme.textDim)
                        if let progress = project.goalProgress {
                            ProgressView(value: progress)
                                .tint(theme.amber)
                            if let projected = InsightsCalculator.projectedCompletionDate(for: project) {
                                Text("Projected: \(projected, style: .date)")
                                    .font(.literata(11))
                                    .foregroundStyle(theme.textDim)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Session history as pages
                if sortedSessions.isEmpty {
                    Text("No sessions yet")
                        .font(.literata(14))
                        .foregroundStyle(theme.textFaint)
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: -24) {
                        ForEach(Array(sortedSessions.enumerated()), id: \.element.id) { index, session in
                            SessionPageView(
                                session: session,
                                sessionNumber: sortedSessions.count - index,
                                isToday: Calendar.current.isDateInToday(session.date),
                                onRequestDelete: { sessionPendingDelete = session }
                            )
                            .rotationEffect(.degrees(
                                // Stable rotation per session (not random per render)
                                sin(Double(session.id.hashValue % 100) / 50.0) * 1.0
                            ))
                            .zIndex(Double(sortedSessions.count - index))
                            .accessibilityAddTraits(.isButton)
                            .accessibilityLabel("Session \(sortedSessions.count - index)")
                            .onTapGesture {
                                editingSession = session
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(theme.background)
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditProject = true }
            }
        }
        .sheet(isPresented: $showEditProject) {
            NewProjectView(editingProject: project)
        }
        .sheet(item: $editingSession) { session in
            LogSessionView(editingSession: session)
        }
        .alert("Couldn't Delete Session", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Unknown delete error")
        }
        .confirmationDialog(
            "Delete this session?",
            isPresented: Binding(
                get: { sessionPendingDelete != nil },
                set: { if !$0 { sessionPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Session", role: .destructive) {
                guard let session = sessionPendingDelete else { return }
                do {
                    modelContext.delete(session)
                    try modelContext.save()
                    sessionPendingDelete = nil
                } catch {
                    deleteErrorMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {
                sessionPendingDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
```

- [ ] **Step 5: Implement ProjectsListView**

```swift
// TheMargin/Views/Projects/ProjectsListView.swift
import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(\.marginTheme) private var theme
    @Query(sort: \Project.createdAt) private var allProjects: [Project]
    @AppStorage("lastUsedProjectID") private var lastUsedProjectID: String = ""
    @State private var showNewProject = false

    private var activeProjects: [Project] {
        allProjects.filter { !$0.isArchived }
    }
    private var archivedProjects: [Project] {
        allProjects.filter { $0.isArchived }
    }

    @State private var showArchived = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(activeProjects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            ProjectCardView(
                                project: project,
                                isCurrent: project.id.uuidString == lastUsedProjectID
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Archived section
                    if !archivedProjects.isEmpty {
                        Button {
                            withAnimation { showArchived.toggle() }
                        } label: {
                            HStack {
                                Text("Archived")
                                    .font(.literata(12))
                                    .foregroundStyle(theme.textFaint)
                                Text("\(archivedProjects.count)")
                                    .font(.mono(10))
                                    .foregroundStyle(theme.textFaint)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.surfaceRaised)
                                    .clipShape(.capsule)
                                Spacer()
                                Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(theme.textFaint)
                            }
                        }
                        .padding(.top, 16)

                        if showArchived {
                            ForEach(archivedProjects) { project in
                                NavigationLink {
                                    ProjectDetailView(project: project)
                                } label: {
                                    ProjectCardView(project: project, isCurrent: false)
                                        .opacity(0.6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(theme.background)
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("+ New") { showNewProject = true }
                        .font(.literata(12))
                        .foregroundStyle(theme.amber)
                }
            }
            .sheet(isPresented: $showNewProject) {
                NewProjectView()
            }
        }
    }
}
```

- [ ] **Step 6: Wire into ContentView**

Replace `Text("Projects")` in ContentView with `ProjectsListView()`.

- [ ] **Step 7: Build and run — create a project, log sessions, verify project detail**

Specifically verify:
- create/edit project persists only after a successful save
- delete session supports cancel and confirm paths
- deleting a session calls `try modelContext.save()` and surfaces an error on failure
- tapping a session opens the edit flow with prefilled data

- [ ] **Step 8: Commit**

```bash
git add Views/Projects/ Components/ ContentView.swift
git commit -m "feat: add projects tab with list, detail, editing, and recoverable deletes"
```

---

### Task 14: Insights Tab

**Files:**
- Create: `Views/Insights/InsightsView.swift`
- Create: `Views/Insights/WritingCalendarView.swift`
- Create: `Views/Insights/DayOfWeekChartView.swift`
- Create: `Views/Insights/WeeklyTrendChartView.swift`
- Create: `Views/Insights/MoodDistributionView.swift`
- Create: `Views/Insights/GoalProgressCardView.swift`
- Modify: `ContentView.swift` — wire InsightsView into Insights tab

**Context:** See visual spec "Insights Tab" for full layout. Uses Swift Charts for bar chart and line chart. Writing frequency calendar has Week/Month/Year views. Empty state when < 7 sessions. All data comes from InsightsCalculator (Task 5).

- [ ] **Step 1: Implement WritingCalendarView (month view first)**

```swift
// TheMargin/Views/Insights/WritingCalendarView.swift
import SwiftUI

struct WritingCalendarView: View {
    let wordsByDay: [Date: Int]

    @Environment(\.marginTheme) private var theme
    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 12) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(Period.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            switch selectedPeriod {
            case .month: monthView
            case .week: weekView
            case .year: yearView
            }
        }
    }

    private var monthView: some View {
        let today = Date.now
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let maxWords = wordsByDay.values.max() ?? 1

        return VStack(spacing: 4) {
            // Day headers
            HStack(spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.literata(9))
                        .foregroundStyle(theme.textFaint)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Empty cells before first day
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                    Color.clear.frame(height: 32)
                }
                // Day cells
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(bySetting: .day, value: day, of: monthStart)!
                    let dayStart = calendar.startOfDay(for: date)
                    let words = wordsByDay[dayStart] ?? 0
                    let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0
                    let isToday = calendar.isDateInToday(date)

                    Text("\(day)")
                        .font(.literata(11))
                        .foregroundStyle(theme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.amber.opacity(intensity * 0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isToday ? theme.amber : .clear, lineWidth: 1)
                        )
                }
            }
        }
    }

    private var weekView: some View {
        let today = calendar.startOfDay(for: .now)
        let weekStart = calendar.startOfWeek(for: today)

        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
                let dayStart = calendar.startOfDay(for: date)
                let words = wordsByDay[dayStart] ?? 0
                let isToday = calendar.isDate(date, inSameDayAs: today)

                VStack(spacing: 4) {
                    Text(daysOfWeek[offset])
                        .font(.literata(9))
                        .foregroundStyle(theme.textFaint)
                    Text("\(words)")
                        .font(.mono(11))
                        .foregroundStyle(words > 0 ? theme.text : theme.textFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isToday ? theme.amberDim : theme.surface)
                )
            }
        }
    }

    private var yearView: some View {
        // Simplified heatmap — 52 weeks x 7 days
        let today = calendar.startOfDay(for: .now)
        let maxWords = wordsByDay.values.max() ?? 1

        return VStack(alignment: .leading, spacing: 2) {
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(8), spacing: 2), count: 7), spacing: 2) {
                ForEach(0..<364, id: \.self) { daysAgo in
                    let date = calendar.date(byAdding: .day, value: -(363 - daysAgo), to: today)!
                    let dayStart = calendar.startOfDay(for: date)
                    let words = wordsByDay[dayStart] ?? 0
                    let intensity = maxWords > 0 ? Double(words) / Double(maxWords) : 0

                    RoundedRectangle(cornerRadius: 1)
                        .fill(words > 0 ? theme.amber.opacity(0.2 + intensity * 0.6) : theme.surfaceRaised)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Implement DayOfWeekChartView**

```swift
// TheMargin/Views/Insights/DayOfWeekChartView.swift
import SwiftUI
import Charts

struct DayOfWeekChartView: View {
    let wordsByDayOfWeek: [Int: Int] // weekday (1=Sun) → total words
    let bestDay: Int?

    @Environment(\.marginTheme) private var theme

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Chart {
            ForEach(1...7, id: \.self) { weekday in
                BarMark(
                    x: .value("Day", dayLabels[weekday - 1]),
                    y: .value("Words", wordsByDayOfWeek[weekday] ?? 0)
                )
                .foregroundStyle(weekday == bestDay ? theme.amber : theme.surfaceRaised)
                .clipShape(.rect(cornerRadius: 4))
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.literata(10))
                    .foregroundStyle(theme.textDim)
            }
        }
        .frame(height: 120)
    }
}
```

- [ ] **Step 3: Implement WeeklyTrendChartView**

```swift
// TheMargin/Views/Insights/WeeklyTrendChartView.swift
import SwiftUI
import Charts

struct WeeklyTrendChartView: View {
    let weeklyData: [(weekStart: Date, words: Int)]

    @Environment(\.marginTheme) private var theme

    private var average: Int {
        guard !weeklyData.isEmpty else { return 0 }
        return weeklyData.map(\.words).reduce(0, +) / weeklyData.count
    }

    private var percentVsAverage: Int? {
        guard average > 0, let current = weeklyData.last else { return nil }
        return Int(((Double(current.words) / Double(average)) - 1.0) * 100)
    }

    var body: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(weeklyData, id: \.weekStart) { week in
                    LineMark(
                        x: .value("Week", week.weekStart),
                        y: .value("Words", week.words)
                    )
                    .foregroundStyle(theme.amber)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Week", week.weekStart),
                        y: .value("Words", week.words)
                    )
                    .foregroundStyle(theme.amber.opacity(0.1))
                    .interpolationMethod(.catmullRom)

                    // Current week dot with ring glow
                    if week.weekStart == weeklyData.last?.weekStart {
                        PointMark(
                            x: .value("Week", week.weekStart),
                            y: .value("Words", week.words)
                        )
                        .foregroundStyle(theme.amber)
                        .symbolSize(40)
                        .annotation(position: .top) {
                            Text("\(week.words)")
                                .font(.mono(8))
                                .foregroundStyle(theme.amber)
                        }
                    }

                    // Label first data point for context
                    if week.weekStart == weeklyData.first?.weekStart {
                        PointMark(
                            x: .value("Week", week.weekStart),
                            y: .value("Words", week.words)
                        )
                        .foregroundStyle(theme.textFaint)
                        .symbolSize(20)
                        .annotation(position: .top) {
                            Text("\(week.words)")
                                .font(.mono(7))
                                .foregroundStyle(theme.textFaint)
                        }
                    }
                }

                // Dashed average line with label
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(theme.textFaint)
                    .lineStyle(StrokeStyle(dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("avg \(average)")
                            .font(.mono(8))
                            .foregroundStyle(theme.textFaint)
                    }
            }
            .frame(height: 140)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.literata(8))
                        .foregroundStyle(theme.textFaint)
                }
            }

            // Summary row: +X% vs average, this week, avg/week
            HStack {
                if let pct = percentVsAverage {
                    Text(pct >= 0 ? "+\(pct)%" : "\(pct)%")
                        .font(.display(16))
                        .foregroundStyle(pct >= 0 ? Color(hex: 0x7A9070) : Color(hex: 0x7A5C50))
                    Text("vs avg")
                        .font(.literata(8))
                        .foregroundStyle(theme.textFaint)
                        .textCase(.uppercase)
                }
                Spacer()
                if let current = weeklyData.last {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(current.words)")
                            .font(.display(16))
                            .foregroundStyle(theme.text)
                        Text("THIS WEEK")
                            .font(.literata(8))
                            .foregroundStyle(theme.textFaint)
                            .tracking(0.5)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(average)")
                        .font(.display(16))
                        .foregroundStyle(theme.text)
                    Text("AVG / WEEK")
                        .font(.literata(8))
                        .foregroundStyle(theme.textFaint)
                        .tracking(0.5)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

- [ ] **Step 4: Implement MoodDistributionView**

```swift
// TheMargin/Views/Insights/MoodDistributionView.swift
import SwiftUI

struct MoodDistributionView: View {
    let distribution: [Mood: Double]

    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Mood.allCases, id: \.self) { mood in
                let pct = distribution[mood] ?? 0
                HStack(spacing: 8) {
                    Text(mood.glyph)
                        .frame(width: 20)
                    Text(mood.displayName)
                        .font(.literata(12))
                        .foregroundStyle(theme.textDim)
                        .frame(width: 70, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(mood.color)
                            .frame(width: geo.size.width * pct)
                    }
                    .frame(height: 12)
                    Text("\(Int(pct * 100))%")
                        .font(.mono(10))
                        .foregroundStyle(theme.textFaint)
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
    }
}
```

- [ ] **Step 5: Implement GoalProgressCardView**

```swift
// TheMargin/Views/Insights/GoalProgressCardView.swift
import SwiftUI

struct GoalProgressCardView: View {
    let project: Project

    @Environment(\.marginTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name.uppercased())
                .font(.typewriter(11))
                .foregroundStyle(MarginTheme.inkLight)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(MarginTheme.inkLight.opacity(0.3), lineWidth: 0.5)
                )

            if let goal = project.wordCountGoal, let progress = project.goalProgress {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(progress * 100))%")
                        .font(.display(28))
                        .foregroundStyle(theme.amber)
                    Spacer()
                    Text("\(project.totalWords) / \(goal)")
                        .font(.mono(11))
                        .foregroundStyle(theme.textDim)
                }

                ProgressView(value: progress)
                    .tint(theme.amber)

                if let projected = InsightsCalculator.projectedCompletionDate(for: project) {
                    Text("Projected completion: \(projected, style: .date)")
                        .font(.literata(11))
                        .foregroundStyle(theme.textDim)
                }
            } else {
                Text("No word count goal set")
                    .font(.literata(12))
                    .foregroundStyle(theme.textFaint)
            }
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }
}
```

- [ ] **Step 6: Implement InsightsView (main container)**

```swift
// TheMargin/Views/Insights/InsightsView.swift
import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.marginTheme) private var theme
    @Query(sort: \Session.date) private var allSessions: [Session]
    @Query(filter: #Predicate<Project> { !$0.isArchived }) private var projects: [Project]

    @State private var selectedProjectID: String? = nil

    private var filteredSessions: [Session] {
        if let id = selectedProjectID {
            return allSessions.filter { $0.project?.id.uuidString == id }
        }
        return allSessions
    }

    private var hasEnoughData: Bool {
        filteredSessions.count >= 7
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !hasEnoughData {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        Text("Log a few more sessions and your patterns will start to emerge.")
                            .font(.literata(14))
                            .foregroundStyle(theme.textDim)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Text("\(filteredSessions.count) of 7 sessions")
                            .font(.mono(12))
                            .foregroundStyle(theme.textFaint)
                    }
                } else {
                    VStack(spacing: 20) {
                        // Writing frequency calendar
                        WritingCalendarView(
                            wordsByDay: InsightsCalculator.wordsByDay(filteredSessions)
                        )
                        .padding(.horizontal, 16)

                        // Stat cards (2x2)
                        let avgWords = InsightsCalculator.averageWordsPerSession(filteredSessions)
                        let avgDuration = InsightsCalculator.averageDurationSeconds(filteredSessions)
                        let bestDay = InsightsCalculator.bestDayOfWeek(filteredSessions)
                        let weekTotal = InsightsCalculator.thisWeekTotal(filteredSessions)
                        let dayLabels = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCardView(label: "Avg words/session", value: "\(avgWords)")
                            StatCardView(
                                label: "Avg duration",
                                value: avgDuration.map { "\($0 / 60)m" } ?? "—"
                            )
                            StatCardView(
                                label: "Best day",
                                value: bestDay.map { dayLabels[$0] } ?? "—",
                                isHighlighted: true
                            )
                            StatCardView(label: "This week", value: "\(weekTotal)")
                        }
                        .padding(.horizontal, 16)

                        // Streaks
                        let streak = StreakCalculator.calculate(
                            sessionDates: filteredSessions.map(\.date)
                        )
                        HStack {
                            HStack(spacing: 4) {
                                Text("\(streak.current)")
                                    .font(.display(20))
                                    .foregroundStyle(theme.amber)
                                Text("current streak")
                                    .font(.literata(12))
                                    .foregroundStyle(theme.textDim)
                            }
                            Spacer()
                            Text("longest: \(streak.longest)")
                                .font(.literata(12))
                                .italic()
                                .foregroundStyle(theme.textFaint)
                        }
                        .padding(.horizontal, 16)

                        // Words by day of week
                        DayOfWeekChartView(
                            wordsByDayOfWeek: InsightsCalculator.wordsByDayOfWeek(filteredSessions),
                            bestDay: bestDay
                        )
                        .padding(.horizontal, 16)

                        // Weekly trend
                        WeeklyTrendChartView(
                            weeklyData: InsightsCalculator.wordsPerWeekTrend(filteredSessions)
                        )
                        .padding(.horizontal, 16)

                        // Mood distribution
                        MoodDistributionView(
                            distribution: InsightsCalculator.moodDistribution(filteredSessions)
                        )
                        .padding(16)
                        .background(theme.surface)
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal, 16)

                        // Goal progress per project
                        ForEach(projects.filter { $0.wordCountGoal != nil }) { project in
                            GoalProgressCardView(project: project)
                                .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .background(theme.background)
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Projects") { selectedProjectID = nil }
                        ForEach(projects) { project in
                            Button(project.name) {
                                selectedProjectID = project.id.uuidString
                            }
                        }
                    } label: {
                        Text(selectedProjectID == nil ? "All Projects" : "Filtered")
                            .font(.literata(12))
                            .foregroundStyle(theme.amber)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 7: Wire into ContentView**

Replace `Text("Insights")` in ContentView with `InsightsView()`.

- [ ] **Step 8: Build and run — verify insights render with sample data**

Log 7+ sessions across multiple days to verify charts, calendar, and stats populate correctly.

- [ ] **Step 9: Commit**

```bash
git add Views/Insights/ ContentView.swift
git commit -m "feat: add insights tab with calendar, charts, mood distribution, and goal progress"
```

---

### Task 15: Settings Screen

**Files:**
- Create: `Views/Settings/SettingsView.swift`
- Modify: `Views/Dashboard/DashboardView.swift` — wire settings sheet

**Context:** Accessed via gear icon, not a tab. Standard iOS form controls on dark background, no paper metaphor. See visual spec "Settings" section. Export should hand the user a named `.csv` file rather than raw `Data`, and reminder UI must hydrate from actual notification authorization + pending request state on open instead of trusting `@AppStorage` alone.

- [ ] **Step 1: Implement SettingsView**

```swift
// Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.marginTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Session.date, order: .reverse) private var allSessions: [Session]

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 9
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var reminderTime = Date.now
    @State private var exportDocument: CSVExportDocument?
    @State private var showExporter = false
    @State private var reminderErrorMessage: String?

    private var csvString: String {
        CSVExportService.generate(sessions: allSessions)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Reminder") {
                    Toggle("Enabled", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationService.requestPermission()
                                    if granted {
                                        try? await NotificationService.scheduleDailyReminder(
                                            at: reminderHour,
                                            minute: reminderMinute
                                        )
                                    } else {
                                        reminderEnabled = false
                                        reminderErrorMessage = "Notifications are disabled for The Margin."
                                    }
                                }
                            } else {
                                NotificationService.cancelDailyReminder()
                            }
                        }

                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newTime in
                                let components = Calendar.current.dateComponents(
                                    [.hour, .minute], from: newTime
                                )
                                reminderHour = components.hour ?? 9
                                reminderMinute = components.minute ?? 0
                                Task {
                                    try? await NotificationService.scheduleDailyReminder(
                                        at: reminderHour,
                                        minute: reminderMinute
                                    )
                                }
                            }
                    }
                }

                Section("Data") {
                    Button {
                        exportDocument = CSVExportDocument(csv: csvString)
                        showExporter = true
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allSessions.isEmpty)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(theme.textDim)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let state = await NotificationService.currentReminderState()
                reminderEnabled = state.isScheduled
                reminderHour = state.hour ?? reminderHour
                reminderMinute = state.minute ?? reminderMinute
                reminderTime = Calendar.current.date(
                    from: DateComponents(hour: reminderHour, minute: reminderMinute)
                ) ?? reminderTime
            }
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "the-margin-export"
            ) { _ in
                exportDocument = nil
            }
            .alert("Reminder Unavailable", isPresented: Binding(
                get: { reminderErrorMessage != nil },
                set: { if !$0 { reminderErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(reminderErrorMessage ?? "Notification state is unavailable.")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

Add a small `CSVExportDocument: FileDocument` wrapper in the same task, and extend `NotificationService` with read helpers such as `currentReminderState()` so the settings screen can reconcile stored preferences with the system's real authorization + scheduled-notification state.

- [ ] **Step 2: Wire into DashboardView**

Replace the settings placeholder:

```swift
.sheet(isPresented: $showSettings) {
    SettingsView()
}
```

- [ ] **Step 3: Build and run — verify settings, notification permission, CSV export**

- [ ] **Step 4: Commit**

```bash
git add Views/Settings/ Views/Dashboard/DashboardView.swift Services/NotificationService.swift Services/CSVExportService.swift
git commit -m "feat: add settings screen with daily reminders and CSV export"
```

---

### Task 16: Dashboard Animations + Save-to-Stack

**Files:**
- Modify: `TheMargin/Components/ManuscriptStackView.swift` — add build animation, stack fan interaction
- Modify: `TheMargin/Views/Dashboard/DashboardView.swift` — choreograph app-open sequence, save-to-stack, streak ink dots
- Create: `TheMargin/Components/OdometerView.swift` — typewriter odometer for stat numbers
- Create: `TheMargin/Components/StreakDotsView.swift` — ink dot streak display
- Create: `TheMargin/Components/TypewriterConfirmation.swift` — letter-by-letter confirmation text
- Create: `TheMargin/Services/TypewriterAudioEngine.swift` — AVAudioEngine for key strike/bell/carriage sounds
- Add: `TheMargin/Resources/Audio/key-strike.caf` — single key press (~100ms), sliced from [exterminat #164807](https://freesound.org/people/exterminat/sounds/164807/)
- Add: `TheMargin/Resources/Audio/bell.caf` — margin bell (~400ms), sliced from [evsecrets #334458](https://freesound.org/people/evsecrets/sounds/334458/)
- Add: `TheMargin/Resources/Audio/carriage-return.caf` — carriage return (~250ms), sliced from [evsecrets #334458](https://freesound.org/people/evsecrets/sounds/334458/)

**Context:** See "Animations & Interactions Spec" at the top of this plan for full timing details. This task implements three major animation systems: the dashboard open choreography (1.5s orchestrated sequence), the save-to-stack transition (2.8s three-phase ceremony), and the stack fan interaction (long-press to reveal recent sessions). Task 10 already owns the structural dashboard/fan layout; this task should add animation and choreography without reintroducing a flat recent-sessions list.

- [ ] **Step 1: Implement stack build animation with decelerating stagger**

Add `animated: Bool` parameter to ManuscriptStackView. When true, pages animate in using paper-drop physics with decelerating stagger.

```swift
// Add to ManuscriptStackView:
let animated: Bool
@State private var visiblePages: Int = 0
@State private var shadowOpacity: Double = 0

// Decelerating stagger: fast at bottom, deliberate at top
private func staggerDelay(index: Int, total: Int) -> Double {
    let totalDuration = 0.8 // 800ms for full build
    let t = Double(index) / Double(max(total - 1, 1))
    let eased = 1 - pow(1 - t, 2.2) // quadratic ease-out
    return eased * totalDuration
}

// Page land animation: paper drop with overshoot + settle
private func pageLandAnimation() -> Animation {
    // translateY(-20) → +2 overshoot → -1 bounce → 0 settle, 350ms
    .spring(response: 0.35, dampingFraction: 0.55)
}

// In .task:
@Environment(\.accessibilityReduceMotion) private var reduceMotion

.task {
    guard animated else { return }
    if reduceMotion {
        // Skip stagger: show all pages immediately with opacity fade
        withAnimation(.easeIn(duration: 0.3)) {
            visiblePages = visualPages
            shadowOpacity = 1
        }
        return
    }
    for i in 0..<visualPages {
        try? await Task.sleep(for: .seconds(staggerDelay(index: i, total: visualPages)))
        withAnimation(pageLandAnimation()) { visiblePages = i + 1 }
        // Shadow/glow at 50% build
        if i == visualPages / 2 {
            withAnimation(.easeIn(duration: 0.3)) { shadowOpacity = 1 }
        }
    }
}
// Haptics via .sensoryFeedback on each page:
.sensoryFeedback(.impact(weight: .light), trigger: visiblePages)
```

- [ ] **Step 2: Implement OdometerView — typewriter digit roller**

Each digit column rolls independently, right-to-left stagger. Used for Total Words and Today stats.

```swift
// TheMargin/Components/OdometerView.swift
struct OdometerView: View {
    let value: Int
    let animated: Bool

    // Each digit is a vertical strip of 0–9 that translates to the target digit.
    // Right-most digit starts first (50ms delay per column from right).
    // Animation: 500ms cubic-bezier(0.2, 0, 0.1, 1)
}
```

- [ ] **Step 3: Implement StreakDotsView — ink dot weekly display**

7 circular dots for the current week. Filled amber = wrote, empty ring = missed, today glows.

```swift
// TheMargin/Components/StreakDotsView.swift
struct StreakDotsView: View {
    let weekHistory: [Bool] // 7 bools, Mon–Sun
    let todayIndex: Int

    // Each dot: 12px diameter, 8px gap
    // Active: filled #C4956A
    // Empty: transparent, 1.5px border #3E3A34
    // Today: filled #C4956A with shadow glow
}
```

- [ ] **Step 4: Implement stack fan interaction — long-press to peek sessions**

Add long-press gesture to ManuscriptStackView on dashboard. Fans top 5 pages to reveal session data in cascade overlap.

```swift
// Add to ManuscriptStackView (dashboard size only):
@State private var isFanned: Bool = false
@GestureState private var isLongPressing: Bool = false

// Fan pages: 5 most recent sessions, reverse chronological
// Collapsed: margin-top -44px (only 8px visible per page)
// Fanned: margin-top -26px (~22px visible per page)
// Z-index flips when fanned: bottom pages above top pages so data is visible
// Session data: opacity 0 → 1 with 250ms delay when fanning
// "Hold to peek" hint below stack, fades when fanned

var longPressGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.3)
        .onEnded { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isFanned.toggle()
            }
        }
}
```

- [ ] **Step 5: Choreograph dashboard open sequence**

Wire up the full 1.5s orchestrated timeline in DashboardView.onAppear:

```swift
// Timeline (all delays from .onAppear):
// 0–800ms:     Stack build (handled by ManuscriptStackView.animated)
// 800ms:       Stats odometer starts (OdometerView.animated triggers)
// 900ms:       Progress bar fills
// 1100ms:      Streak row fades in
// 1200ms:      Ink dots fade in with stagger
// 1300ms:      Pen FAB scales in

@State private var showStats = false
@State private var showProgress = false
@State private var showStreak = false
@State private var showFAB = false

@Environment(\.accessibilityReduceMotion) private var reduceMotion

.task {
    if reduceMotion {
        // Show everything immediately — skip choreography
        showStats = true; showProgress = true; showStreak = true; showFAB = true
        return
    }
    try? await Task.sleep(for: .seconds(0.8))
    withAnimation { showStats = true }
    try? await Task.sleep(for: .seconds(0.1))
    withAnimation(.easeOut(duration: 0.8)) { showProgress = true }
    try? await Task.sleep(for: .seconds(0.2))
    withAnimation { showStreak = true }
    try? await Task.sleep(for: .seconds(0.2))
    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { showFAB = true }
}
```

- [ ] **Step 6: Implement full save-to-stack transition**

Three-phase ceremony when the log session sheet saves:

```swift
// Phase 1 — Form transforms (0–900ms):
// Paper lifts (translateY -4px, shadow deepens, 200ms)
// Form compresses (scaleY 1→0.08, text fades, 400ms)
// Pages split (compressed page → N pages with jitter, 300ms)
//
// Phase 2 — Pages land (900–1700ms):
// Pages cascade onto stack (180ms stagger, 280ms settle-bounce each)
// Pages start amber, fade to paper-white
// Stats odometer ticks up as pages land
// Haptic: .light per page, .success on completion
//
// Phase 3 — Confirmation (1700–2800ms):
// TypewriterConfirmation types "N new pages." letter-by-letter (110ms/char)
// Key strike sound per character
// Streak pulses (scale 1→1.15→1, 300ms) if first session today
// Confirmation fades out (400ms)

// Use a dedicated SaveToStackAnimator class to manage the state machine
// and coordinate between the log sheet dismiss and dashboard updates.
```

- [ ] **Step 7: Implement TypewriterConfirmation view**

Letter-by-letter text in Special Elite with key strike sounds per character.

```swift
// TheMargin/Components/TypewriterConfirmation.swift
struct TypewriterConfirmation: View {
    let text: String
    @State private var visibleCharacters: Int = 0

    // 110ms per character, key strike sound per char
    // Characters use ink variation (weighted random 60/25/15)
    // Fades out after 2s via parent control
}
```

- [ ] **Step 8: Bundle typewriter audio samples and implement TypewriterAudioEngine**

**Step 8a: Source, slice, and bundle audio files**

Two CC0 typewriter recordings from Freesound provide all three sounds:

| Source | URL | What to extract |
|--------|-----|-----------------|
| Hermes Baby by evsecrets | [#334458](https://freesound.org/people/evsecrets/sounds/334458/) | Bell (line-end ding), carriage return. Mono, 44.1kHz, 32-bit WAV, 1:27 |
| Typewriter by exterminat | [#164807](https://freesound.org/people/exterminat/sounds/164807/) | Key strike (isolated slow keystrokes at start). Stereo, 44.1kHz, 16-bit WAV, 57s |

Download both WAVs (requires free Freesound account). Then slice and convert using `ffmpeg` + `afconvert`:

```bash
# 1. Key strike — extract a single clean keystroke from exterminat recording
#    The slow individual keystrokes are in the first ~15s. Pick one with clean attack.
#    Trim to ~100ms (attack transient only — avoids muddy overlap at 110ms typing interval)
ffmpeg -i 164807__exterminat__typewriter.wav -ss 2.1 -t 0.1 -ac 1 key-strike.wav

# 2. Bell — extract the line-end ding from evsecrets recording
#    Listen for the "ding" at the end of each typed line. First one is around ~8-10s in.
#    Keep natural ring-out (~300ms)
ffmpeg -i 334458__evsecrets__typing-on-a-typewriter.wav -ss 8.5 -t 0.4 bell.wav

# 3. Carriage return — extract the mechanical slide after a ding from evsecrets
#    The carriage return follows immediately after each ding. ~200ms of mechanical slide.
ffmpeg -i 334458__evsecrets__typing-on-a-typewriter.wav -ss 8.9 -t 0.25 carriage-return.wav

# 4. Convert all to .caf (Core Audio Format) for lowest-latency iOS playback
afconvert -f caff -d LEI16@44100 key-strike.wav Resources/Audio/key-strike.caf
afconvert -f caff -d LEI16@44100 bell.wav Resources/Audio/bell.caf
afconvert -f caff -d LEI16@44100 carriage-return.wav Resources/Audio/carriage-return.caf

# 5. Clean up intermediate WAVs
rm key-strike.wav bell.wav carriage-return.wav
```

**Timestamps are approximate** — listen to both source files and adjust `-ss` (start) and `-t` (duration) to get clean transients. The evsecrets recording has multiple typing lines with dings, so there are several bell/carriage candidates to choose from. Pick the crispest one.

**Key strike selection tip:** The exterminat recording starts with slow isolated keystrokes (~1 per second) before speeding up. These early strikes have the cleanest separation. Avoid the fast burst section — too much overlap to isolate cleanly.

Add all three `.caf` files to the `Resources/Audio/` directory and verify they appear in the `project.yml` source group (the `Resources/**` glob should catch them).

**Step 8b: Implement TypewriterAudioEngine**

Uses `AVAudioEngine` with pre-loaded `AVAudioPCMBuffer` instances for zero-latency playback. Pitch and volume variation per keystroke creates the mechanical imperfection that makes it feel real.

```swift
// Services/TypewriterAudioEngine.swift
import AVFoundation

@MainActor
final class TypewriterAudioEngine {
    private let engine = AVAudioEngine()
    private var keyStrikeBuffer: AVAudioPCMBuffer?
    private var bellBuffer: AVAudioPCMBuffer?
    private var carriageReturnBuffer: AVAudioPCMBuffer?

    /// Pool of player nodes for polyphonic key strikes.
    /// Multiple keys can overlap (e.g. during fast typing or the confirmation sequence).
    private var playerPool: [AVAudioPlayerNode] = []
    private var nextPlayerIndex = 0
    private let poolSize = 4

    private var isRunning = false

    init() {
        setupEngine()
    }

    private func setupEngine() {
        // Pre-decode audio files into PCM buffers at init — not at play time
        keyStrikeBuffer = loadBuffer(named: "key-strike")
        bellBuffer = loadBuffer(named: "bell")
        carriageReturnBuffer = loadBuffer(named: "carriage-return")

        // Create a pool of player nodes for polyphonic playback
        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: keyStrikeBuffer?.format)
            playerPool.append(player)
        }

        do {
            try engine.start()
            isRunning = true
        } catch {
            // Audio is non-critical — fail silently, app still works
            isRunning = false
        }
    }

    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf"),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: file.processingFormat,
                  frameCapacity: AVAudioFrameCount(file.length)
              ) else { return nil }
        try? file.read(into: buffer)
        return buffer
    }

    /// Play a key strike with per-character pitch and volume variation.
    /// Pitch range: 0.94–1.08× (subtle mechanical imperfection).
    /// Volume range: 0.7–1.0 (simulates varying strike force).
    func playKeyStrike() {
        guard isRunning, let buffer = keyStrikeBuffer else { return }

        let player = playerPool[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1

        if player.isPlaying { player.stop() }
        player.volume = Float.random(in: 0.7...1.0)
        player.rate = Float.random(in: 0.94...1.08)

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    /// Play the margin bell (no pitch variation — bells have a fixed pitch).
    func playBell() {
        guard isRunning, let buffer = bellBuffer else { return }
        let player = playerPool[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1

        if player.isPlaying { player.stop() }
        player.volume = 0.8
        player.rate = 1.0

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    /// Play carriage return at 1.3× speed (spec: "real recording at 1.3× playback speed").
    func playCarriageReturn() {
        guard isRunning, let buffer = carriageReturnBuffer else { return }
        let player = playerPool[nextPlayerIndex % poolSize]
        nextPlayerIndex += 1

        if player.isPlaying { player.stop() }
        player.volume = 0.85
        player.rate = 1.3

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    /// Stop the engine when leaving the timer screen.
    func shutdown() {
        playerPool.forEach { $0.stop() }
        engine.stop()
        isRunning = false
    }

    /// Mute check — respects the user's sound preference stored in UserDefaults.
    var isMuted: Bool {
        UserDefaults.standard.bool(forKey: "typewriterSoundMuted")
    }
}
```

**Key design decisions:**
- **Player pool (4 nodes):** At 110ms typing intervals, up to 3 strikes can overlap. 4 nodes gives headroom.
- **Pre-decoded buffers:** `.caf` files are loaded into `AVAudioPCMBuffer` at init, not at play time. This eliminates the ~5ms decode latency that would make strikes feel laggy.
- **Fail-silent:** If audio setup fails (e.g. permissions, hardware), the engine marks itself as not running. The app works fine without sound.
- **Mute support:** Reads a UserDefaults key so Settings can add a sound toggle. The engine still exists but callers should check `isMuted` before calling play methods.
- **Rate for pitch variation:** `AVAudioPlayerNode.rate` changes playback speed which also shifts pitch — this is the correct behavior for simulating mechanical variation in a real typewriter.

**Step 8c: Wire audio into TimerViewModel**

Add a `TypewriterAudioEngine` instance to the timer and call it from the typing loop:

```swift
// In TimerViewModel:
@State private var audioEngine = TypewriterAudioEngine()

// In beginTyping(), after each character:
if !audioEngine.isMuted {
    audioEngine.playKeyStrike()
}

// On carriage return:
if !audioEngine.isMuted {
    audioEngine.playBell()
    // After bell, before next line:
    audioEngine.playCarriageReturn()
}

// In stop():
audioEngine.shutdown()
```

**Step 8d: Wire audio into TypewriterConfirmation**

The save-to-stack confirmation ("N new pages.") also types letter-by-letter with key strike sounds:

```swift
// In TypewriterConfirmation, each character tick:
if !audioEngine.isMuted {
    audioEngine.playKeyStrike()
}
```

- [ ] **Step 9: Build and run — verify all three animation systems**

Test:
1. App open → full 1.5s dashboard choreography with haptics
2. Long-press stack → fan reveals 5 sessions, tap to collapse
3. Log session → full 2.8s save-to-stack ceremony with sounds and haptics
4. Tab switching → instant swap, no animation

- [ ] **Step 10: Commit**

```bash
git add Components/OdometerView.swift Components/StreakDotsView.swift \
  Components/TypewriterConfirmation.swift Components/ManuscriptStackView.swift \
  Services/TypewriterAudioEngine.swift \
  Views/Dashboard/DashboardView.swift Resources/Audio/
git commit -m "feat: dashboard animations, save-to-stack ceremony, stack fan, typewriter audio"
```

---

### Task 17: Polish + Integration Testing

**Files:**
- Modify: Various — fix issues found during integration testing
- Modify: `TheMargin/ContentView.swift` — final tab bar styling

**Context:** Final pass. Style the tab bar per visual spec (Literata 9px labels, SF Symbols, amber active, text-faint inactive, 1px top border). Test the full flow end-to-end: create project → log session → verify dashboard updates → check insights → export CSV. Fix any data flow issues.

- [ ] **Step 1: Style the tab bar with Literata 9px, amber/text-faint, 1px border**

In `TheMarginApp.swift` or `ContentView.init()`, configure `UITabBarAppearance`:

```swift
init() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(MarginTheme(colorScheme: .dark).background)

    // 1px top border
    appearance.shadowColor = UIColor.white.withAlphaComponent(0.04)

    // Literata 9px for tab labels
    let literata9 = UIFont(name: "Literata-Regular", size: 9) ?? .systemFont(ofSize: 9)
    let normalAttrs: [NSAttributedString.Key: Any] = [
        .font: literata9,
        .foregroundColor: UIColor(Color(hex: 0x605850)) // text-faint
    ]
    let selectedAttrs: [NSAttributedString.Key: Any] = [
        .font: literata9,
        .foregroundColor: UIColor(Color(hex: 0xC4956A)) // amber
    ]

    appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
    appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: 0x605850))
    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: 0xC4956A))

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
}
```

Also apply `.tint(MarginTheme(colorScheme: .dark).amber)` to the `TabView` in ContentView.

- [ ] **Step 2: End-to-end flow test**

Manually test:
1. First launch → empty state → create project with goal and starting word count
2. Log a session via "Log Session" → verify the stack/fan updates and stale `lastUsedProjectID` falls back cleanly
3. Start a timed session → verify timer runs, tip types out, pause/resume works → stop → log form has duration pre-filled
4. Check Projects tab → project card shows updated word count → drill into detail → session pages render
5. Log 7+ sessions across multiple days → verify Insights tab populates
6. Settings → deny notification permission, then allow it, reopen settings, and verify reminder UI matches actual system state
7. Settings → export with real data and with zero sessions; verify filename, CSV escaping, and empty-export behavior
8. Attempt delete → cancel, then delete → confirm; verify cancel keeps the session and confirm persists removal
9. Force a save failure for project/session edits and verify the sheet stays open with an error
10. Archive a project → verify it moves to archived section
11. Switch between projects on dashboard → verify stack updates and fan interaction still targets the correct project

- [ ] **Step 3: Fix any issues found**

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: polish tab bar styling and fix integration issues"
```

---

## Summary

| Task | What it builds | Depends on |
|------|----------------|------------|
| 1 | Xcode project, fonts, tab skeleton | — |
| 2 | SwiftData models + enums + schema versioning | 1 |
| 3 | Theme / design system | 1 |
| 4 | Streak calculator | 2 |
| 5 | Insights calculator | 2 |
| 6 | Tip rotation + CSV export | 2 |
| 7 | Notification service | — |
| 8 | Manuscript stack component | 3 |
| 9 | Mood selector, FAB, stat card | 3 |
| 10 | Dashboard view | 2, 3, 4, 8, 9 |
| 11 | Log session flow | 2, 3, 9, 10 |
| 12 | Timer screen | 3, 6, 11 |
| 13 | Projects tab + detail | 2, 3, 5, 8 |
| 14 | Insights tab | 2, 3, 4, 5, 9 |
| 15 | Settings | 6, 7, 10 |
| 16 | Dashboard animations, save-to-stack, stack fan, audio | 8, 10, 11 |
| 17 | Polish + integration | All |

**Parallelizable groups:**
- Tasks 4, 5, 6, 7 can run in parallel (all depend only on 2)
- Tasks 8, 9 can run in parallel (both depend only on 3)
- Tasks 13, 14 can start once 8, 9 are done (they don't depend on 10-12)
