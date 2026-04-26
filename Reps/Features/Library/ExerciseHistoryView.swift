import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    let exercise: Exercise

    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]
    @Environment(AppSettings.self) private var appSettings

    private var recentEntries: [(session: WorkoutSession, log: ExerciseLog)] {
        allSessions
            .filter { $0.status != .inProgress }
            .compactMap { session -> (WorkoutSession, ExerciseLog)? in
                guard let log = session.exerciseLogs.first(where: { $0.exercise.id == exercise.id })
                else { return nil }
                return (session, log)
            }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        Group {
            if recentEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No history yet")
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(recentEntries, id: \.session.id) { entry in
                        ExerciseHistoryRow(session: entry.session, log: entry.log)
                    }
                }
            }
        }
        .navigationTitle("\(exercise.name) History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExerciseHistoryRow: View {
    let session: WorkoutSession
    let log: ExerciseLog
    @Environment(AppSettings.self) private var appSettings

    private var completedSets: [SetLog] {
        log.setLogs.filter(\.isCompleted).sorted { $0.order < $1.order }
    }

    private var bestSet: SetLog? {
        completedSets.max {
            ($0.weight ?? 0) * Double($0.actualReps ?? 0) <
            ($1.weight ?? 0) * Double($1.actualReps ?? 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startedAt, style: .date).fontWeight(.medium)
                Spacer()
                Text("\(completedSets.count) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let best = bestSet {
                HStack(spacing: 16) {
                    if let w = best.weight, let r = best.actualReps {
                        Label("Best: \(fmt(w)) \(best.weightUnit.rawValue) × \(r)", systemImage: "trophy")
                    } else if let r = best.actualReps {
                        Label("Best: \(r) reps", systemImage: "trophy")
                    }

                    let vol = VolumeCalculator.totalVolume(for: log.setLogs)
                    if vol > 0 {
                        Label("\(fmt(vol)) \(appSettings.weightUnit.rawValue)", systemImage: "scalemass")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
