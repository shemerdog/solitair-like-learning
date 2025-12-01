import Foundation

struct LevelGenerationParameters {
    let categoriesCount: Int
    let itemsPerCategory: Int
    let baseMoves: Int
}

extension Difficulty {
    var generationParameters: LevelGenerationParameters {
        switch self {
        case .easy:
            return LevelGenerationParameters(
                categoriesCount: 2,
                itemsPerCategory: 4,
                baseMoves: 30
            )
        case .medium:
            return LevelGenerationParameters(
                categoriesCount: 3,
                itemsPerCategory: 4,
                baseMoves: 32
            )
        case .hard:
            return LevelGenerationParameters(
                categoriesCount: 4,
                itemsPerCategory: 4,
                baseMoves: 34
            )
        }
    }
}

struct TagBasedLevelGenerator {
    let tags: [TagDefinition]
    let words: [WordDefinition]
    
    func generateLevel(
        journey: JourneyType,
        difficulty: Difficulty,
        language: AppLanguage
    ) -> Level? {
        let params = difficulty.generationParameters
        
        // Filter tags & words for this journey
        let journeyTags  = tags.filter  { $0.journey == journey }
        let journeyWords = words.filter { $0.journey == journey }
        
        // Eligible tags: have enough words for this difficulty
        var eligibleTags = journeyTags.filter { tag in
            let count = journeyWords.filter { $0.tags.contains(tag.tagKey) }.count
            return count >= params.itemsPerCategory && count >= tag.minItems
        }
        
        // Optional: bias by difficultyHint (very soft)
        eligibleTags.shuffle()
        if !eligibleTags.isEmpty {
            let preferred = eligibleTags.filter { $0.difficultyHint?.matches(difficulty) ?? true }
            if !preferred.isEmpty {
                eligibleTags = preferred
            }
        }
        
        guard !eligibleTags.isEmpty else {
            print("No eligible tags for journey \(journey) and difficulty \(difficulty)")
            return nil
        }
        
        let chosenTags = Array(eligibleTags.prefix(params.categoriesCount))
        guard !chosenTags.isEmpty else { return nil }
        
        var categories: [CategoryCard] = []
        var items: [ItemCard] = []
        
        for tag in chosenTags {
            let categoryID = UUID()
            let categoryTitle = tag.title(for: language)
            
            categories.append(CategoryCard(id: categoryID, title: categoryTitle))
            
            let candidates = journeyWords.filter { $0.tags.contains(tag.tagKey) }
            let shuffled   = candidates.shuffled()
            let picked     = Array(shuffled.prefix(params.itemsPerCategory))
            
            for w in picked {
                let text = w.value(for: language)
                let content: ItemCardContent
                switch w.contentType {
                case .word:
                    content = .word(text)
                case .imageName:
                    content = .imageName(text)
                }
                
                let card = ItemCard(
                    id: UUID(),
                    content: content,
                    correctCategoryID: categoryID
                )
                items.append(card)
            }
        }
        
        // Shuffle final items for randomness on the board
        items.shuffle()
        
        return Level(
            id: UUID(),
            journey: journey,
            difficulty: difficulty,
            categories: categories,
            items: items,
            baseMoves: params.baseMoves
        )
    }
}

private extension DifficultyHint {
    func matches(_ difficulty: Difficulty) -> Bool {
        switch (self, difficulty) {
        case (.easy, .easy), (.medium, .medium), (.hard, .hard):
            return true
        default:
            // right now we allow "loose" match – you can tighten this later
            return true
        }
    }
}
