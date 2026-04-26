import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(TemplateService.self) private var templateService
    @Environment(WorkoutSessionService.self) private var workoutSessionService
    @Environment(AppRouter.self) private var appRouter
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Templates")
            .navigationDestination(for: WorkoutTemplate.self) { template in
                TemplateBuilderView(template: template)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            createAndNavigate()
                        } label: {
                            Label("New Template", systemImage: "doc.badge.plus")
                        }
                        Button {
                            startAdHocWorkout()
                        } label: {
                            Label("Empty Workout", systemImage: "play.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var templateList: some View {
        List {
            ForEach(templates) { template in
                HStack {
                    Button {
                        path.append(template)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                            let count = template.exerciseTemplates.count
                            Text("\(count) \(count == 1 ? "exercise" : "exercises")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        let session = workoutSessionService.startWorkout(from: template)
                        appRouter.present(.activeWorkout(session))
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        templateService.delete(template)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No templates yet")
                .foregroundStyle(.secondary)
            Button("Create Template") {
                createAndNavigate()
            }
            .buttonStyle(.borderedProminent)
            Button("Start Empty Workout") {
                startAdHocWorkout()
            }
            .foregroundStyle(.secondary)
        }
    }

    private func createAndNavigate() {
        let newTemplate = templateService.create(name: "New Workout", notes: nil, restDuration: 90)
        path.append(newTemplate)
    }

    private func startAdHocWorkout() {
        let session = workoutSessionService.startAdHocWorkout()
        appRouter.present(.activeWorkout(session))
    }
}
