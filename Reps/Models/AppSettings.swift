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

    init() {}
}
