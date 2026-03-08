
import Foundation

enum GameEngineFactory {
    static func engine(for format: GameFormat) -> GameEngineProtocol {
        switch format {
        case .nassau: return NassauEngine()
        case .fourBall: return FourBallEngine()
        case .bestBall: return GenericTeamEngine(format: .bestBall)
        case .alternateShot: return GenericTeamEngine(format: .alternateShot)
        case .scramble: return ScrambleEngine()
        case .shamble: return GenericTeamEngine(format: .shamble)
        case .wolf: return WolfEngine()
        case .fiveThreeOne: return FiveThreeOneEngine()
        }
    }
}
