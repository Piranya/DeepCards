import Foundation
import SwiftData

struct CardDTO: Decodable {
    let id: UUID
    let question: String
    let categoryName: String
    let categoryId: UUID
    let translations: [String: String]?
}

@MainActor
final class CardLoader {
    static func seedIfNeeded(in context: ModelContext) async throws {
        let fetchRequest = FetchDescriptor<Card>()
        let existing = try context.fetch(fetchRequest)
        guard existing.isEmpty else { return }

        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json") else {
            throw NSError(domain: "CardLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "cards.json not found"])
        }
        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([CardDTO].self, from: data)

        for dto in dtos {
            let card = Card(id: dto.id, question: dto.question, categoryName: dto.categoryName, categoryId: dto.categoryId, translations: dto.translations)
            context.insert(card)
        }
        try await context.save()
    }
}
