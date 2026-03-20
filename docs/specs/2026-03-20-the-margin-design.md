# The Margin — Product Requirements Document

## Product Vision

The Margin is a native iOS writing tracker for writers who want to build consistent habits and see their progress come to life. It replaces the spreadsheet-and-willpower approach with a dedicated app that makes logging sessions fast, visualizes manuscript progress as a growing stack of pages, and surfaces patterns in your writing practice. Positioned between Day One's reflective journaling, Duolingo's streak motivation, and Scrivener's project awareness — The Margin is the app you open after you write, and the reason you write again tomorrow.

The target user is a working writer (fiction, nonfiction, or both) who juggles multiple projects and wants a lightweight way to track output, reflect on sessions, and stay motivated — without the overhead of a full manuscript management tool. The aesthetic is manuscript/journal: dark parchment tones, serif typography, and ink-like accents. Opening the app should feel like opening a writer's notebook.

---

## User Stories

### Session Logging
- As a writer, I want to quickly log my word count after a writing session so that I can track my output without friction.
- As a writer, I want to add freeform notes about what I worked on and how it went so that I can reflect on my process over time.
- As a writer, I want to tag a mood for each session (dry / grinding / steady / flow / breakthrough) so that I can see how my emotional state correlates with productivity.
- As a writer, I want to optionally tag a chapter or section so that I can see which parts of a project I've been working on.
- As a writer, I want the log form to default to my last-used project so that logging is fast when I'm focused on one project.

### Timed Sessions
- As a writer, I want to start a session timer before I write so that I can track how long my sessions actually take.
- As a writer, I want to pause and resume the timer so that I can take breaks without inflating my session duration.
- As a writer, I want to see a writing tip type out letter-by-letter on the timer screen so that I'm motivated and rewarded for starting a session.
- As a writer, I want the timer duration to carry over into the log form when I stop the timer so that I don't have to enter it manually.

### Manuscript Progress
- As a writer, I want to set a word count goal for each project so that I can track progress toward completion.
- As a writer, I want to enter a starting word count when creating a project so that existing work is reflected in my progress.
- As a writer, I want to see my manuscript progress visualized as a growing stack of pages so that my progress feels tangible and real.

### Projects
- As a writer, I want to manage multiple projects so that I can track a novel and blog posts separately.
- As a writer, I want to archive completed projects without losing their data so that my active project list stays clean.
- As a writer, I want to see a per-project session history so that I can review my work on a specific project.

### Streaks & Momentum
- As a writer, I want to see my current writing streak (consecutive days with any session logged) so that I'm motivated to maintain consistency.
- As a writer, I want to see my longest streak of all time so that I have a personal record to beat.

### Pattern Insights
- As a writer, I want to see my best writing day of the week so that I can plan my schedule around my natural rhythm.
- As a writer, I want to see my average words per session and average session duration so that I can set realistic goals.
- As a writer, I want to see my mood distribution so that I can notice patterns in how I feel about my writing.
- As a writer, I want to see a words-per-week trend so that I can see whether I'm improving over time.
- As a writer, I want to see my progress toward my word count goal with a projected completion date so that I know if I'm on pace.
- As a writer, I want to see a writing frequency calendar (week/month/year views) so that I can visualize my consistency and build a daily habit.
- As a writer, I want to filter insights by project so that I can analyze my patterns on a specific project.

### Daily Writing Tips
- As a writer, I want to see a rotating craft tip or writer quote on my dashboard so that I'm inspired each time I open the app.
- As a writer, I want to see a writing tip type out on the timer screen so that starting a session feels rewarding.

### Settings & Data
- As a writer, I want to set a daily reminder notification so that I don't forget to write.
- As a writer, I want to export my data as CSV so that I can back it up or continue using a spreadsheet alongside the app.

---

## Data Model

### Project
| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | e.g., "Novel Draft 2", "Blog Posts" |
| `wordCountGoal` | Int? | Optional target (e.g., 80,000) |
| `startingWordCount` | Int | Default 0. Words written before tracking. |
| `createdAt` | Date | |
| `isArchived` | Bool | Hide completed projects without deleting data |
| `sessions` | [Session] | Relationship — one-to-many |

