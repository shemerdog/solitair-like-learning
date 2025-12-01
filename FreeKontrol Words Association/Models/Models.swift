//
//  Models.swift
//  FreeKontrol Words Association
//
//  Created by ChatGPT 5.1 on 02/12/2025.
//
import SwiftUI
import Foundation

enum JourneyType: String, CaseIterable, Identifiable, Codable {
    case history
    case nature
    case philosophy
    case movies
    case religion
    
    var id: String { rawValue }
    
    var displayNameHebrew: String {
        switch self {
        case .history: return "היסטוריה"
        case .nature: return "טבע"
        case .philosophy: return "פילוסופיה"
        case .movies: return "סרטים"
        case .religion: return "דת"
        }
    }
}

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case medium
    case hard
    
    var id: String { rawValue }
    
    var displayNameHebrew: String {
        switch self {
        case .easy: return "קל"
        case .medium: return "בינוני"
        case .hard: return "קשה"
        }
    }
    
    // Example parameters – you can tune these
    var maxMoves: Int {
        switch self {
        case .easy: return 30
        case .medium: return 20
        case .hard: return 12
        }
    }
    
    var maxCategories: Int {
        switch self {
        case .easy: return 3
        case .medium: return 4
        case .hard: return 5
        }
    }
    
    var maxItems: Int {
        switch self {
        case .easy: return 12
        case .medium: return 18
        case .hard: return 24
        }
    }
}

enum CardContentType: String, CaseIterable, Identifiable, Codable {
    case words
    case images
    case both
    
    var id: String { rawValue }
    
    var displayNameHebrew: String {
        switch self {
        case .words: return "מילים בלבד"
        case .images: return "אייקונים בלבד"
        case .both: return "גם וגם"
        }
    }
}

struct GameAppearanceTheme: Identifiable, Codable {
    let id: UUID
    let name: String
    let backgroundColor: ColorData
    let cardBackColor: ColorData
    
    init(id: UUID = UUID(),
         name: String,
         backgroundColor: ColorData,
         cardBackColor: ColorData) {
        self.id = id
        self.name = name
        self.backgroundColor = backgroundColor
        self.cardBackColor = cardBackColor
    }
}

struct ColorData: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue).opacity(opacity)
    }
}

// Category card (e.g. "חיות ים", "מלחמות")
struct CategoryCard: Identifiable, Codable {
    let id: UUID
    let title: String    // Hebrew category name
}

// Individual item to match to a category
enum ItemCardContent: Codable {
    case word(String)
    case imageName(String) // name of asset in your asset catalog
    
    private enum CodingKeys: CodingKey {
        case type, value
    }
    
    enum ContentType: String, Codable {
        case word
        case imageName
    }
    
    // Codable boilerplate
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        switch type {
        case .word:
            let value = try container.decode(String.self, forKey: .value)
            self = .word(value)
        case .imageName:
            let value = try container.decode(String.self, forKey: .value)
            self = .imageName(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .word(let text):
            try container.encode(ContentType.word, forKey: .type)
            try container.encode(text, forKey: .value)
        case .imageName(let name):
            try container.encode(ContentType.imageName, forKey: .type)
            try container.encode(name, forKey: .value)
        }
    }
}

struct ItemCard: Identifiable, Codable {
    let id: UUID
    let content: ItemCardContent
    let correctCategoryID: UUID
}

// One playable level
struct Level: Identifiable, Codable {
    let id: UUID
    let journey: JourneyType
    let difficulty: Difficulty
    let categories: [CategoryCard]
    let items: [ItemCard]
    let baseMoves: Int
}

// MARK: - JSON level definitions
struct LevelDefinition: Codable {
    let journey: JourneyType
    let difficulty: Difficulty
    let baseMoves: Int?
    let categories: [CategoryDefinition]
    let items: [ItemDefinition]
}

struct CategoryDefinition: Codable {
    let key: String
    let title: String
}

struct ItemDefinition: Codable {
    let content: ItemCardContent    // uses existing Codable implementation
    let categoryKey: String
}

// MARK: - Level Repository (JSON-backed)

struct LevelRepository {
    static let shared = LevelRepository()
    
    let allLevels: [Level]
    
    init() {
        // Load from levels.json in the app bundle
        if let url = Bundle.main.url(forResource: "levels", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let definitions = try decoder.decode([LevelDefinition].self, from: data)
                self.allLevels = definitions.compactMap { LevelRepository.makeLevel(from: $0) }
            } catch {
                print("❌ Failed to load levels.json: \(error)")
                self.allLevels = []
            }
        } else {
            print("❌ levels.json not found in bundle")
            self.allLevels = []
        }
    }
    
    static func makeLevel(from def: LevelDefinition) -> Level {
        // Create categories with UUIDs and map keys → ids
        var categoryIDByKey: [String: UUID] = [:]
        var categories: [CategoryCard] = []
        
        for catDef in def.categories {
            let id = UUID()
            categoryIDByKey[catDef.key] = id
            categories.append(CategoryCard(id: id, title: catDef.title))
        }
        
        // Create items using the mapping
        var items: [ItemCard] = []
        for itemDef in def.items {
            guard let catID = categoryIDByKey[itemDef.categoryKey] else {
                print("⚠️ Unknown categoryKey \(itemDef.categoryKey) in level for journey \(def.journey)")
                continue
            }
            let item = ItemCard(
                id: UUID(),
                content: itemDef.content,
                correctCategoryID: catID
            )
            items.append(item)
        }
        
        let moves = def.baseMoves ?? def.difficulty.maxMoves
        
        return Level(
            id: UUID(),
            journey: def.journey,
            difficulty: def.difficulty,
            categories: categories,
            items: items,
            baseMoves: moves
        )
    }
    
    func levels(for journey: JourneyType, difficulty: Difficulty) -> [Level] {
        allLevels.filter { $0.journey == journey && $0.difficulty == difficulty }
    }
}
