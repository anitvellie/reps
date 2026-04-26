import Foundation
import HealthKit

@Observable
class HealthKitService {
    var isAuthorized: Bool = false

    private let healthStore = HKHealthStore()
    @ObservationIgnored private var workoutBuilder: HKWorkoutBuilder?

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        isAuthorized = true
    }

    func startWorkout(date: Date) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        if !isAuthorized {
            try? await requestAuthorization()
        }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: .local())
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.beginCollection(withStart: date) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        workoutBuilder = builder
    }

    func endWorkout(date: Date) async throws {
        guard let builder = workoutBuilder else { return }
        defer { workoutBuilder = nil }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.endCollection(withEnd: date) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.finishWorkout { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
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
