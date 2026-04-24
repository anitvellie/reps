import Foundation
import SwiftData

@Observable
class TemplateService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func create(name: String, notes: String?, restDuration: TimeInterval) -> WorkoutTemplate {
        let template = WorkoutTemplate(
            name: name,
            notes: notes,
            restDuration: restDuration
        )
        modelContext.insert(template)
        try? modelContext.save()
        return template
    }

    func delete(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }

    @discardableResult
    func addExercise(_ exercise: Exercise, to template: WorkoutTemplate) -> ExerciseTemplate {
        let order = template.exerciseTemplates.count
        let exerciseTemplate = ExerciseTemplate(order: order, exercise: exercise)
        template.exerciseTemplates.append(exerciseTemplate)
        modelContext.insert(exerciseTemplate)
        try? modelContext.save()
        return exerciseTemplate
    }

    func removeExercise(_ exerciseTemplate: ExerciseTemplate, from template: WorkoutTemplate) {
        template.exerciseTemplates.removeAll { $0.id == exerciseTemplate.id }
        modelContext.delete(exerciseTemplate)
        // Reorder remaining exercise templates
        for (index, et) in template.exerciseTemplates.enumerated() {
            et.order = index
        }
        try? modelContext.save()
    }

    @discardableResult
    func addSet(to exerciseTemplate: ExerciseTemplate, type: SetType) -> SetTemplate {
        let order = exerciseTemplate.sets.count
        let setTemplate = SetTemplate(order: order, setType: type)
        exerciseTemplate.sets.append(setTemplate)
        modelContext.insert(setTemplate)
        try? modelContext.save()
        return setTemplate
    }

    func removeSet(_ set: SetTemplate, from exerciseTemplate: ExerciseTemplate) {
        exerciseTemplate.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)
        // Reorder remaining sets
        for (index, s) in exerciseTemplate.sets.enumerated() {
            s.order = index
        }
        try? modelContext.save()
    }
}
