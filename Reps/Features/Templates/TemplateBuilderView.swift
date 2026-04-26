import SwiftUI
import SwiftData

struct TemplateBuilderView: View {
    @Environment(TemplateService.self) private var templateService
    @Environment(AppSettings.self) private var appSettings

    @Bindable var template: WorkoutTemplate

    @State private var notesText: String
    @State private var showingExercisePicker = false

    init(template: WorkoutTemplate) {
        self.template = template
        _notesText = State(initialValue: template.notes ?? "")
    }

    var body: some View {
        List {
            headerSection
            exercisesSection
            addExerciseButton
        }
        .navigationTitle(template.name.isEmpty ? "Template" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                templateService.addExercise(exercise, to: template)
            }
        }
        .onChange(of: notesText) { _, newValue in
            template.notes = newValue.isEmpty ? nil : newValue
        }
    }

    private var headerSection: some View {
        Section {
            TextField("Workout name", text: $template.name)

            restDurationRow

            TextField("Notes", text: $notesText, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private var restDurationRow: some View {
        HStack {
            Text("Rest")
            Spacer()
            Text(formatDuration(template.restDuration))
                .foregroundStyle(.secondary)
            Stepper(
                "",
                value: $template.restDuration,
                in: 15...600,
                step: 15
            )
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var exercisesSection: some View {
        ForEach(template.exerciseTemplates.sorted(by: { $0.order < $1.order })) { exerciseTemplate in
            exerciseSection(exerciseTemplate)
        }
        .onMove { indices, destination in
            var sorted = template.exerciseTemplates.sorted(by: { $0.order < $1.order })
            sorted.move(fromOffsets: indices, toOffset: destination)
            for (index, et) in sorted.enumerated() {
                et.order = index
            }
        }
    }

    @ViewBuilder
    private func exerciseSection(_ exerciseTemplate: ExerciseTemplate) -> some View {
        Section {
            ForEach(exerciseTemplate.sets.sorted(by: { $0.order < $1.order })) { setTemplate in
                setRow(setTemplate, in: exerciseTemplate)
            }
            .onDelete { indexSet in
                let sorted = exerciseTemplate.sets.sorted(by: { $0.order < $1.order })
                for index in indexSet {
                    templateService.removeSet(sorted[index], from: exerciseTemplate)
                }
            }

            addSetButton(for: exerciseTemplate)
        } header: {
            exerciseSectionHeader(exerciseTemplate)
        }
    }

    private func exerciseSectionHeader(_ exerciseTemplate: ExerciseTemplate) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseTemplate.exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(exerciseTemplate.exercise.muscleGroup.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(role: .destructive) {
                templateService.removeExercise(exerciseTemplate, from: template)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .textCase(nil)
    }

    private func setRow(_ set: SetTemplate, in exerciseTemplate: ExerciseTemplate) -> some View {
        HStack(spacing: 8) {
            Text("\(set.order + 1)")
                .frame(width: 24)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Text(shortLabel(for: set.setType))
                .font(.caption.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            repsField(for: set)

            weightField(for: set)

            intensityField(for: set)

            restField(for: set)
        }
    }

    private func restField(for set: SetTemplate) -> some View {
        IntOptionalField(
            placeholder: "Rest",
            value: Binding(
                get: { set.restDuration.map { Int($0) } },
                set: { set.restDuration = $0.map { TimeInterval($0) } }
            )
        )
    }

    private func repsField(for set: SetTemplate) -> some View {
        IntOptionalField(placeholder: "Reps", value: Binding(
            get: { set.targetReps },
            set: { set.targetReps = $0 }
        ))
    }

    private func weightField(for set: SetTemplate) -> some View {
        DoubleOptionalField(placeholder: "Weight", value: Binding(
            get: { set.targetWeight },
            set: { set.targetWeight = $0 }
        ))
    }

    @ViewBuilder
    private func intensityField(for set: SetTemplate) -> some View {
        if appSettings.useRPE {
            IntOptionalField(placeholder: "RPE", value: Binding(
                get: { set.rir },
                set: { set.rir = $0 }
            ))
        } else {
            IntOptionalField(placeholder: "RIR", value: Binding(
                get: { set.rir },
                set: { set.rir = $0 }
            ))
        }
    }

    private func addSetButton(for exerciseTemplate: ExerciseTemplate) -> some View {
        HStack {
            Button {
                templateService.addSet(to: exerciseTemplate, type: .working)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
            }

            Spacer()

            Menu {
                ForEach(SetType.allCases, id: \.self) { setType in
                    Button(setType.displayName) {
                        templateService.addSet(to: exerciseTemplate, type: setType)
                    }
                }
            } label: {
                Image(systemName: "chevron.down.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var addExerciseButton: some View {
        Section {
            Button {
                showingExercisePicker = true
            } label: {
                Label("Add Exercise", systemImage: "plus")
            }
        }
    }

    private func shortLabel(for setType: SetType) -> String {
        switch setType {
        case .working:   return "W"
        case .warmup:    return "WU"
        case .dropSet:   return "D"
        case .failure:   return "F"
        case .restPause: return "RP"
        case .myorep:    return "MR"
        case .backoff:   return "BO"
        case .amrap:     return "AMRAP"
        }
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

