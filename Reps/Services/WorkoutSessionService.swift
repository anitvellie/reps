import Foundation
import SwiftData

@Observable
class WorkoutSessionService {
    private let modelContext: ModelContext
    private let healthKitService: HealthKitService

    var activeSession: WorkoutSession?
    var restTimerEndsAt: Date?
    var isRestTimerRunning: Bool = false

    init(modelContext: ModelContext, healthKitService: HealthKitService) {
        self.modelContext = modelContext
        self.healthKitService = healthKitService
    }

    @discardableResult
    func startWorkout(from template: WorkoutTemplate) -> WorkoutSession {
        // TODO: Phase 2 — build ExerciseLogs and SetLogs from template
        let session = WorkoutSession(
            name: template.name,
            startedAt: Date(),
            status: .inProgress
        )

        // TODO: Phase 2 — populate exerciseLogs from template.exerciseTemplates

        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session

        // TODO: Phase 2 — call healthKitService.startWorkout(date:)

        return session
    }

    func completeSet(_ setLog: SetLog, in session: WorkoutSession) {
        // TODO: Phase 2 — mark set as completed, calculate volume, trigger rest timer
        setLog.isCompleted = true
        setLog.completedAt = Date()
        try? modelContext.save()
    }

    func finishWorkout(_ session: WorkoutSession) {
        // TODO: Phase 2 — calculate totalDuration, totalVolume, save to HealthKit
        session.endedAt = Date()
        session.status = .completed
        if let start = Optional(session.startedAt) {
            session.totalDuration = session.endedAt?.timeIntervalSince(start) ?? 0
        }
        activeSession = nil
        isRestTimerRunning = false
        restTimerEndsAt = nil
        try? modelContext.save()

        // TODO: Phase 2 — call healthKitService.endWorkout(date:)
    }

    func abandonWorkout(_ session: WorkoutSession) {
        // TODO: Phase 2 — mark abandoned, cancel HealthKit workout
        session.endedAt = Date()
        session.status = .abandoned
        activeSession = nil
        isRestTimerRunning = false
        restTimerEndsAt = nil
        try? modelContext.save()
    }

    func skipRestTimer() {
        // TODO: Phase 2 — cancel the active rest timer
        isRestTimerRunning = false
        restTimerEndsAt = nil
    }
}
