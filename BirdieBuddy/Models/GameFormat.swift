import Foundation

enum GameFormat: String, CaseIterable, Codable {
    case strokePlay = "Stroke Play"
    case matchPlay  = "Match Play"
}

enum HoleResult: Equatable {
    case playerWins(Player)
    case halved
}
