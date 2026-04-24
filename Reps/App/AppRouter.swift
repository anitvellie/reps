import SwiftUI

@Observable
class AppRouter {
    var navigationPath = NavigationPath()
    var activeSheet: AppSheet?

    func navigate(to destination: some Hashable) {
        navigationPath.append(destination)
    }

    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    func present(_ sheet: AppSheet) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }
}

enum AppSheet: Identifiable {
    case createExercise
    case createTemplate
    case activeWorkout(WorkoutSession)

    var id: String {
        switch self {
        case .createExercise:
            return "createExercise"
        case .createTemplate:
            return "createTemplate"
        case .activeWorkout(let session):
            return "activeWorkout-\(session.id.uuidString)"
        }
    }
}
