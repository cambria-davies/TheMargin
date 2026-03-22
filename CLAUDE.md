# CLAUDE.md

Guidance for Claude Code when working on The Margin.

## Overview

The Margin is a native iOS writing tracker app — session logging, timed writing sessions, manuscript progress visualization, streaks, and pattern insights. It is a personal tool for writers who care about showing up consistently.

## Quick Reference

```bash
# Regenerate Xcode project after adding/removing files:
xcodegen generate

# Build (simulator) — always use --quiet to avoid flooding context:
xcodebuild -target TheMargin -sdk iphonesimulator build ONLY_ACTIVE_ARCH=YES ARCHS=arm64 --quiet

# Run tests (once simulator runtime is installed):
xcodebuild test -scheme TheMargin -destination 'platform=iOS Simulator,name=iPhone 16' --quiet
```

## iOS Development Gotchas

These are hard-won lessons from the community. Follow them strictly.

- **Never edit `.pbxproj` files directly** — one bad edit corrupts the entire Xcode project. Always use `xcodegen generate` after adding/removing files instead.
- **Always use `--quiet` on xcodebuild** — without it, verbose output floods the context window and wastes tokens, especially on build failures.
- **Never clear DerivedData** — it doesn't fix underlying problems and breaks Xcode's ability to resolve Swift packages. Requires an Xcode restart to recover.
- **Use `--terminate-running-process`** when launching on simulator via `simctl` — prevents silent relaunch of stale app instances, which causes misinterpreted logs.
- **Large refactors are slow** — renaming a class across many files can take 25+ minutes. Prefer incremental changes.
- **XcodeBuildMCP is configured** — use it for builds, tests, simulator management, and debugging instead of raw xcodebuild commands when available.

## Architecture

**Pattern:** MVVM — SwiftUI views, view models for stateful screens, `@Model` classes for persistence, service classes for business logic.

**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Charts, UserNotifications, iOS 17+

**No third-party dependencies.** Apple frameworks only, plus bundled Google Fonts (OFL licensed).

### Project Structure
```
TheMargin/
├── TheMarginApp.swift              # App entry, ModelContainer, font registration, tip seeding
├── ContentView.swift               # 3-tab root (Home, Projects, Insights)
├── Models/                         # @Model classes (Project, Session, WritingTip) + enums
├── Services/                       # Pure logic: streaks, insights, tip rotation, CSV export
├── Theme/                          # Color tokens, typography helpers, paper surface modifier
├── Components/                     # Reusable views: manuscript stack, mood selector, FAB, stat cards
├── Views/                          # Screen-level views organized by feature
│   ├── Dashboard/
│   ├── Timer/
│   ├── LogSession/
│   ├── Projects/
│   ├── Insights/
│   └── Settings/
├── Resources/
│   ├── Fonts/                      # .ttf files (Special Elite, Newsreader, Literata, JetBrains Mono)
│   ├── writing-tips.json           # Bundled ~60 tips/quotes
│   └── Assets.xcassets/
TheMarginTests/
├── ModelTests/
├── ServiceTests/
└── ViewModelTests/
```

### Key Patterns

- **SwiftData for persistence** — `@Model` classes, `@Query` in views, `ModelContainer` at app root
- **Services are pure logic** — no SwiftData imports in service classes; they take arrays/values, not model contexts
- **Theme is centralized** — all colors, fonts, and paper textures go through `MarginTheme`, `PaperSurface`, and `TypewriterText`
- **View models for stateful screens only** — Timer and LogSession have view models; simple list/detail views use `@Query` directly

## Design System

The Margin has a specific visual identity — do not use default iOS styling.

- **Two modes:** Lamplight (dark/warm default) and Daylight (light)
- **Paper metaphor:** Views use a paper surface with ruled lines and a red margin line
- **Accent philosophy:** No chromatic accent — accent is ink (light mode) or warm white (dark mode). Hierarchy through weight/size/brightness, not color.
- **Typography:** Fraunces (display/numbers), Space Grotesk (body/labels), Space Mono (metadata), Special Elite (typewriter on paper surfaces only)
- **Ink variation:** Typewriter text has subtle per-character opacity and position jitter
- **Texture:** Paper noise at 3.5% opacity on elevated card surfaces; SVG manuscript stack with ruled lines, margin line, dog-ear

Refer to the visual design spec at `docs/specs/2026-03-22-the-margin-visual-design-v2.md` for exact tokens, colors, and spacing.

## Specs

- **Product spec:** `docs/specs/2026-03-20-the-margin-design.md`
- **Visual design spec:** `docs/specs/2026-03-22-the-margin-visual-design-v2.md` (supersedes v1 from 2026-03-20)
- **Implementation plan:** `docs/plans/2026-03-20-the-margin.md`

Read the relevant spec before implementing any feature. Do not guess at behavior or visual details.

## Testing

### Test Ownership
**If tests fail after your changes, you own those failures.** Do not dismiss failures as pre-existing — assume all failures are caused by your changes until proven otherwise.

### What to Test
- **Models:** Computed properties, relationships, edge cases (zero word counts, nil optionals)
- **Services:** All business logic — streak calculation (gaps, timezones, empty data), insights aggregation, tip rotation (random-without-repeat), CSV export (escaping, encoding)
- **View models:** State transitions (timer run/pause/stop), form validation, save behavior

### How to Test
- Services are pure functions/classes — test them with plain XCTest, no SwiftData needed
- Model tests use an in-memory `ModelContainer` — create one per test method
- View model tests may need a model context injected

```swift
// In-memory container for tests
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: Project.self, Session.self, configurations: config)
```

## Swift Style

- **Naming:** Swift API Design Guidelines — `camelCase` properties/methods, `CapWords` types
- **Access control:** Mark things `private` by default; only expose what's needed
- **Avoid force unwraps** (`!`) except in tests or truly invariant situations
- **Prefer value types** — use structs and enums where possible; `@Model` classes are the exception

## Git

- **Never use `--no-verify`** on commits or pushes
- **Commit messages:** Concise, imperative mood ("Add streak calculator", not "Added streak calculator")
- Build must succeed before committing
