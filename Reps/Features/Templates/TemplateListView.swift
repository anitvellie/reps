import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(TemplateService.self) private var templateService
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
                    Button {
                        createAndNavigate()
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
                NavigationLink(value: template) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                        let count = template.exerciseTemplates.count
                        Text("\(count) \(count == 1 ? "exercise" : "exercises")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
        }
    }

    private func createAndNavigate() {
        let newTemplate = templateService.create(name: "New Workout", notes: nil, restDuration: 90)
        path.append(newTemplate)
    }
}
