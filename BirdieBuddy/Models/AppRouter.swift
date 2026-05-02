import SwiftUI
import Observation

/// All navigable screens in the app.
enum AppRoute: Hashable {
    case setup
    case round
    case summary
    case scorecard
    case newCourse
    case editCourse(CourseSetup)
    case stats
    case signIn
    case roundLobby
    case joinRound
}

/// Holds the NavigationPath centrally so any view can push/pop without chained bindings.
@Observable
final class AppRouter {
    var path: [AppRoute] = []

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
