import Foundation
import SwiftData

@Observable
class ExerciseLibraryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func seedLibraryIfNeeded() {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { !$0.isCustom })
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let exercises: [Exercise] = [
            // MARK: - Chest
            Exercise(name: "Barbell Bench Press",          modality: .barbell,         muscleGroup: .chest,      equipment: .barbell),
            Exercise(name: "Incline Barbell Bench Press",  modality: .barbell,         muscleGroup: .chest,      equipment: .barbell),
            Exercise(name: "Decline Barbell Bench Press",  modality: .barbell,         muscleGroup: .chest,      equipment: .barbell),
            Exercise(name: "Dumbbell Bench Press",         modality: .dumbbell,        muscleGroup: .chest,      equipment: .dumbbell),
            Exercise(name: "Incline Dumbbell Press",       modality: .dumbbell,        muscleGroup: .chest,      equipment: .dumbbell),
            Exercise(name: "Dumbbell Fly",                 modality: .dumbbell,        muscleGroup: .chest,      equipment: .dumbbell),
            Exercise(name: "Cable Fly",                    modality: .cable,           muscleGroup: .chest,      equipment: .cable),
            Exercise(name: "Machine Chest Press",          modality: .machine,         muscleGroup: .chest,      equipment: .machine),
            Exercise(name: "Push-Up",                      modality: .bodyweight,      muscleGroup: .chest,      equipment: .bodyweight),
            Exercise(name: "Dip",                          modality: .bodyweightLoaded,muscleGroup: .chest,      equipment: .bodyweight),

            // MARK: - Back
            Exercise(name: "Pull-Up",                      modality: .bodyweightLoaded,muscleGroup: .back,       equipment: .bodyweight),
            Exercise(name: "Chin-Up",                      modality: .bodyweightLoaded,muscleGroup: .back,       equipment: .bodyweight),
            Exercise(name: "Barbell Row",                  modality: .barbell,         muscleGroup: .back,       equipment: .barbell),
            Exercise(name: "Pendlay Row",                  modality: .barbell,         muscleGroup: .back,       equipment: .barbell),
            Exercise(name: "Dumbbell Row",                 modality: .dumbbell,        muscleGroup: .back,       equipment: .dumbbell, isUnilateral: true),
            Exercise(name: "Seated Cable Row",             modality: .cable,           muscleGroup: .back,       equipment: .cable),
            Exercise(name: "Lat Pulldown",                 modality: .cable,           muscleGroup: .back,       equipment: .cable),
            Exercise(name: "Machine Row",                  modality: .machine,         muscleGroup: .back,       equipment: .machine),
            Exercise(name: "T-Bar Row",                    modality: .barbell,         muscleGroup: .back,       equipment: .barbell),
            Exercise(name: "Deadlift",                     modality: .barbell,         muscleGroup: .back,       equipment: .barbell),

            // MARK: - Shoulders
            Exercise(name: "Overhead Press",               modality: .barbell,         muscleGroup: .shoulders,  equipment: .barbell),
            Exercise(name: "Push Press",                   modality: .barbell,         muscleGroup: .shoulders,  equipment: .barbell),
            Exercise(name: "Seated Dumbbell Press",        modality: .dumbbell,        muscleGroup: .shoulders,  equipment: .dumbbell),
            Exercise(name: "Arnold Press",                 modality: .dumbbell,        muscleGroup: .shoulders,  equipment: .dumbbell),
            Exercise(name: "Lateral Raise",                modality: .dumbbell,        muscleGroup: .shoulders,  equipment: .dumbbell, isUnilateral: true),
            Exercise(name: "Cable Lateral Raise",          modality: .cable,           muscleGroup: .shoulders,  equipment: .cable, isUnilateral: true),
            Exercise(name: "Face Pull",                    modality: .cable,           muscleGroup: .shoulders,  equipment: .cable),
            Exercise(name: "Rear Delt Fly",                modality: .dumbbell,        muscleGroup: .shoulders,  equipment: .dumbbell),
            Exercise(name: "Machine Shoulder Press",       modality: .machine,         muscleGroup: .shoulders,  equipment: .machine),
            Exercise(name: "Upright Row",                  modality: .barbell,         muscleGroup: .shoulders,  equipment: .barbell),

            // MARK: - Biceps
            Exercise(name: "Barbell Curl",                 modality: .barbell,         muscleGroup: .biceps,     equipment: .barbell),
            Exercise(name: "EZ-Bar Curl",                  modality: .barbell,         muscleGroup: .biceps,     equipment: .barbell),
            Exercise(name: "Dumbbell Curl",                modality: .dumbbell,        muscleGroup: .biceps,     equipment: .dumbbell),
            Exercise(name: "Hammer Curl",                  modality: .dumbbell,        muscleGroup: .biceps,     equipment: .dumbbell),
            Exercise(name: "Incline Dumbbell Curl",        modality: .dumbbell,        muscleGroup: .biceps,     equipment: .dumbbell),
            Exercise(name: "Cable Curl",                   modality: .cable,           muscleGroup: .biceps,     equipment: .cable),
            Exercise(name: "Preacher Curl",                modality: .machine,         muscleGroup: .biceps,     equipment: .machine),
            Exercise(name: "Concentration Curl",           modality: .dumbbell,        muscleGroup: .biceps,     equipment: .dumbbell, isUnilateral: true),

            // MARK: - Triceps
            Exercise(name: "Skull Crushers",               modality: .barbell,         muscleGroup: .triceps,    equipment: .barbell),
            Exercise(name: "Close-Grip Bench Press",       modality: .barbell,         muscleGroup: .triceps,    equipment: .barbell),
            Exercise(name: "Tricep Pushdown",              modality: .cable,           muscleGroup: .triceps,    equipment: .cable),
            Exercise(name: "Overhead Tricep Extension",    modality: .cable,           muscleGroup: .triceps,    equipment: .cable),
            Exercise(name: "Dumbbell Tricep Kickback",     modality: .dumbbell,        muscleGroup: .triceps,    equipment: .dumbbell, isUnilateral: true),
            Exercise(name: "Dumbbell Overhead Extension",  modality: .dumbbell,        muscleGroup: .triceps,    equipment: .dumbbell),
            Exercise(name: "Tricep Dip",                   modality: .bodyweightLoaded,muscleGroup: .triceps,    equipment: .bodyweight),
            Exercise(name: "Machine Tricep Extension",     modality: .machine,         muscleGroup: .triceps,    equipment: .machine),

            // MARK: - Forearms
            Exercise(name: "Barbell Wrist Curl",           modality: .barbell,         muscleGroup: .forearms,   equipment: .barbell),
            Exercise(name: "Reverse Barbell Curl",         modality: .barbell,         muscleGroup: .forearms,   equipment: .barbell),
            Exercise(name: "Dumbbell Wrist Curl",          modality: .dumbbell,        muscleGroup: .forearms,   equipment: .dumbbell),
            Exercise(name: "Farmer's Carry",               modality: .dumbbell,        muscleGroup: .forearms,   equipment: .dumbbell),
            Exercise(name: "Dead Hang",                    modality: .bodyweight,      muscleGroup: .forearms,   equipment: .bodyweight),

            // MARK: - Quads
            Exercise(name: "Barbell Back Squat",           modality: .barbell,         muscleGroup: .quads,      equipment: .barbell),
            Exercise(name: "Barbell Front Squat",          modality: .barbell,         muscleGroup: .quads,      equipment: .barbell),
            Exercise(name: "Leg Press",                    modality: .machine,         muscleGroup: .quads,      equipment: .machine),
            Exercise(name: "Leg Extension",                modality: .machine,         muscleGroup: .quads,      equipment: .machine),
            Exercise(name: "Hack Squat",                   modality: .machine,         muscleGroup: .quads,      equipment: .machine),
            Exercise(name: "Dumbbell Lunge",               modality: .dumbbell,        muscleGroup: .quads,      equipment: .dumbbell),
            Exercise(name: "Bulgarian Split Squat",        modality: .dumbbell,        muscleGroup: .quads,      equipment: .dumbbell, isUnilateral: true),
            Exercise(name: "Step-Up",                      modality: .dumbbell,        muscleGroup: .quads,      equipment: .dumbbell, isUnilateral: true),
            Exercise(name: "Goblet Squat",                 modality: .dumbbell,        muscleGroup: .quads,      equipment: .kettlebell),

            // MARK: - Hamstrings
            Exercise(name: "Romanian Deadlift",            modality: .barbell,         muscleGroup: .hamstrings, equipment: .barbell),
            Exercise(name: "Stiff-Leg Deadlift",           modality: .barbell,         muscleGroup: .hamstrings, equipment: .barbell),
            Exercise(name: "Leg Curl",                     modality: .machine,         muscleGroup: .hamstrings, equipment: .machine),
            Exercise(name: "Seated Leg Curl",              modality: .machine,         muscleGroup: .hamstrings, equipment: .machine),
            Exercise(name: "Nordic Hamstring Curl",        modality: .bodyweight,      muscleGroup: .hamstrings, equipment: .bodyweight),
            Exercise(name: "Dumbbell Romanian Deadlift",   modality: .dumbbell,        muscleGroup: .hamstrings, equipment: .dumbbell),
            Exercise(name: "Good Morning",                 modality: .barbell,         muscleGroup: .hamstrings, equipment: .barbell),

            // MARK: - Glutes
            Exercise(name: "Barbell Hip Thrust",           modality: .barbell,         muscleGroup: .glutes,     equipment: .barbell),
            Exercise(name: "Cable Kickback",               modality: .cable,           muscleGroup: .glutes,     equipment: .cable, isUnilateral: true),
            Exercise(name: "Glute Bridge",                 modality: .bodyweight,      muscleGroup: .glutes,     equipment: .bodyweight),
            Exercise(name: "Machine Hip Abduction",        modality: .machine,         muscleGroup: .glutes,     equipment: .machine),
            Exercise(name: "Sumo Deadlift",                modality: .barbell,         muscleGroup: .glutes,     equipment: .barbell),
            Exercise(name: "Single-Leg Hip Thrust",        modality: .bodyweightLoaded,muscleGroup: .glutes,     equipment: .bodyweight, isUnilateral: true),

            // MARK: - Calves
            Exercise(name: "Standing Calf Raise",          modality: .machine,         muscleGroup: .calves,     equipment: .machine),
            Exercise(name: "Seated Calf Raise",            modality: .machine,         muscleGroup: .calves,     equipment: .machine),
            Exercise(name: "Donkey Calf Raise",            modality: .bodyweightLoaded,muscleGroup: .calves,     equipment: .bodyweight),
            Exercise(name: "Single-Leg Calf Raise",        modality: .bodyweight,      muscleGroup: .calves,     equipment: .bodyweight, isUnilateral: true),
            Exercise(name: "Leg Press Calf Raise",         modality: .machine,         muscleGroup: .calves,     equipment: .machine),

            // MARK: - Core
            Exercise(name: "Plank",                        modality: .durationOnly,    muscleGroup: .core,       equipment: .bodyweight),
            Exercise(name: "Side Plank",                   modality: .durationOnly,    muscleGroup: .core,       equipment: .bodyweight, isUnilateral: true),
            Exercise(name: "Ab Wheel Rollout",             modality: .bodyweight,      muscleGroup: .core,       equipment: .other),
            Exercise(name: "Cable Crunch",                 modality: .cable,           muscleGroup: .core,       equipment: .cable),
            Exercise(name: "Hanging Leg Raise",            modality: .bodyweight,      muscleGroup: .core,       equipment: .bodyweight),
            Exercise(name: "Decline Sit-Up",               modality: .bodyweightLoaded,muscleGroup: .core,       equipment: .machine),
            Exercise(name: "Russian Twist",                modality: .dumbbell,        muscleGroup: .core,       equipment: .dumbbell),
            Exercise(name: "Dragon Flag",                  modality: .bodyweight,      muscleGroup: .core,       equipment: .bodyweight),
            Exercise(name: "Pallof Press",                 modality: .cable,           muscleGroup: .core,       equipment: .cable),

            // MARK: - Full Body
            Exercise(name: "Running",                      modality: .cardio,          muscleGroup: .fullBody,   equipment: .bodyweight),
            Exercise(name: "Cycling",                      modality: .cardio,          muscleGroup: .fullBody,   equipment: .machine),
            Exercise(name: "Rowing Machine",               modality: .cardio,          muscleGroup: .fullBody,   equipment: .machine),
            Exercise(name: "Barbell Clean",                modality: .barbell,         muscleGroup: .fullBody,   equipment: .barbell),
            Exercise(name: "Kettlebell Swing",             modality: .dumbbell,        muscleGroup: .fullBody,   equipment: .kettlebell),
            Exercise(name: "Burpee",                       modality: .cardio,          muscleGroup: .fullBody,   equipment: .bodyweight),
            Exercise(name: "Battle Ropes",                 modality: .cardio,          muscleGroup: .fullBody,   equipment: .other),
            Exercise(name: "Jump Rope",                    modality: .cardio,          muscleGroup: .fullBody,   equipment: .other),
            Exercise(name: "Thruster",                     modality: .barbell,         muscleGroup: .fullBody,   equipment: .barbell),

            // MARK: - Other
            Exercise(name: "Band Pull-Apart",              modality: .band,            muscleGroup: .other,      equipment: .resistanceBand),
            Exercise(name: "Resistance Band Squat",        modality: .band,            muscleGroup: .other,      equipment: .resistanceBand),
        ]

        for exercise in exercises {
            modelContext.insert(exercise)
        }

        try? modelContext.save()
    }
}
