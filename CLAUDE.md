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
- `order`, `setType`, `targetReps?`, `targetWeight?`, `targetDuration?`, `targetDistance?`, `rir?`, `notes?`

### WorkoutSession
- `template?`, `name`, `startedAt`, `endedAt?`, `status` (inProgress / completed / abandoned)
- `totalVolume`, `totalDuration`, `healthKitWorkoutID?`, `exerciseLogs: [ExerciseLog]`, `notes?`

### ExerciseLog / SetLog
- SetLog fields: `setType`, `targetReps?`, `actualReps?`, `weight?`, `weightUnit`, `rir?`, `rpe?`, `duration?`, `distance?`, `isCompleted`, `completedAt?`, `notes?`

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
- Default rest timer per template, overridable per exercise

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
WorkoutApp/
├── App/                         # Entry point, AppRouter, environment setup
├── Models/                      # SwiftData model classes + Enums.swift
├── Services/                    # WorkoutSessionService, TemplateService, ExerciseLibraryService, HealthKitService
├── Features/
│   ├── Library/                 # Exercise browser + create custom exercise
│   ├── Templates/               # Template list, builder, set configuration
│   ├── ActiveWorkout/           # Active workout screen, set rows, rest timer
│   ├── History/                 # Workout history list + detail
│   └── Settings/
├── Components/                  # Reusable UI components
└── Utilities/                   # WeightConverter, VolumeCalculator
```

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
