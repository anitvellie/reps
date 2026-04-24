import Foundation
import SwiftData

@Model
class WorkoutSession {
    var id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?
    var status: WorkoutStatus
    var totalVolume: Double
    var totalDuration: TimeInterval
    var healthKitWorkoutID: UUID?
    var notes: String?
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]

    init(
        id: UUID = UUID(),
        name: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: WorkoutStatus = .inProgress,
        totalVolume: Double = 0,
        totalDuration: TimeInterval = 0,
        healthKitWorkoutID: UUID? = nil,
        notes: String? = nil,
        exerciseLogs: [ExerciseLog] = []
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.totalVolume = totalVolume
        self.totalDuration = totalDuration
        self.healthKitWorkoutID = healthKitWorkoutID
        self.notes = notes
        self.exerciseLogs = exerciseLogs
    }
}

@Model
class ExerciseLog {
    var id: UUID
    var order: Int
    var exercise: Exercise
    @Relationship(deleteRule: .cascade) var setLogs: [SetLog]

    init(
        id: UUID = UUID(),
        order: Int,
        exercise: Exercise,
        setLogs: [SetLog] = []
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.setLogs = setLogs
    }
}

@Model
class SetLog {
    var id: UUID
    var order: Int
    var setType: SetType
    var targetReps: Int?
    var actualReps: Int?
    var weight: Double?
    var weightUnit: WeightUnit
    var rir: Int?
    var rpe: Double?
    var duration: TimeInterval?
    var distance: Double?
    var isCompleted: Bool
    var completedAt: Date?
    var notes: String?

    init(
        id: UUID = UUID(),
        order: Int,
        setType: SetType = .working,
        targetReps: Int? = nil,
        actualReps: Int? = nil,
        weight: Double? = nil,
        weightUnit: WeightUnit = .kg,
        rir: Int? = nil,
        rpe: Double? = nil,
        duration: TimeInterval? = nil,
        distance: Double? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.order = order
        self.setType = setType
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.weight = weight
        self.weightUnit = weightUnit
        self.rir = rir
        self.rpe = rpe
        self.duration = duration
        self.distance = distance
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notes = notes
    }
}
