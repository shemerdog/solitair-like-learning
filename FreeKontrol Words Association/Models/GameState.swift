import SwiftUI
import Combine

enum GameStatus {
    case playing
    case won
    case lost
}

enum MatchFeedback {
    case none
    case correct
    case wrong
}

final class GameState: ObservableObject {

    private let levelGenerator = TagBasedLevelGenerator(
        tags: ContentRepository.shared.tags,
        words: ContentRepository.shared.words
    )
    
    private let appLanguage: AppLanguage = .he   // or .en later

    @Published var currentJourney: JourneyType? = nil
    @Published var currentLevel: Level? = nil
    @Published var movesLeft: Int = 0
    @Published var settings: GameSettings
    @Published var availableThemes: [GameAppearanceTheme]
    
    // Gameplay state
    @Published var matchedItemIDs: [UUID] = []             // ordered – last = last matched
    @Published var status: GameStatus = .playing
    @Published var lastMatchFeedback: MatchFeedback = .none
    
    // Solitaire-style layout
    @Published var tableauColumns: [[UUID]] = []           // per column card IDs (bottom -> top)
    @Published var drawPileItemIDs: [UUID] = []            // stock
    @Published var wastePileItemIDs: [UUID] = []           // waste (face-up)
    @Published var faceUpItemIDs: [UUID] = []              // which tableau cards are face-up
    
    // MARK: - Init
    
