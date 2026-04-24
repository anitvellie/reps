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

            Section("About") {
                LabeledContent("App", value: "Reps")
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
    }
}
