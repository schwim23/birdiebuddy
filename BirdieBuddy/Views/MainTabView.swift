
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            TripListScreen()
                .tabItem { Label("Trips", systemImage: "airplane") }
                .tag(1)
            TournamentListScreen()
                .tabItem { Label("Tournaments", systemImage: "trophy.fill") }
                .tag(2)
            VideoGalleryScreen()
                .tabItem { Label("Videos", systemImage: "video.fill") }
                .tag(3)
            ProfileScreen()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Theme.primaryGreen)
    }
}
