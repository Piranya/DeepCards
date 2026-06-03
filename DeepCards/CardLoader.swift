import Foundation
import SwiftData

struct CardDTO: Decodable {
    let id: String
    let question: String
    let categoryName: String
    let categoryId: String
    let translations: [String: String]?
}

@MainActor
final class CardLoader {
    static func seedIfNeeded(in context: ModelContext) async throws {
        let fetchRequest = FetchDescriptor<DeckCard>()
        let existing = try context.fetch(fetchRequest)
        guard existing.isEmpty else { return }

        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json") else {
            throw NSError(domain: "CardLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "cards.json not found"])
        }
        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([CardDTO].self, from: data)

        for dto in dtos {
            // Build texts dictionary from translations, falling back to question for "en"
            var texts = dto.translations ?? [:]
            if texts["en"].map({ !$0.isEmpty }) != true {
                texts["en"] = dto.question
            }
            let deckCard = DeckCard(texts: texts)
            context.insert(deckCard)
        }
        try context.save()
    }
}
