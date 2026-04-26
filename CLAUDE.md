# Reps — Workout Tracking App

Native iOS workout tracking app built with SwiftUI + SwiftData.

---

## Tech Stack

- **SwiftUI + SwiftData** (iOS 17+) — no third-party dependencies
- **HealthKit** — `HKWorkoutBuilder` on iOS for writing workout records
- **MVVM** — domain services injected via SwiftUI environment
- **UserNotifications** — rest timer fires when app is backgrounded

---

## Data Models

### Exercise (shared library)
- `id`, `name`, `modality` (ExerciseModality), `muscleGroup` (MuscleGroup), `equipment` (EquipmentType)
- `isUnilateral: Bool`, `isCustom: Bool`, `notes: String?`, `createdAt: Date`

### WorkoutTemplate
- `id`, `name`, `notes?`, `restDuration` (default), `createdAt`, `lastUsedAt`
- `exerciseTemplates: [ExerciseTemplate]` (ordered)

### ExerciseTemplate
- `exercise`, `order`, `restDuration?` (overrides template default), `sets: [SetTemplate]`, `supersetGroupID?`

### SetTemplate
- `order`, `setType`, `targetReps?`, `targetWeight?`, `targetDuration?`, `targetDistance?`, `rir?`, `notes?`, `restDuration?`

### WorkoutSession
- `template?`, `name`, `startedAt`, `endedAt?`, `status` (inProgress / completed / abandoned)
- `totalVolume`, `totalDuration`, `healthKitWorkoutID?`, `exerciseLogs: [ExerciseLog]`, `notes?`

### ExerciseLog / SetLog
- SetLog fields: `setType`, `targetReps?`, `actualReps?`, `weight?`, `weightUnit`, `rir?`, `rpe?`, `duration?`, `distance?`, `isCompleted`, `completedAt?`, `notes?`, `restDuration?`

---

## Enums

```swift
enum ExerciseModality { barbell, dumbbell, machine, cable, bodyweight, bodyweightLoaded, cardio, durationOnly, band }
enum SetType { working, warmup, dropSet, failure, restPause, myorep, backoff, amrap }
enum WeightUnit { kg, lb }
enum WorkoutStatus { inProgress, completed, abandoned }
enum MuscleGroup { chest, back, shoulders, biceps, triceps, forearms, quads, hamstrings, glutes, calves, core, fullBody, other }
enum EquipmentType { barbell, dumbbell, machine, cable, bodyweight, resistanceBand, kettlebell, other }
```

---

## Set Logging Fields

Per set: `targetReps`, `actualReps`, `weight`, `weightUnit` (kg/lb), `RIR` (0–5), optional `RPE` (6.0–10.0), `duration`, `distance`, `notes`.

---

## V1 Phases

### Phase 0 — Foundation
- Xcode project setup, SwiftData models, all enums
- Exercise library seed data (~100 exercises, each with muscleGroup tagged)
- App settings: weight unit (kg/lb), RIR vs RPE preference

### Phase 1 — Exercise Library & Template Builder
- Exercise library browser — search, filter by muscle group / equipment
- **Create custom exercise** — pick modality (from all ExerciseModality types), tag muscle group (including fullBody and other as fallbacks), mark unilateral if applicable
- All exercises (bundled and custom) carry a `muscleGroup` attribute
- Create / edit / delete workout templates
- Configure sets per exercise: type, target reps/weight, rest duration
- Default rest timer per template, overridable per set (leave blank to inherit template default)

### Phase 2 — Active Workout Engine
- Start workout from template → creates `WorkoutSession`
- Global workout stopwatch (always visible)
- Set rows: weight, reps, RIR/RPE fields + complete button
- **Auto rest timer** after each set completion — countdown overlay, skip button, haptic + sound on end
- Timer uses `Date`-target approach (not decrement counter) — background-safe; local notification fallback via `UNUserNotificationCenter`
- Add sets / exercises on the fly, edit any field mid-workout
- Ad-hoc workout (no template)

### Phase 3 — Completion & History
- Finish workout → summary screen (duration, total volume, sets completed)
- Persist `WorkoutSession` to SwiftData (also saved eagerly after every set — never lose data on OS kill)
- **HealthKit write**: workout type, start/end time, estimated calories
- Workout history list + full workout detail view
- Exercise history: last 5 sessions for a given exercise (accessible from library and active workout)

### Phase 4 — MVP Readiness
- HealthKit permission rationale screen + onboarding flow
- Resume interrupted workout on relaunch (detect `inProgress` session at launch)
- App icon + launch screen
- TestFlight build

---

## Architecture Notes