**Computed:** `totalWords` = `startingWordCount` + sum of `sessions.wordCount`

### Session
| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `project` | Project | Relationship — many-to-one |
| `date` | Date | |
| `wordCount` | Int | |
| `notes` | String? | Freeform — what you worked on, how it went |
| `mood` | Mood | Enum: dry, grinding, steady, flow, breakthrough |
| `durationSeconds` | Int? | Only populated if timer was used |
| `chapterTag` | String? | Optional label — "Ch. 3", "Introduction" |

### WritingTip
| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `text` | String | The tip or quote text |
| `attribution` | String? | Author name for quotes, nil for craft tips |
| `category` | TipCategory | Enum: craft, quote |

Ships pre-populated with ~50-100 tips bundled in the app. No network dependency. Daily rotation is random-without-repeat (cycle through all tips before reshuffling).

### Enums
- **Mood**: `dry`, `grinding`, `steady`, `flow`, `breakthrough`
- **TipCategory**: `craft`, `quote`

### Derived Data (computed, not stored)
- **Streak**: calculated from consecutive calendar days with at least one session
- **Insights**: aggregated from session data on the fly (averages, trends, distributions)
- **Goal progress**: `project.totalWords / project.wordCountGoal`
- **Projected completion date**: based on current writing pace

---

## Screen Inventory

### 1. Dashboard (Home Tab)
**Purpose:** At-a-glance status — the screen you see when you open the app.

**Elements:**
- Daily writing tip or quote (rotates daily)
- Current streak counter (prominent, top area)
- Manuscript stack visualization for current project — shows project name, stack progress, words written today, and total progress toward goal. Defaults to last-used project; subtle switcher to change project.
- Recent sessions list (last 3-5, below the stack — date, word count, mood icon)
- Pen FAB (floating action button, bottom-right) — taps to reveal popup with "Start Session" and "Log Session" options

### 2. Timer Screen (from "Start Session")
**Purpose:** Active writing companion — the screen that's open while you write.

**Elements:**
- Running timer display (minutes:seconds)
- Play / pause / stop controls
- Writing tip that types out letter-by-letter in a typewriter animation (appears when timer starts)
- Tapping stop transitions to the Log Session Fields screen with duration pre-filled

**States:** Running → Paused → Running → Stopped → Log Fields

### 3. Log Session Fields (Modal Sheet)
**Purpose:** Fast post-writing entry — the core interaction.

**Elements:**
- Project selector (defaults to last-used, subtle — not primary UI)
- Word count input (large, prominent number field)
- Chapter/section tag (optional, with recent tags as quick suggestions)
- Mood selector (5 icons in a row — tap to select)
- Notes field (freeform text, expandable)
- Duration display (if coming from timer — shown but not editable)
- Save button

**Design goal:** Log a session in under 15 seconds.

**Editing/deleting:** Users can edit or delete previously logged sessions from the project detail session history. Swipe-to-delete, tap to edit.

### 4. Projects (Tab)
**Purpose:** Manage projects and see per-project detail.

**Elements:**
- List of active projects with manuscript stack thumbnail + total words
- "New Project" button
- Archived projects section (collapsed, at bottom)

**Project Detail (push view):**
- Full manuscript stack visualization
- Word count goal progress
- Session history for that project
- Edit / archive project

### 5. Insights (Tab)
**Purpose:** Patterns and stats across all writing.

**Elements:**
- Best writing day of week (bar chart)
- Average words per session
- Average session duration (for timed sessions)
- Current streak + longest streak (all time)
- Mood distribution breakdown
- Words-per-week trend line
- Goal progress per project + projected completion date
- Writing frequency calendar (week / month / year toggle — days written vs. not, habit visualization)
- Project filter (all projects vs. specific project)

**Empty state:** Insights need ~7 sessions before they're meaningful. Show encouraging empty states before then (e.g., "Log a few more sessions and your patterns will start to emerge").

### 6. Settings (accessed via gear icon on Dashboard nav bar — not a tab)
**Purpose:** App configuration.

