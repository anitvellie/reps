import Foundation
import SwiftData
import UIKit
import UserNotifications

@Observable
class WorkoutSessionService {
    private let modelContext: ModelContext
    private let healthKitService: HealthKitService

    var activeSession: WorkoutSession?
    var restTimerEndsAt: Date?
    var isRestTimerRunning: Bool = false
    var lastCompletedSetID: UUID?

    @ObservationIgnored private var restTimerTask: Task<Void, Never>?

    init(modelContext: ModelContext, healthKitService: HealthKitService) {
        self.modelContext = modelContext
        self.healthKitService = healthKitService
    }

    @discardableResult
    func startWorkout(from template: WorkoutTemplate) -> WorkoutSession {
        requestNotificationPermission()

        let session = WorkoutSession(name: template.name, startedAt: Date(), status: .inProgress)
        template.lastUsedAt = Date()

        for (i, et) in template.exerciseTemplates.sorted(by: { $0.order < $1.order }).enumerated() {
            let effectiveRest = et.restDuration ?? template.restDuration
            let exerciseLog = ExerciseLog(order: i, exercise: et.exercise, restDuration: effectiveRest)
            for (j, st) in et.sets.sorted(by: { $0.order < $1.order }).enumerated() {
                let setLog = SetLog(
                    order: j,
                    setType: st.setType,
                    targetReps: st.targetReps,
                    actualReps: st.targetReps,
                    weight: st.targetWeight,
                    weightUnit: .kg,
                    restDuration: st.restDuration ?? effectiveRest
                )
                modelContext.insert(setLog)
                exerciseLog.setLogs.append(setLog)
            }
            modelContext.insert(exerciseLog)
            session.exerciseLogs.append(exerciseLog)
        }

        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session

        Task { try? await healthKitService.startWorkout(date: session.startedAt) }

        return session
    }

    @discardableResult
    func startAdHocWorkout(name: String = "Workout") -> WorkoutSession {
        requestNotificationPermission()

        let session = WorkoutSession(name: name, startedAt: Date(), status: .inProgress)
        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session

        Task { try? await healthKitService.startWorkout(date: session.startedAt) }

        return session
    }

    func completeSet(_ setLog: SetLog, in session: WorkoutSession) {
        setLog.isCompleted = true
        setLog.completedAt = Date()

        session.totalVolume = VolumeCalculator.totalVolume(for: session.exerciseLogs.flatMap { $0.setLogs })
        try? modelContext.save()

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let exerciseLog = session.exerciseLogs.first { $0.setLogs.contains { $0.id == setLog.id } }
        lastCompletedSetID = setLog.id
        startRestTimer(duration: setLog.restDuration ?? exerciseLog?.restDuration ?? 90)
    }

    func addSet(to exerciseLog: ExerciseLog, type: SetType = .working, in session: WorkoutSession) {
        let nextOrder = (exerciseLog.setLogs.map(\.order).max() ?? -1) + 1
        let lastSet = exerciseLog.setLogs.sorted { $0.order < $1.order }.last
        let setLog = SetLog(
            order: nextOrder,
            setType: type,
            weight: lastSet?.weight,
            weightUnit: lastSet?.weightUnit ?? .kg
        )
        modelContext.insert(setLog)
        exerciseLog.setLogs.append(setLog)
        try? modelContext.save()
    }

    func addExercise(_ exercise: Exercise, to session: WorkoutSession) {
        let nextOrder = (session.exerciseLogs.map(\.order).max() ?? -1) + 1
        let exerciseLog = ExerciseLog(order: nextOrder, exercise: exercise, restDuration: 90)
        modelContext.insert(exerciseLog)
        session.exerciseLogs.append(exerciseLog)
        try? modelContext.save()
    }

    func finishWorkout(_ session: WorkoutSession) {
        let endDate = Date()
        session.endedAt = endDate
        session.status = .completed
        session.totalDuration = endDate.timeIntervalSince(session.startedAt)

        cancelRestTimer()
        activeSession = nil
        try? modelContext.save()

        Task { try? await healthKitService.endWorkout(date: endDate) }
    }

    func abandonWorkout(_ session: WorkoutSession) {
        session.endedAt = Date()
        session.status = .abandoned

        cancelRestTimer()
        activeSession = nil
        try? modelContext.save()
    }

    func skipRestTimer() {
        cancelRestTimer()
    }

    func adjustRestTimer(by delta: TimeInterval) {
        guard isRestTimerRunning, let current = restTimerEndsAt else { return }
        let newEndsAt = max(Date().addingTimeInterval(1), current.addingTimeInterval(delta))
        restTimerTask?.cancel()
        restTimerTask = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
        restTimerEndsAt = newEndsAt
        scheduleRestNotification(at: newEndsAt)
        startRestTimerTask(endsAt: newEndsAt)
    }

    func setRestTimerEnd(to date: Date) {
        guard isRestTimerRunning else { return }
        let safeDate = max(Date().addingTimeInterval(1), date)
        restTimerTask?.cancel()
        restTimerTask = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
        restTimerEndsAt = safeDate
        scheduleRestNotification(at: safeDate)
        startRestTimerTask(endsAt: safeDate)
    }

    // MARK: - Rest Timer

    private func startRestTimer(duration: TimeInterval) {
        guard duration > 0 else { return }
        cancelRestTimer()

        let endsAt = Date().addingTimeInterval(duration)
        restTimerEndsAt = endsAt
        isRestTimerRunning = true

        scheduleRestNotification(at: endsAt)
        startRestTimerTask(endsAt: endsAt)
    }

    private func startRestTimerTask(endsAt: Date) {
        let duration = endsAt.timeIntervalSinceNow
        restTimerTask = Task {
            let deadline = ContinuousClock.now + .seconds(max(0, duration))
            try? await Task.sleep(until: deadline, clock: .continuous)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isRestTimerRunning = false
                restTimerEndsAt = nil
                lastCompletedSetID = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func cancelRestTimer() {
        restTimerTask?.cancel()
        restTimerTask = nil
        isRestTimerRunning = false
        restTimerEndsAt = nil
        lastCompletedSetID = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }

    private func scheduleRestNotification(at date: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])

        let content = UNMutableNotificationContent()
        content.title = "Rest Over"
        content.body = "Time to get back to work!"
        content.sound = .default

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermission() {
        Task {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }
}
