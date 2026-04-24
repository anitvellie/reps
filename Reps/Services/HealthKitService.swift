import Foundation
import HealthKit

@Observable
class HealthKitService {
    var isAuthorized: Bool = false

    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        // TODO: Phase 2 — request HealthKit read/write authorization
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        isAuthorized = true
    }

    func startWorkout(date: Date) async throws {
        // TODO: Phase 2 — create and start an HKWorkoutSession / HKWorkoutBuilder
    }

    func endWorkout(date: Date) async throws {
        // TODO: Phase 2 — finish the HKWorkoutBuilder and save the workout
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        }
    }
}
