import Foundation

enum ExerciseModality: String, CaseIterable, Codable {
    case barbell
    case dumbbell
    case machine
    case cable
    case bodyweight
    case bodyweightLoaded
    case cardio
    case durationOnly
    case band

    var displayName: String {
        switch self {
        case .barbell:         return "Barbell"
        case .dumbbell:        return "Dumbbell"
        case .machine:         return "Machine"
        case .cable:           return "Cable"
        case .bodyweight:      return "Bodyweight"
        case .bodyweightLoaded: return "Weighted Bodyweight"
        case .cardio:          return "Cardio"
        case .durationOnly:    return "Duration Only"
        case .band:            return "Resistance Band"
        }
    }
}

enum SetType: String, CaseIterable, Codable {
    case working
    case warmup
    case dropSet
    case failure
    case restPause
    case myorep
    case backoff
    case amrap

    var displayName: String {
        switch self {
        case .working:    return "Working"
        case .warmup:     return "Warm-Up"
        case .dropSet:    return "Drop Set"
        case .failure:    return "To Failure"
        case .restPause:  return "Rest-Pause"
        case .myorep:     return "Myo-Rep"
        case .backoff:    return "Back-Off"
        case .amrap:      return "AMRAP"
        }
    }
}

enum WeightUnit: String, CaseIterable, Codable {
    case kg
    case lb

    var displayName: String {
        switch self {
        case .kg: return "Kilograms (kg)"
        case .lb: return "Pounds (lb)"
        }
    }
}

enum WorkoutStatus: String, CaseIterable, Codable {
    case inProgress
    case completed
    case abandoned
}

enum MuscleGroup: String, CaseIterable, Codable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case quads
    case hamstrings
    case glutes
    case calves
    case core
    case fullBody
    case other

    var displayName: String {
        switch self {
        case .chest:       return "Chest"
        case .back:        return "Back"
        case .shoulders:   return "Shoulders"
        case .biceps:      return "Biceps"
        case .triceps:     return "Triceps"
        case .forearms:    return "Forearms"
        case .quads:       return "Quads"
        case .hamstrings:  return "Hamstrings"
        case .glutes:      return "Glutes"
        case .calves:      return "Calves"
        case .core:        return "Core"
        case .fullBody:    return "Full Body"
        case .other:       return "Other"
        }
    }
}

enum EquipmentType: String, CaseIterable, Codable {
    case barbell
    case dumbbell
    case machine
    case cable
    case bodyweight
    case resistanceBand
    case kettlebell
    case other

    var displayName: String {
        switch self {
        case .barbell:        return "Barbell"
        case .dumbbell:       return "Dumbbell"
        case .machine:        return "Machine"
        case .cable:          return "Cable"
        case .bodyweight:     return "Bodyweight"
        case .resistanceBand: return "Resistance Band"
        case .kettlebell:     return "Kettlebell"
        case .other:          return "Other"
        }
    }
}
