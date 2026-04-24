import Foundation
import SwiftData

@Model
class Exercise {
    var id: UUID
    var name: String
    var modality: ExerciseModality
    var muscleGroup: MuscleGroup
    var equipment: EquipmentType
    var isUnilateral: Bool
    var isCustom: Bool
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        modality: ExerciseModality,
        muscleGroup: MuscleGroup,
        equipment: EquipmentType,
        isUnilateral: Bool = false,
        isCustom: Bool = false,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.modality = modality
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.isUnilateral = isUnilateral
        self.isCustom = isCustom
        self.notes = notes
        self.createdAt = createdAt
    }
}
