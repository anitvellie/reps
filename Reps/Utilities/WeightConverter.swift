import Foundation

struct WeightConverter {
    private static let kgToLbFactor: Double = 2.20462
    private static let lbToKgFactor: Double = 0.453592

    static func convert(_ value: Double, from: WeightUnit, to: WeightUnit) -> Double {
        guard from != to else { return value }
        switch (from, to) {
        case (.kg, .lb):
            return value * kgToLbFactor
        case (.lb, .kg):
            return value * lbToKgFactor
        default:
            return value
        }
    }

    static func formatted(_ value: Double, unit: WeightUnit) -> String {
        let formatted = String(format: "%.1f", value)
        switch unit {
        case .kg: return "\(formatted) kg"
        case .lb: return "\(formatted) lb"
        }
    }
}