    init() {
        let themes: [GameAppearanceTheme] = [
            GameAppearanceTheme(
                name: "קלאסי",
                backgroundColor: ColorData(red: 0.8, green: 1.0, blue: 0.8, opacity: 1.0),
                cardBackColor: ColorData(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
            ),
            GameAppearanceTheme(
                name: "לילה",
                backgroundColor: ColorData(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0),
                cardBackColor: ColorData(red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0)
            ),
            GameAppearanceTheme(
                name: "טבע",
                backgroundColor: ColorData(red: 0.7, green: 0.85, blue: 1.0, opacity: 1.0),
                cardBackColor: ColorData(red: 0.6, green: 0.8, blue: 0.6, opacity: 1.0)
            )
        ]
        
        self.availableThemes = themes
        self.settings = GameSettings(
            difficulty: .easy,
            cardContentType: .both,
            selectedThemeID: themes.first?.id
        )
    }
    
    var currentTheme: GameAppearanceTheme {
        if let id = settings.selectedThemeID,
           let theme = availableThemes.first(where: { $0.id == id }) {
            return theme
        }
        return availableThemes[0]
    }
    
    // MARK: - Level loading
    
    func start(journey: JourneyType) {
        currentJourney = journey
        loadLevelForCurrentJourney()
        resetForCurrentLevel()
    }
    
    private func loadLevelForCurrentJourney() {
        guard let journey = currentJourney else {
            currentLevel = nil
            return
        }
        
        if let level = levelGenerator.generateLevel(
            journey: journey,
            difficulty: settings.difficulty,
            language: appLanguage
        ) {
            currentLevel = level
        } else {
            currentLevel = nil
            print("Failed to generate level for \(journey) \(settings.difficulty)")
        }
    }

    // MARK: - Layout parameters / helpers
    
    let maxColumns = 3
    
    var drawPileCount: Int {
        drawPileItemIDs.filter { id in
            !matchedItemIDs.contains(id)
        }.count
    }
    
    var wasteItems: [ItemCard] {
        guard let level = currentLevel else { return [] }
        return wastePileItemIDs.compactMap { id in
            guard !matchedItemIDs.contains(id) else { return nil }
            return level.items.first { $0.id == id }
        }
    }
    
    func item(for id: UUID) -> ItemCard? {
        guard let level = currentLevel else { return nil }
        return level.items.first { $0.id == id }
    }
    
    func matchedItems(for categoryID: UUID) -> [ItemCard] {
        guard let level = currentLevel else { return [] }
        
        let items = matchedItemIDs.compactMap { id in
            level.items.first { $0.id == id && $0.correctCategoryID == categoryID }
        }
        return items
    }
    
    // MARK: - Reset
    
    private func resetForCurrentLevel() {
        matchedItemIDs.removeAll()
        status = .playing
        lastMatchFeedback = .none
        movesLeft = currentLevel?.baseMoves ?? 0
        
        tableauColumns.removeAll()
        drawPileItemIDs.removeAll()
        wastePileItemIDs.removeAll()
        faceUpItemIDs.removeAll()
        
        guard let level = currentLevel else { return }
        
        // Shuffle all items
        var allIDs = level.items.map { $0.id }
        allIDs.shuffle()
        
        // Start with 3 cards per column (or less if not enough),
        // only the top one in each column face-up
        tableauColumns = Array(repeating: [], count: maxColumns)
        
        for col in 0..<maxColumns {
            var column: [UUID] = []
            for _ in 0..<3 {
                guard !allIDs.isEmpty else { break }
                column.append(allIDs.removeFirst())
            }
            tableauColumns[col] = column
        }
        
        // Remaining cards go to draw pile
        drawPileItemIDs = allIDs
        
        // Mark top card in each non-empty column as face-up
        for column in tableauColumns {
            if let top = column.last {
                faceUpItemIDs.append(top)
            }
        }
    }
    
    // MARK: - Gameplay
    
    func isItemMatched(_ item: ItemCard) -> Bool {
        matchedItemIDs.contains(item.id)
    }
    
    private func checkForLossIfNeeded() {
        guard let level = currentLevel else { return }
        if movesLeft <= 0 && matchedItemIDs.count < level.items.count {
            status = .lost
        }
    }
    
    func dealFromDrawPile() {
        guard status == .playing else { return }
        
        // Only unmatched cards in draw pile
        let available = drawPileItemIDs.filter { !matchedItemIDs.contains($0) }
        guard !available.isEmpty else {
            checkForLossIfNeeded()
            return
        }
        
        // Draw count depends on difficulty
        let drawCount: Int
        switch settings.difficulty {
        case .easy:
            drawCount = 1   // 👈 only one card per draw on easy
        case .medium, .hard:
            drawCount = maxColumns
        }
        
        // Dealing costs a move
        movesLeft -= 1
        
        let cardsToDeal = min(drawCount, available.count)
        let dealt = Array(available.prefix(cardsToDeal))
        
        // Remove from draw
        drawPileItemIDs.removeAll(where: { dealt.contains($0) })
        
        // Place on waste
        wastePileItemIDs.append(contentsOf: dealt)
        
        checkForLossIfNeeded()
    }
    
    func attemptMatch(itemID: UUID, categoryID: UUID) {
        guard status == .playing else { return }
        guard let level = currentLevel,
              let item = level.items.first(where: { $0.id == itemID }) else {
            return
        }
        
        // Each attempt costs a move
        movesLeft -= 1
        
        // Check correctness
        if item.correctCategoryID == categoryID {
            matchedItemIDs.append(item.id)
            lastMatchFeedback = .correct
            removeItemFromPilesAfterMatch(itemID: item.id)
        } else {
            lastMatchFeedback = .wrong
        }
        
        // Win?
        if matchedItemIDs.count == level.items.count {
            status = .won
            return
        }
        
        // Lose?
        checkForLossIfNeeded()
    }
    
    private func removeItemFromPilesAfterMatch(itemID: UUID) {
        // Remove from tableau columns
        for colIndex in tableauColumns.indices {
            if let idx = tableauColumns[colIndex].firstIndex(of: itemID) {
                tableauColumns[colIndex].remove(at: idx)
                faceUpItemIDs.removeAll(where: { $0 == itemID })
                
                // Flip next top card face-up, if any
                if let newTop = tableauColumns[colIndex].last {
                    if !faceUpItemIDs.contains(newTop) {
                        faceUpItemIDs.append(newTop)
                    }
                }
                break
            }
        }
        
        // Remove from waste
        wastePileItemIDs.removeAll(where: { $0 == itemID })
        
        // Just in case, also clear from draw if it somehow was there
        drawPileItemIDs.removeAll(where: { $0 == itemID })
    }
}