- `WorkoutSessionService` owns the active workout state machine — set completion, rest timer, HealthKit writes
- `HealthKitService` is a fully isolated boundary — nothing else in the app imports HealthKit directly
- Timer pattern: store `restEndsAt: Date`, drive UI with `TimelineView`, fire completion with `Task.sleep(until:)`
- `AppRouter` (`@Observable`) owns `NavigationPath` + active sheet state, injected via environment
- All services injected at root via `.environment()`

### File Structure
```
Reps/
├── App/                         # RepsApp, AppRouter, ContentView
├── Models/                      # SwiftData model classes + Enums.swift + AppSettings
├── Services/                    # WorkoutSessionService, TemplateService, ExerciseLibraryService, HealthKitService
├── Features/
│   ├── Library/                 # ExerciseLibraryView, CreateExerciseView
│   ├── Templates/               # TemplateListView, TemplateBuilderView, ExercisePickerView
│   ├── ActiveWorkout/           # (Phase 2)
│   ├── History/                 # (Phase 3)
│   └── Settings/                # SettingsView
├── Components/                  # Reusable UI (none yet)
└── Utilities/                   # WeightConverter, VolumeCalculator
```

---

## Established Patterns (Phases 0–1)

### SwiftUI / SwiftData conventions
- Services are `@Observable` classes, accessed in views via `@Environment(ServiceType.self)` — never `@EnvironmentObject`
- When a binding is needed from an `@Observable` service/model, declare `@Bindable var x = x` locally inside `body` (iOS 17 pattern)
- `@Query` is used directly in views for SwiftData fetching — no extra ViewModel wrapper needed
- `String?` model fields can't bind to `TextField` directly — use a local `@State var text: String` initialised from the optional, with `.onChange` to write back
- Delete pattern: `modelContext.delete(object)` then `try? modelContext.save()` — services also call save after mutations
- Services take `ModelContext` in their `init` (obtained from `container.mainContext` at app startup) — never `ModelContainer`
- `xcodegen generate` must be re-run after adding any new Swift files since `project.yml` uses a directory glob for sources

### Navigation
- `TemplateListView` owns its own `NavigationStack` + `@State var path: NavigationPath` so it can programmatically push `TemplateBuilderView` immediately after creating a new template
- `ExerciseLibraryView` is wrapped in a `NavigationStack` by `ContentView`
- `AppRouter` is now active — `AppRouter.present(.activeWorkout(session))` triggers a `.fullScreenCover` in `ContentView` via `@Bindable var router = appRouter` + `$router.activeSheet`
- Active workout is **not** part of any tab's `NavigationStack` — it's a root-level full-screen cover

### Reusable UI patterns
- Muscle group filter chips (horizontal `ScrollView` of capsule `Button`s, "All" chip first, tap active chip to deselect) — implemented in both `ExerciseLibraryView` and `ExercisePickerView`; if needed a third time, extract to `Components/MuscleGroupChipRail.swift`
- `IntOptionalField` and `DoubleOptionalField` live in `Components/OptionalFields.swift` — used by both `TemplateBuilderView` and `ActiveWorkoutView`; `DoubleOptionalField` formats whole numbers without a trailing `.0`

### HealthKit
- Only entitlement needed: `com.apple.developer.healthkit: true`
- Do NOT add `com.apple.developer.healthkit.access: health-records` — that requires special Apple approval and breaks automatic provisioning
- All HealthKit code lives exclusively in `HealthKitService.swift`

---

## Established Patterns (Phase 2)

### SwiftData model additions
- Added `restDuration: TimeInterval` to `ExerciseLog` — resolved once at workout-start from `exerciseTemplate.restDuration ?? template.restDuration`; serves as the fallback for ad-hoc sets added mid-workout
- Added `restDuration: TimeInterval?` to `SetLog` — resolved at workout-start per set; nil means fall back to `exerciseLog.restDuration ?? 90` at completion time (allows graceful schema evolution for existing records)
- `WorkoutSession` has no direct `template` reference (the template name is copied to `session.name`); resolved rest durations on `SetLog` are the only template data carried forward
- `actualReps` is pre-filled from `targetReps` when creating `SetLog` from a `SetTemplate` — user can override before completing the set
- `weightUnit` defaults to `.kg` when creating `SetLog` from a template (AppSettings is not injected into `WorkoutSessionService`); the display label in set rows follows `appSettings.weightUnit`

### `@Observable` service patterns
- Use `@ObservationIgnored` for internal properties that should not trigger SwiftUI observation: `Task<Void, Never>?` (rest timer handle), `HKWorkoutBuilder?` (HealthKit builder)
- Services are not `@MainActor` — use `await MainActor.run { }` inside async `Task` closures when updating `@Observable` properties that drive UI (e.g., clearing `isRestTimerRunning` when the rest timer fires)

