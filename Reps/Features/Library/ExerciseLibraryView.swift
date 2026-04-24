import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var showingCreateExercise = false

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscleGroup == nil || exercise.muscleGroup == selectedMuscleGroup
            return matchesSearch && matchesMuscle
        }
    }

    private var isGrouped: Bool {
        searchText.isEmpty && selectedMuscleGroup == nil
    }

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        let groups = Dictionary(grouping: filtered, by: \.muscleGroup)
        return MuscleGroup.allCases
            .compactMap { group -> (MuscleGroup, [Exercise])? in
                guard let items = groups[group], !items.isEmpty else { return nil }
                return (group, items.sorted { $0.name < $1.name })
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            muscleGroupChips

            if isGrouped {
                List {
                    ForEach(groupedExercises, id: \.0) { group, items in
                        Section(group.displayName) {
                            ForEach(items) { exercise in
                                exerciseRow(exercise)
                            }
                        }
                    }
                }
            } else {
                List {
                    ForEach(filtered) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
        }
        .navigationTitle("Library")
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateExercise) {
            CreateExerciseView()
        }
    }

    @ViewBuilder
    private func exerciseRow(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
            Text("\(exercise.muscleGroup.displayName) · \(exercise.modality.displayName)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if exercise.isCustom {
                Button(role: .destructive) {
                    modelContext.delete(exercise)
                    try? modelContext.save()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var muscleGroupChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", isSelected: selectedMuscleGroup == nil) {
                    selectedMuscleGroup = nil
                }
                ForEach(MuscleGroup.allCases, id: \.self) { group in
                    chip(label: group.displayName, isSelected: selectedMuscleGroup == group) {
                        if selectedMuscleGroup == group {
                            selectedMuscleGroup = nil
                        } else {
                            selectedMuscleGroup = group
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
