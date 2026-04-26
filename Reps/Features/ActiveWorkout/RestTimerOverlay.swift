import SwiftUI

struct InlineRestTimerRow: View {
    let isActive: Bool
    let endsAt: Date?
    let restDuration: TimeInterval
    let totalDuration: TimeInterval

    @Environment(WorkoutSessionService.self) private var sessionService
    @State private var showingTimerEdit = false
    @State private var timerEditText = ""

    var body: some View {
        if isActive, let endsAt {
            activeTimerRow(endsAt: endsAt)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } else {
            staticSeparator
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    private func activeTimerRow(endsAt: Date) -> some View {
        TimelineView(.animation) { ctx in
            let remaining = max(0, endsAt.timeIntervalSince(ctx.date))
            let progress = totalDuration > 0 ? min(1.0, remaining / totalDuration) : 0.0

            HStack(spacing: 0) {
                Button {
                    sessionService.adjustRestTimer(by: -10)
                } label: {
                    Text("-10")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 60)
                        .frame(maxHeight: .infinity)
                        .background(Color.pink)
                }
                .buttonStyle(.plain)

                ZStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))

                    Rectangle()
                        .fill(Color.accentColor)
                        .scaleEffect(x: CGFloat(progress), anchor: .leading)

                    Text(formatTime(remaining))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    timerEditText = "\(Int(max(0, endsAt.timeIntervalSinceNow)))"
                    showingTimerEdit = true
                }

                Button {
                    sessionService.adjustRestTimer(by: 10)
                } label: {
                    Text("+10")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 60)
                        .frame(maxHeight: .infinity)
                        .background(Color.pink)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 44)
        }
        .alert("Set Timer", isPresented: $showingTimerEdit) {
            TextField("Seconds", text: $timerEditText)
                .keyboardType(.numberPad)
            Button("Set") {
                if let secs = Double(timerEditText), secs > 0 {
                    sessionService.setRestTimerEnd(to: Date().addingTimeInterval(secs))
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter new duration in seconds")
        }
    }

    private var staticSeparator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.12))
                .frame(height: 24)
            Text(formatTime(restDuration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 2)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, ceil(seconds)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
