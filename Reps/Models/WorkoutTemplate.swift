import Foundation
import SwiftData

@Model
class WorkoutTemplate {
    var id: UUID
    var name: String
    var notes: String?
    var restDuration: TimeInterval
    var createdAt: Date
    var lastUsedAt: Date?
    @Relationship(deleteRule: .cascade) var exerciseTemplates: [ExerciseTemplate]

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        restDuration: TimeInterval = 90,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        exerciseTemplates: [ExerciseTemplate] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.restDuration = restDuration
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.exerciseTemplates = exerciseTemplates
    }
}

@Model
class ExerciseTemplate {
    var id: UUID
    var order: Int
    var exercise: Exercise
    var restDuration: TimeInterval?
    var supersetGroupID: UUID?
    @Relationship(deleteRule: .cascade) var sets: [SetTemplate]

    init(
        id: UUID = UUID(),
        order: Int,
        exercise: Exercise,
        restDuration: TimeInterval? = nil,
        supersetGroupID: UUID? = nil,
        sets: [SetTemplate] = []
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.restDuration = restDuration
        self.supersetGroupID = supersetGroupID
        self.sets = sets
    }
}

@Model
class SetTemplate {
    var id: UUID
    var order: Int
    var setType: SetType
    var targetReps: Int?
    var targetWeight: Double?
    var targetDuration: TimeInterval?
    var targetDistance: Double?
    var rir: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        order: Int,
        setType: SetType = .working,
        targetReps: Int? = nil,
        targetWeight: Double? = nil,
        targetDuration: TimeInterval? = nil,
        targetDistance: Double? = nil,
        rir: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.order = order
        self.setType = setType
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.targetDuration = targetDuration
        self.targetDistance = targetDistance
        self.rir = rir
        self.notes = notes
    }
}
