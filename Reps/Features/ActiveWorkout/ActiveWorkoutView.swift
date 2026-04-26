import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(WorkoutSessionService.self) private var sessionService
    @Environment(AppSettings.self) private var appSettings
    @Environment(AppRouter.self) private var appRouter

    var session: WorkoutSession

    @State private var path: [WorkoutSession] = []
    @State private var showingAbandonAlert = false
    @State private var showingExercisePicker = false

    var body: some View {
        NavigationStack(path: $path) {
            exerciseList
                .navigationTitle(session.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: WorkoutSession.self) { completed in
                    WorkoutSummaryView(session: completed)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Abandon") {
                            showingAbandonAlert = true
                        }
                        .foregroundStyle(.red)
                    }
                    ToolbarItem(placement: .principal) {
                        WorkoutStopwatch(startedAt: session.startedAt)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Finish") {
                            sessionService.finishWorkout(session)
                            path.append(session)
                        }
                        .fontWeight(.semibold)
                    }
                }
                .alert("Abandon Workout?", isPresented: $showingAbandonAlert) {
                    Button("Abandon", role: .destructive) {
                        sessionService.abandonWorkout(session)
                        appRouter.dismissSheet()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Your progress will be saved but marked as abandoned.")
                }
                .sheet(isPresented: $showingExercisePicker) {
                    ExercisePickerView { exercise in
                        sessionService.addExercise(exercise, to: session)
                    }
                }
        }
    }

    private var exerciseList: some View {
        List {
            ForEach(session.exerciseLogs.sorted { $0.order < $1.order }) { exerciseLog in
                ActiveExerciseSection(exerciseLog: exerciseLog, session: session)
            }

            Section {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
    }
}

// MARK: - Exercise Section

private struct ActiveExerciseSection: View {
    @Environment(WorkoutSessionService.self) private var sessionService

    var exerciseLog: ExerciseLog
    var session: WorkoutSession

    @State private var showingHistory = false

    var body: some View {
        Section {
            setRows
            Button {
                sessionService.addSet(to: exerciseLog, in: session)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
            }
        } header: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exerciseLog.exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(exerciseLog.exercise.muscleGroup.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.accentColor)
                }
                completedBadge
            }
            .textCase(nil)
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                ExerciseHistoryView(exercise: exerciseLog.exercise)
            }
        }
    }

    @ViewBuilder
    private var setRows: some View {
        let sortedSets = exerciseLog.setLogs.sorted { $0.order < $1.order }
        ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, setLog in
            ActiveSetRow(
                setLog: setLog,
                setNumber: setLog.order + 1,
                modality: exerciseLog.exercise.modality,
                session: session
            )

            let isActiveTimer = sessionService.isRestTimerRunning && sessionService.lastCompletedSetID == setLog.id
            if index < sortedSets.count - 1 || isActiveTimer {
                InlineRestTimerRow(
                    isActive: isActiveTimer,
                    endsAt: sessionService.restTimerEndsAt,
                    restDuration: setLog.restDuration ?? exerciseLog.restDuration
                )
            }
        }
    }

    private var completedBadge: some View {
        let completed = exerciseLog.setLogs.filter(\.isCompleted).count
        let total = exerciseLog.setLogs.count
        return Text("\(completed)/\(total)")
            .font(.caption.bold())
            .foregroundStyle(total > 0 && completed == total ? .green : .secondary)
    }
}

// MARK: - Set Row

private struct ActiveSetRow: View {
    @Bindable var setLog: SetLog
    let setNumber: Int
    let modality: ExerciseModality
    var session: WorkoutSession

    @Environment(WorkoutSessionService.self) private var sessionService
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .frame(width: 20)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            setTypeBadge

            if modality == .cardio || modality == .durationOnly {
                durationField
            } else {
                weightField
                repsField
            }

            intensityField

            completeButton
        }
        .opacity(setLog.isCompleted ? 0.5 : 1.0)
    }

    private var setTypeBadge: some View {
        Text(shortLabel(for: setLog.setType))
            .font(.caption.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var weightField: some View {
        DoubleOptionalField(
            placeholder: modality == .bodyweightLoaded ? "+\(appSettings.weightUnit.rawValue)" : appSettings.weightUnit.rawValue,
            value: Binding(get: { setLog.weight }, set: { setLog.weight = $0 })
        )
        .disabled(setLog.isCompleted)
    }

    private var repsField: some View {
        IntOptionalField(
            placeholder: "Reps",
            value: Binding(get: { setLog.actualReps }, set: { setLog.actualReps = $0 })
        )
        .disabled(setLog.isCompleted)
    }

    private var durationField: some View {
        DoubleOptionalField(
            placeholder: "Secs",
            value: Binding(get: { setLog.duration }, set: { setLog.duration = $0 })
        )
        .disabled(setLog.isCompleted)
    }

    @ViewBuilder
    private var intensityField: some View {
        if appSettings.useRPE {
            DoubleOptionalField(
                placeholder: "RPE",
                value: Binding(get: { setLog.rpe }, set: { setLog.rpe = $0 })
            )
            .disabled(setLog.isCompleted)
        } else {
            IntOptionalField(
                placeholder: "RIR",
                value: Binding(get: { setLog.rir }, set: { setLog.rir = $0 })
            )
            .disabled(setLog.isCompleted)
        }
    }

    private var completeButton: some View {
        Button {
            guard !setLog.isCompleted else { return }
            sessionService.completeSet(setLog, in: session)
        } label: {
            Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(setLog.isCompleted ? .green : .secondary)
                .font(.title2)
        }
        .buttonStyle(.plain)
    }

    private func shortLabel(for setType: SetType) -> String {
        switch setType {
        case .working:   return "W"
        case .warmup:    return "WU"
        case .dropSet:   return "D"
        case .failure:   return "F"
        case .restPause: return "RP"
        case .myorep:    return "MR"
        case .backoff:   return "BO"
        case .amrap:     return "AMRAP"
        }
    }
}

// MARK: - Stopwatch

private struct WorkoutStopwatch: View {
    let startedAt: Date

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { context in
            Text(formatElapsed(context.date.timeIntervalSince(startedAt)))
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
