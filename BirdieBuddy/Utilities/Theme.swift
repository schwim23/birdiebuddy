
import SwiftUI

struct Theme {
    static let primaryGreen = Color("PrimaryGreen")
    static let secondaryGreen = Color("SecondaryGreen")
    static let lightGreen = Color("LightGreen")
    static let darkGreen = Color("DarkGreen")
    static let accent = Color("Accent")
    static let background = Color("AppBackground")
    static let cardBackground = Color("CardBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let destructive = Color("Destructive")
    static let birdie = Color(red: 0.85, green: 0.20, blue: 0.20)
    static let eagle = Color(red: 0.80, green: 0.68, blue: 0.15)
    static let par = Color(red: 0.18, green: 0.55, blue: 0.34)
    static let bogey = Color(red: 0.25, green: 0.47, blue: 0.75)
    static let doubleBogey = Color(red: 0.85, green: 0.55, blue: 0.15)
    static let worse = Color(red: 0.55, green: 0.55, blue: 0.55)
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
}

enum ScoreType: String {
    case albatross = "Albatross"
    case eagle = "Eagle"
    case birdie = "Birdie"
    case par = "Par"
    case bogey = "Bogey"
    case doubleBogey = "Double"
    case triplePlus = "Triple+"

    var color: Color {
        switch self {
        case .albatross: return .purple
        case .eagle: return Theme.eagle
        case .birdie: return Theme.birdie
        case .par: return Theme.par
        case .bogey: return Theme.bogey
        case .doubleBogey: return Theme.doubleBogey
        case .triplePlus: return Theme.worse
        }
    }

    static func from(gross: Int, par: Int) -> ScoreType {
        switch gross - par {
        case ...(-3): return .albatross
        case -2: return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        case 2: return .doubleBogey
        default: return .triplePlus
        }
    }
}
