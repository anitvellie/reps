import SwiftUI

struct ContentView: View {
    @Environment(AppRouter.self) private var appRouter

    var body: some View {
        @Bindable var router = appRouter

        TabView {
            TemplateListView()
                .tabItem {
                    Label("Workouts", systemImage: "list.bullet")
                }

            NavigationStack {
                ExerciseLibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "book")
            }

            NavigationStack {
                WorkoutHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .fullScreenCover(item: $router.activeSheet) { sheet in
            if case .activeWorkout(let session) = sheet {
                ActiveWorkoutView(session: session)
            }
        }
    }
}
