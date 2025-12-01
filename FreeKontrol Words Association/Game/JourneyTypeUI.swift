import SwiftUI

extension JourneyType {
    var emoji: String {
        switch self {
        case .history:    return "📜"
        case .nature:     return "🌿"
        case .philosophy: return "🧠"
        case .movies:     return "🎬"
        case .religion:   return "✡️"
        }
    }
    
    var subtitleHebrew: String {
        switch self {
        case .history:    return "דמויות, אירועים ומהפכות"
        case .nature:     return "חיות, צמחים ועולמות חיים"
        case .philosophy: return "רעיונות, זרמים וחוקרים"
        case .movies:     return "סגנונות, תקופות ובמאים"
        case .religion:   return "חגים, מושגים ומקורות"
        }
    }
    
    /// Main color for the journey card
    var primaryColor: Color {
        switch self {
        case .history:    return Color(red: 0.85, green: 0.55, blue: 0.30)
        case .nature:     return Color(red: 0.20, green: 0.65, blue: 0.35)
        case .philosophy: return Color(red: 0.40, green: 0.45, blue: 0.85)
        case .movies:     return Color(red: 0.80, green: 0.25, blue: 0.40)
        case .religion:   return Color(red: 0.75, green: 0.65, blue: 0.25)
        }
    }
    
    /// Secondary color for gradient
    var secondaryColor: Color {
        switch self {
        case .history:    return Color(red: 0.60, green: 0.35, blue: 0.20)
        case .nature:     return Color(red: 0.10, green: 0.40, blue: 0.25)
        case .philosophy: return Color(red: 0.25, green: 0.30, blue: 0.65)
        case .movies:     return Color(red: 0.45, green: 0.10, blue: 0.25)
        case .religion:   return Color(red: 0.45, green: 0.45, blue: 0.15)
        }
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
