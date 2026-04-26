import SwiftUI

struct InlineRestTimerRow: View {
    let isActive: Bool
    let endsAt: Date?
    let restDuration: TimeInterval

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
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    private func activeTimerRow(endsAt: Date) -> some View {
        HStack(spacing: 0) {
            Button {
                sessionService.adjustRestTimer(by: -10)
            } label: {
                Text("-10")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.pink)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            TimelineView(.animation) { ctx in
                let remaining = max(0, endsAt.timeIntervalSince(ctx.date))
                Text(formatTime(remaining))
                    .font(.headline.monospacedDigit())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.pink)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
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
        HStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 1)
            Text(formatTime(restDuration))
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 8)
            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, ceil(seconds)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
