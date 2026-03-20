import SwiftUI
import SwiftData

@main
struct BirdieBuddyApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: Binding(
                get: { router.path },
                set: { router.path = $0 }
            )) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .setup:     SetupView()
                        case .round:     RoundView()
                        case .summary:   SummaryView()
                        case .scorecard: ScorecardView()
                        }
                    }
            }
            .environment(appState)
            .environment(router)
        }
        .modelContainer(for: [PlayerProfile.self, RoundRecord.self])
    }
}