### Rest timer implementation
- `restTimerTask: Task<Void, Never>?` stored with `@ObservationIgnored`
- Sleep pattern: `try? await Task.sleep(until: ContinuousClock.now + .seconds(duration), clock: .continuous)` — the `until:` form wakes immediately if the deadline is already past (handles app returning from background)
- Cancellation check after sleep: `guard !Task.isCancelled else { return }` — `try?` swallows `CancellationError` so the guard is required to prevent the completion handler from firing
- `UNTimeIntervalNotificationTrigger` interval must be `> 0` — clamp with `max(1, date.timeIntervalSinceNow)` before creating the trigger

### HealthKit
- `HKWorkoutBuilder` completion-handler methods (`beginCollection`, `endCollection`, `finishWorkout`) have no native async overloads — wrap each in `withCheckedThrowingContinuation`
- `workoutBuilder` is stored on `HealthKitService` between `startWorkout(date:)` and `endWorkout(date:)` calls; cleared with `defer { workoutBuilder = nil }` in `endWorkout`

### Active workout UI
- `@Bindable var setLog: SetLog` declared as a stored property on `ActiveSetRow` (not in `body`) — works for SwiftData `@Model` classes passed as view parameters
- Set row fields are modality-driven: `cardio`/`durationOnly` show a duration field; all others show weight + reps; `bodyweightLoaded` weight placeholder shows "+kg"/"+lb"
- Completed sets rendered at 50% opacity; complete button is a no-op if `setLog.isCompleted` is already true

### Template list — starting workouts
- Per-template "Start": visible `play.circle.fill` button on the right of each row (plain `Button`, not swipe action)
- Row no longer uses `NavigationLink(value:)` — a plain `.buttonStyle(.plain)` `Button` on the label area navigates by appending to the path; the play button starts the workout
- Ad-hoc workout: `+` menu in toolbar with "New Template" and "Empty Workout" options; also surfaced as a button in the empty state
- Both flows call `workoutSessionService.start…`, then `appRouter.present(.activeWorkout(session))`
- Templates tab is the first tab in `ContentView`, renamed "Workouts"

---

## Established Patterns (Phase 2 — Post-launch polish)

### Inline rest timer
- `InlineRestTimerRow` lives in `RestTimerOverlay.swift` (repurposed; the full-screen overlay is gone)
- **Static state** (between sets, timer not active): thin horizontal lines + M:SS text in `Color.accentColor`; shown between every adjacent pair of sets via `index < count - 1 || isActiveTimer` condition
- **Active state** (after set completion): pink `-10` | `Color.accentColor` countdown (`TimelineView(.animation)`) | pink `+10`; row goes edge-to-edge with `.listRowInsets(EdgeInsets())`
- Tap the countdown → `.alert` with `TextField(.numberPad)` to enter new seconds; commits via `sessionService.setRestTimerEnd(to:)`
- `lastCompletedSetID: UUID?` on `WorkoutSessionService` (observable) identifies which separator is active — set in `completeSet`, cleared in `cancelRestTimer` and the timer-fire handler
- `adjustRestTimer(by delta: TimeInterval)` and `setRestTimerEnd(to date: Date)` both cancel the existing task/notification and restart via `startRestTimerTask(endsAt:)` private helper (extracted to avoid duplication across three call sites)
- Separator after the last set only renders when that set is the active timer

---

## Phase 2 Implementation Notes

### Starting a workout (`WorkoutSessionService.startWorkout`)
- Copy `ExerciseTemplate → ExerciseLog` and `SetTemplate → SetLog`, carrying over all target values (`targetReps`, `targetWeight`, `rir`, `setType`, etc.)
- Set `template.lastUsedAt = Date()` on the source template
- Insert the `WorkoutSession` (and all child logs) into `modelContext` and save immediately — session must be persisted before the user completes any sets
- Set `activeSession` on the service so the UI can react

### Rest timer
- Store `restTimerEndsAt: Date` on `WorkoutSessionService` (already stubbed)
- Drive countdown UI with `TimelineView(.animation)` — compute `remaining = restTimerEndsAt.timeIntervalSinceNow` on each tick
- Fire completion via `Task { try? await Task.sleep(until: restTimerEndsAt, clock: .continuous) }` — cancel the task on `skipRestTimer()`
- Schedule a `UNUserNotificationCenter` local notification at `restTimerEndsAt` as background fallback; cancel it when the timer is skipped or app is foregrounded
- Rest duration resolution chain (evaluated at workout-start, stored on `SetLog`): `setTemplate.restDuration ?? exerciseTemplate.restDuration ?? template.restDuration`
- At set completion: use `setLog.restDuration ?? exerciseLog.restDuration ?? 90`
- Between exercises: no special handling — the timer started by the last set of exercise N keeps running while the user navigates to exercise N+1

