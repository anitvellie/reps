import SwiftUI
import SwiftData

@main
struct RepsApp: App {
    @State private var appRouter = AppRouter()
    @State private var exerciseLibraryService: ExerciseLibraryService
    @State private var templateService: TemplateService
    @State private var healthKitService = HealthKitService()
    @State private var workoutSessionService: WorkoutSessionService
    @State private var appSettings = AppSettings()

    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            ExerciseTemplate.self,
            SetTemplate.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            modelContainer = container

            let context = container.mainContext
            let hkService = HealthKitService()
            let libService = ExerciseLibraryService(modelContext: context)
            let tmplService = TemplateService(modelContext: context)
            let sessionService = WorkoutSessionService(modelContext: context, healthKitService: hkService)

            _exerciseLibraryService = State(initialValue: libService)
            _templateService = State(initialValue: tmplService)
            _healthKitService = State(initialValue: hkService)
            _workoutSessionService = State(initialValue: sessionService)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(appRouter)
                .environment(exerciseLibraryService)
                .environment(templateService)
                .environment(workoutSessionService)
                .environment(healthKitService)
                .environment(appSettings)
                .onAppear {
                    exerciseLibraryService.seedLibraryIfNeeded()
                }
        }
    }
}
