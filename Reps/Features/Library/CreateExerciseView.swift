import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var modality: ExerciseModality = .barbell
    @State private var equipment: EquipmentType = .barbell
    @State private var isUnilateral = false
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)

                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Modality", selection: $modality) {
                        ForEach(ExerciseModality.allCases, id: \.self) { mod in
                            Text(mod.displayName).tag(mod)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: modality) { _, newValue in
                        equipment = defaultEquipment(for: newValue)
                    }

                    Picker("Equipment", selection: $equipment) {
                        ForEach(EquipmentType.allCases, id: \.self) { eq in
                            Text(eq.displayName).tag(eq)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Unilateral", isOn: $isUnilateral)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func defaultEquipment(for modality: ExerciseModality) -> EquipmentType {
        switch modality {
        case .barbell:                    return .barbell
        case .dumbbell:                   return .dumbbell
        case .machine:                    return .machine
        case .cable:                      return .cable
        case .bodyweight, .durationOnly:  return .bodyweight
        case .band:                       return .resistanceBand
        case .bodyweightLoaded, .cardio:  return .bodyweight
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let exercise = Exercise(
            name: trimmedName,
            modality: modality,
            muscleGroup: muscleGroup,
            equipment: equipment,
            isUnilateral: isUnilateral,
            isCustom: true,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }
}