### Set completion flow
1. Mark `setLog.isCompleted = true`, `setLog.completedAt = Date()`
2. Save to SwiftData immediately (crash-safety)
3. Recalculate `session.totalVolume` via `VolumeCalculator.totalVolume(for:)`
4. Start the rest timer with the appropriate duration
5. Haptic feedback: `UIImpactFeedbackGenerator(style: .medium).impactOccurred()`

### Active workout UI behaviour per modality
- `cardio` / `durationOnly`: hide weight field, show duration field instead
- `bodyweight`: weight field is optional (show but not required)
- `bodyweightLoaded`: weight field represents added load
- All others: weight + reps fields both shown

### RIR vs RPE
- `SetLog` has both `rir: Int?` and `rpe: Double?` fields — populate only the one matching `appSettings.useRPE`
- In the active workout UI, show either "RIR" or "RPE" label based on `appSettings.useRPE`

### Saving eagerly
- Call `try? modelContext.save()` after every set completion — not just at workout end
- This ensures an OS kill mid-workout loses at most the current in-progress set

### Presenting the active workout
- Use `AppRouter.present(.activeWorkout(session))` to show as `.fullScreenCover` from the root
- The active workout screen should not be part of any tab's `NavigationStack`

---

## Established Patterns (Phase 3)

### Workout completion flow
- `ActiveWorkoutView` owns `@State private var path: [WorkoutSession] = []` and uses `NavigationStack(path: $path)`
- "Finish" button calls `sessionService.finishWorkout(session)` then `path.append(session)` — does **not** call `appRouter.dismissSheet()`
- `WorkoutSummaryView` is the `.navigationDestination(for: WorkoutSession.self)` destination; its "Done" button calls `appRouter.dismissSheet()` via `@Environment(AppRouter.self)`
- `navigationBarBackButtonHidden(true)` on `WorkoutSummaryView` prevents back-navigation into the finished workout list

### History queries
- `@Query(sort: \WorkoutSession.startedAt, order: .reverse)` fetches all sessions; `.inProgress` sessions filtered out in-memory (`allSessions.filter { $0.status != .inProgress }`) — avoids complex `#Predicate` on an enum
- `ExerciseHistoryView` uses the same full-query pattern, then `compactMap` to pair sessions with the matching `ExerciseLog`, then `.prefix(5)`

### Exercise history access points (three locations)
- **Library tab**: `NavigationLink(value: exercise)` on each row + `.navigationDestination(for: Exercise.self)` on `ExerciseLibraryView`
- **Active workout**: `clock.arrow.circlepath` button in `ActiveExerciseSection` header → `.sheet` presenting `NavigationStack { ExerciseHistoryView(exercise:) }`
- **Workout detail**: same clock button pattern in `DetailExerciseSection` header

### HealthKit calorie estimate
- `workoutStartDate: Date?` stored `@ObservationIgnored` on `HealthKitService` alongside `workoutBuilder`; both cleared via `defer { workoutBuilder = nil; workoutStartDate = nil }` in `endWorkout`
- Calorie add uses `withCheckedContinuation` (non-throwing) so errors never propagate — the continuation always resumes regardless of failure
- Estimate formula: MET 5.0 × 70 kg × duration_hours; `HKQuantityType(.activeEnergyBurned)` added to `typesToShare` in `requestAuthorization`
- Calorie sample is added to the builder **before** `endCollection` / `finishWorkout`

### History deletion
- Swipe-to-delete on `WorkoutHistoryView` rows only: `modelContext.delete(session)` + `try? modelContext.save()`
- No delete affordance in `WorkoutDetailView` — deletion is a list-level action

---

## Long-Term Roadmap (Post-V1)

- **Personal Record detection** — flag a `SetLog` as a PR when `weight × reps` exceeds the prior best for that exercise; surface in active workout and history
- **Apple Watch companion** — `HKWorkoutSession` (watchOS target), live heart rate, calorie tracking from watch sensor
- **Live Activity / Dynamic Island** — rest timer visible outside the app
- **Volume progression charts** — SwiftCharts, 1RM estimation (Epley formula)
- **CloudKit sync** — low-lift upgrade from SwiftData local store
- **Program/mesocycle builder** — schedule workouts across weeks, auto-progression rules
- **Dark mode + full accessibility** — Dynamic Type, VoiceOver labels, high-contrast support
- **Calories from Apple Watch HR** — compute active energy burn from heart rate data during workout
