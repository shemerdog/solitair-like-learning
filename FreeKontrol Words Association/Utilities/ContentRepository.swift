import Foundation

final class ContentRepository {
    static let shared = ContentRepository()
    
    let tags: [TagDefinition]
    let words: [WordDefinition]
    
    private init() {
        self.tags = Self.load("tags.json")
        self.words = Self.load("words.json")
    }
    
    private static func load<T: Decodable>(_ filename: String) -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("Missing resource: \(filename)")
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode \(filename): \(error)")
        }
    }
}
