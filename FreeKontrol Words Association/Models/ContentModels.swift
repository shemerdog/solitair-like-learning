import Foundation

// Use your existing JourneyType & Difficulty types.
// Assuming JourneyType: String, Codable and Difficulty: String, Codable

enum AppLanguage {
    case he
    case en
}

enum DifficultyHint: String, Codable {
    case easy, medium, hard
}

struct TagDefinition: Codable {
    let journey: JourneyType
    let tagKey: String
    let minItems: Int
    let difficultyHint: DifficultyHint?
    let titleHe: String
    let titleEn: String
    
    func title(for language: AppLanguage) -> String {
        switch language {
        case .he: return titleHe.isEmpty ? titleEn : titleHe
        case .en: return titleEn.isEmpty ? titleHe : titleEn
        }
    }
}

enum WordContentType: String, Codable {
    case word
    case imageName
}

struct WordDefinition: Codable {
    let journey: JourneyType
    let contentType: WordContentType
    let tags: [String]
    let valueHe: String
    let valueEn: String
    
    func value(for language: AppLanguage) -> String {
        switch language {
        case .he: return valueHe.isEmpty ? valueEn : valueHe
        case .en: return valueEn.isEmpty ? valueHe : valueEn
        }
    }
}