**Elements:**
- Daily reminder notification toggle + time picker
- Default project selection
- Data export (CSV)
- About / credits

### 7. New/Edit Project (Modal Sheet)
**Purpose:** Create or modify a project.

**Elements:**
- Project name
- Word count goal (optional)
- Starting word count ("Words already written" — default 0)
- Archive toggle (edit only)

---

## MVP Scope

### V1 — Ship This
- Dashboard with streak, daily tip, manuscript stack (with build animation), recent sessions, pen FAB with session options
- Log Session flow (fields modal — fast logging)
- Timer Session flow (timer with typewriter tip animation, play/pause/stop, transitions to log fields)
- Projects tab (create, edit, archive, detail view with session history)
- Insights tab (best day, avg words/session, avg duration, streaks, mood breakdown, words-per-week trend, goal progress with projected completion, writing frequency calendar)
- Settings (daily reminder notification, CSV export)
- ~50 bundled writing tips and quotes
- SwiftData persistence, iOS 17+

### Deferred — V2+
- Sound design (typewriter key strikes, carriage return ding, page land, save thud)
- Most productive time of day insight (requires sufficient timed session data)
- iCloud sync / multi-device support
- Home screen widgets (streak, daily progress)
- Apple Watch complication (streak count)
- Social sharing (streak milestones, manuscript completion)
- Custom tip library (user adds their own quotes)
- Onboarding flow / first-run experience
- Haptic feedback on milestones (streak records, goal completion)

---

## Visual Design

Full visual specification is in the companion document: `docs/superpowers/specs/2026-03-20-the-margin-visual-design.md`

Key points integrated here:
- **3-tab bar** (Home, Projects, Insights) — Settings is accessed via gear icon, not a tab
- **Pen FAB** on Home replaces two separate buttons — single amber circle that expands to reveal "Start Session" and "Log Session"
- **"Ink Still Wet" aesthetic**: dark/light themes (Lamplight/Daylight), 4-font typography system (Special Elite, Newsreader, Literata, JetBrains Mono), paper textures with grain/ruled lines/red margin
- **Manuscript stack**: physical pages with jitter, build animation on app open (~1.5s), save-to-stack transition after logging (~2s)
- **Timer screen**: literal typewriter carriage mechanism with paper feed, tip types on ruled paper
- **Log form**: styled as a sheet of ruled paper, typewriter text input with ink variation and micro-jitter
- **Mood icons**: mix of ink-drawn SVG icons (dry nib, stone, seedling) and typographic glyphs (∞, ✦) — not emoji
- **Micro-interactions**: typewriter strike (60ms), ink-wash mood fill (400ms), page land bounce (350ms), carriage return snap (150ms)

---

## Tech Recommendations

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Language** | Swift | Native iOS |
| **UI Framework** | SwiftUI | Declarative, modern, integrates with SwiftData |
| **Persistence** | SwiftData | Lightweight declarative layer over Core Data/SQLite. Handles Project ↔ Session relationships, `@Query` for reactive views, zero boilerplate. iOS 17+. |
| **Charts** | Swift Charts | Apple's native charting framework — bar charts, trend lines, calendar heatmap for insights tab |
| **Notifications** | UserNotifications | Daily reminder scheduling |
| **3rd-party deps** | None for logic. Custom fonts bundled: Special Elite, Newsreader, Literata, JetBrains Mono (all Google Fonts, OFL licensed). |
| **Min deployment** | iOS 17.0 | Required for SwiftData |

### Architecture Notes
- **MVVM pattern** — SwiftUI views backed by observable view models. SwiftData `@Model` classes serve as the model layer.
- **Typewriter animation** — built with a `Timer` publisher feeding characters into a `Text` view. No library needed.
- **Streak calculation** — computed from session dates grouped by calendar day (device timezone), counting consecutive days backward from today.
- **CSV export** — generate in-memory, share via `ShareLink` / UIActivityViewController.
- **Portability** — the data model and business logic (streak calc, insights aggregation) are simple enough to rewrite in Kotlin (Android) or TypeScript (web) without architectural changes. SwiftData is iOS-only but the schema maps directly to any relational database.
