import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ExerciseLibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "book")
            }

            TemplateListView()
                .tabItem {
                    Label("Templates", systemImage: "list.bullet")
                }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
