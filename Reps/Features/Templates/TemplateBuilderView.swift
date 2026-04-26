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
            TextField("Notes", text: $notesText, axis: .vertical)
                .lineLimit(2...5)
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
        let sortedSets = exerciseTemplate.sets.sorted(by: { $0.order < $1.order })
        Section {
            ForEach(sortedSets) { setTemplate in
                setRow(setTemplate, in: exerciseTemplate)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            templateService.removeSet(setTemplate, from: exerciseTemplate)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                TemplateRestTimerRow(setTemplate: setTemplate, defaultDuration: appSettings.defaultRestDuration)
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

            Menu {
                ForEach(SetType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        set.setType = type
                    }
                }
            } label: {
                Text(shortLabel(for: set.setType))
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            repsField(for: set)
            weightField(for: set)
            intensityField(for: set)
        }
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
                templateService.addSet(to: exerciseTemplate, type: .working, restDuration: appSettings.defaultRestDuration)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
            }

            Spacer()

            Menu {
                ForEach(SetType.allCases, id: \.self) { setType in
                    Button(setType.displayName) {
                        templateService.addSet(to: exerciseTemplate, type: setType, restDuration: appSettings.defaultRestDuration)
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
}

// MARK: - Template Rest Timer Row

private struct TemplateRestTimerRow: View {
    var setTemplate: SetTemplate
    let defaultDuration: TimeInterval

    @State private var showingEdit = false
    @State private var editText = ""

    private var duration: TimeInterval {
        setTemplate.restDuration ?? defaultDuration
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.12))
                .frame(height: 28)
            Text(formatTime(duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.accentColor)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editText = "\(Int(duration))"
            showingEdit = true
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .alert("Rest Timer", isPresented: $showingEdit) {
            TextField("Seconds", text: $editText)
                .keyboardType(.numberPad)
            Button("Set") {
                if let secs = Double(editText), secs > 0 {
                    setTemplate.restDuration = secs
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter rest duration in seconds")
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, ceil(seconds)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
