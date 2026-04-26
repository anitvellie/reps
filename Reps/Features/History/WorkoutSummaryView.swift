import SwiftUI

struct WorkoutSummaryView: View {
    let session: WorkoutSession

    @Environment(AppRouter.self) private var appRouter
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        List {
            Section {
                statRow("Duration", formatDuration(session.totalDuration))
                statRow("Total Volume", formatVolume(session.totalVolume))
                statRow("Sets Completed", "\(completedSets)")
                statRow("Exercises", "\(session.exerciseLogs.count)")
            }

            Section("Exercises") {
                ForEach(session.exerciseLogs.sorted { $0.order < $1.order }) { exerciseLog in
                    let completed = exerciseLog.setLogs.filter(\.isCompleted).count
                    let total = exerciseLog.setLogs.count
                    HStack {
                        Text(exerciseLog.exercise.name)
                        Spacer()
                        Text("\(completed)/\(total) sets")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Workout Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    appRouter.dismissSheet()
                }
                .fontWeight(.semibold)
            }
        }
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
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m \(seconds)s" }
        return "\(seconds)s"
    }

    private func formatVolume(_ volume: Double) -> String {
        guard volume > 0 else { return "—" }
        let s = volume.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", volume) : String(format: "%.1f", volume)
        return "\(s) \(appSettings.weightUnit.rawValue)"
    }
}
