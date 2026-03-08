
import Foundation
import SwiftData

@Model
final class HoleScore {
    var id: UUID
    var playerId: UUID
    var holeNumber: Int
    var grossScore: Int
    var netScore: Int
    var strokesReceived: Int

    var round: GolfRound?

    init(
        id: UUID = UUID(),
        playerId: UUID = UUID(),
        holeNumber: Int = 1,
        grossScore: Int = 0,
        netScore: Int = 0,
        strokesReceived: Int = 0
    ) {
        self.id = id
        self.playerId = playerId
        self.holeNumber = holeNumber
        self.grossScore = grossScore
        self.netScore = netScore
        self.strokesReceived = strokesReceived
    }
}
