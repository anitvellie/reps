import SwiftUI

struct RestTimerOverlay: View {
    let endsAt: Date
    @Environment(WorkoutSessionService.self) private var sessionService

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Rest")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))

                TimelineView(.animation) { context in
                    let remaining = max(0, endsAt.timeIntervalSince(context.date))
                    Text(formatCountdown(remaining))
                        .font(.system(size: 72, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }

                Button("Skip") {
                    sessionService.skipRestTimer()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
                .foregroundStyle(.white)
            }
        }
    }

    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let total = Int(ceil(seconds))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
