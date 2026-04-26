import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        List {
            Section {
                if let endedAt = session.endedAt {
                    statRow("Date", endedAt.formatted(date: .abbreviated, time: .shortened))
                }
                statRow("Duration", formatDuration(session.totalDuration))
                if session.totalVolume > 0 {
                    statRow("Total Volume", formatVolume(session.totalVolume))
                }
                statRow("Sets Completed", "\(completedSets)")
            }

            ForEach(session.exerciseLogs.sorted { $0.order < $1.order }) { exerciseLog in
                DetailExerciseSection(exerciseLog: exerciseLog)
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var completedSets: Int {
        session.exerciseLogs.flatMap(\.setLogs).filter(\.isCompleted).count
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let t = Int(interval)
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    private func formatVolume(_ v: Double) -> String {
        let s = v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v) : String(format: "%.1f", v)
        return "\(s) \(appSettings.weightUnit.rawValue)"
    }
}

// MARK: - Exercise Section

private struct DetailExerciseSection: View {
    let exerciseLog: ExerciseLog
    @State private var showingHistory = false

    var body: some View {
        Section {
            ForEach(exerciseLog.setLogs.sorted { $0.order < $1.order }) { setLog in
                DetailSetRow(setLog: setLog, modality: exerciseLog.exercise.modality)
            }
        } header: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
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
            }
            .textCase(nil)
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                ExerciseHistoryView(exercise: exerciseLog.exercise)
            }
        }
    }
}

// MARK: - Set Row

private struct DetailSetRow: View {
    let setLog: SetLog
    let modality: ExerciseModality
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        HStack(spacing: 12) {
            Text("\(setLog.order + 1)")
                .frame(width: 20)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Text(shortLabel(for: setLog.setType))
                .font(.caption.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if modality == .cardio || modality == .durationOnly {
                Text(setLog.duration.map(formatSeconds) ?? "—")
                    .font(.subheadline)
            } else {
                setVolumeText
                    .font(.subheadline)
            }

            Spacer()

            intensityLabel

            Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(setLog.isCompleted ? .green : .secondary)
        }
        .opacity(setLog.isCompleted ? 1.0 : 0.5)
    }

    private var setVolumeText: some View {
        Group {
            if let w = setLog.weight, let r = setLog.actualReps {
                Text("\(fmt(w)) \(setLog.weightUnit.rawValue) × \(r)")
            } else if let r = setLog.actualReps {
                Text("\(r) reps")
            } else if let w = setLog.weight {
                Text("\(fmt(w)) \(setLog.weightUnit.rawValue)")
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var intensityLabel: some View {
        if let rir = setLog.rir {
            Text("RIR \(rir)").font(.caption).foregroundStyle(.secondary)
        } else if let rpe = setLog.rpe {
            Text("RPE \(fmt(rpe))").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }

    private func formatSeconds(_ s: TimeInterval) -> String {
        let t = Int(s); let m = t / 60, sec = t % 60
        return m > 0 ? "\(m)m \(sec)s" : "\(sec)s"
    }

    private func shortLabel(for t: SetType) -> String {
        switch t {
        case .working: return "W"; case .warmup: return "WU"; case .dropSet: return "D"
        case .failure: return "F"; case .restPause: return "RP"; case .myorep: return "MR"
        case .backoff: return "BO"; case .amrap: return "AMRAP"
        }
    }
}
