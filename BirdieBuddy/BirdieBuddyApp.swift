
import SwiftUI
import SwiftData

@main
struct BirdieBuddyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            UserProfile.self,
            Course.self,
            Hole.self,
            GolfRound.self,
            RoundPlayer.self,
            HoleScore.self,
            Game.self,
            Team.self,
            Trip.self,
            ShotVideo.self,
            Tournament.self,
            TournamentPlayer.self,
            TournamentRound.self,
            Foursome.self,
            TournamentGame.self
        ])
    }
}
