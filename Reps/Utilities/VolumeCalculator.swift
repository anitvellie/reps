import Foundation

struct VolumeCalculator {
    static func volume(weight: Double, reps: Int) -> Double {
        return weight * Double(reps)
    }

    static func totalVolume(for setLogs: [SetLog]) -> Double {
        return setLogs
            .filter { $0.isCompleted }
            .reduce(0.0) { total, setLog in
                guard let weight = setLog.weight,
                      let reps = setLog.actualReps else {
                    return total
                }
                return total + volume(weight: weight, reps: reps)
            }
    }
}
