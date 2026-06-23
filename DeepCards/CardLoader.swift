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

        guard existing.isEmpty else {
            print("[Seeding] data already seeded")
            return
        }

        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json") else {
            throw NSError(
                domain: "CardLoader",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "cards.json not found"]
            )
        }

        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([CardDTO].self, from: data)
        var seenQuestions = Set<String>()
        
        for dto in dtos {

            // Clean question
            let question = dto.question
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\r\n", with: "\n")

            guard !question.isEmpty else {
                print("[Seeding] skipping card with empty question")
                continue
            }

            // Clean translations
            var texts: [String: String] = [:]

            for (lang, value) in (dto.translations ?? [:]) {
                let cleaned = value
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\r\n", with: "\n")

                guard !cleaned.isEmpty else { continue }

                texts[lang.lowercased()] = cleaned
            }

            // Fallback English text
            if texts["en"]?.isEmpty ?? true {
                texts["en"] = question
            }
            
            let key = question.lowercased()

            guard seenQuestions.insert(key).inserted else {
                print("[Seeding] duplicate question skipped: \(question)")
                continue
            }

            let deckCard = DeckCard(texts: texts, categoryName: dto.categoryName)
            context.insert(deckCard)
        }

        try context.save()
    }
}

extension CardLoader {

    static func removeAllCards(in context: ModelContext) throws {
        try context.delete(model: DeckCard.self)
        try context.save()

        print("[CardLoader] All cards removed")
    }
}
