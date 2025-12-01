import SwiftUI

struct GameSettings: Codable {
    var difficulty: Difficulty = .easy
    var cardContentType: CardContentType = .both
    var selectedThemeID: UUID?
}
