import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext

    private var sessions: [WorkoutSession] {
        allSessions.filter { $0.status != .inProgress }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(value: session) {
                            HistoryRow(session: session)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(session)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationDestination(for: WorkoutSession.self) { session in
            WorkoutDetailView(session: session)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No workouts yet")
                .foregroundStyle(.secondary)
        }
    }
}

private struct HistoryRow: View {
    let session: WorkoutSession
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.name).fontWeight(.medium)
                if session.status == .abandoned {
                    Text("Abandoned")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
                Text(session.startedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label(formatDuration(session.totalDuration), systemImage: "clock")
                if session.totalVolume > 0 {
                    Label(formatVolume(session.totalVolume), systemImage: "scalemass")
                }
                Label("\(completedSets) sets", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var completedSets: Int {
        session.exerciseLogs.flatMap(\.setLogs).filter(\.isCompleted).count
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let t = Int(interval)
        let h = t / 3600, m = (t % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "<1m"
    }

    private func formatVolume(_ v: Double) -> String {
        let s = v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v) : String(format: "%.1f", v)
        return "\(s) \(appSettings.weightUnit.rawValue)"
    }
}
