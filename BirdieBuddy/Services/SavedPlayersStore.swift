import Foundation
import Observation

/// Persists player profiles to UserDefaults (JSON). Replaced by SwiftData in Feature 006.
@Observable
final class SavedPlayersStore {
    private(set) var players: [Player] = []
    private let key = "savedPlayers"

    init() { load() }

    /// Upserts a player by name (case-insensitive). Adds if new, updates handicap if known.
    func upsert(_ player: Player) {
        if let idx = players.firstIndex(where: { $0.name.lowercased() == player.name.lowercased() }) {
            players[idx].handicap = player.handicap
        } else {
            players.append(player)
        }
        persist()
    }

    func remove(_ player: Player) {
        players.removeAll { $0.id == player.id }
        persist()
    }

    // MARK: - Private

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Player].self, from: data)
        else { return }
        players = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(players) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
