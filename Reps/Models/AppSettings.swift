import Foundation

@Observable
class AppSettings {
    var weightUnit: WeightUnit {
        get {
            let raw = UserDefaults.standard.string(forKey: "weightUnit") ?? WeightUnit.kg.rawValue
            return WeightUnit(rawValue: raw) ?? .kg
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "weightUnit")
        }
    }

    var useRPE: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRPE") as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useRPE")
        }
    }

    var defaultRestDuration: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: "defaultRestDuration")
            return stored > 0 ? stored : 90
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultRestDuration")
        }
    }

    init() {}
}
