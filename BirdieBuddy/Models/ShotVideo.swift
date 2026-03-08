
import Foundation
import SwiftData

@Model
final class ShotVideo {
    var id: UUID
    var videoURLString: String
    var thumbnailURLString: String?
    var playerId: UUID
    var courseId: UUID?
    var holeNumber: Int?
    var recordedAt: Date
    var playerName: String

    var round: GolfRound?

    init(
        id: UUID = UUID(),
        videoURL: URL = URL(fileURLWithPath: ""),
        thumbnailURL: URL? = nil,
        playerId: UUID = UUID(),
        courseId: UUID? = nil,
        holeNumber: Int? = nil,
        recordedAt: Date = Date(),
        playerName: String = ""
    ) {
        self.id = id
        self.videoURLString = videoURL.absoluteString
        self.thumbnailURLString = thumbnailURL?.absoluteString
        self.playerId = playerId
        self.courseId = courseId
        self.holeNumber = holeNumber
        self.recordedAt = recordedAt
        self.playerName = playerName
    }

    var videoURL: URL {
        get { URL(string: videoURLString) ?? URL(fileURLWithPath: "") }
        set { videoURLString = newValue.absoluteString }
    }

    var thumbnailURL: URL? {
        get { guard let s = thumbnailURLString else { return nil }; return URL(string: s) }
        set { thumbnailURLString = newValue?.absoluteString }
    }
}
