import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        @Bindable var appSettings = appSettings
        Form {
            Section("Units") {
                Picker("Weight Unit", selection: $appSettings.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Logging") {
                Toggle("Use RPE instead of RIR", isOn: $appSettings.useRPE)
            }

            Section("Rest Timer") {
                HStack {
                    Text("Default Rest")
                    Spacer()
                    Text(formatDuration(appSettings.defaultRestDuration))
                        .foregroundStyle(.secondary)
                    Stepper(
                        "",
                        value: $appSettings.defaultRestDuration,
                        in: 15...600,
                        step: 15
                    )
                    .labelsHidden()
                }
            }

            Section("About") {
                LabeledContent("App", value: "Reps")
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let minutes = total / 60
        let secs = total % 60
        if minutes > 0 && secs > 0 {
            return "\(minutes)m \(secs)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(secs)s"
        }
    }
}
