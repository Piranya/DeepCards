import SwiftUI
import SwiftData

@Model
final class Card {
  @Attribute(.unique) var id: UUID
  var texts: [String: String] // languageCode: text
  
  init(id: UUID = UUID(), texts: [String: String]) {
    self.id = id
    self.texts = texts
  }
}

struct CardsView: View {
  @Query private var cards: [Card]
  @State private var currentIndex = 0
  
  var body: some View {
    VStack(spacing: 20) {
      if !cards.isEmpty {
        Text(bestText(for: cards[currentIndex]))
          .font(.title)
          .padding()
        
        HStack {
          Button("Previous") {
            if currentIndex > 0 {
              currentIndex -= 1
            }
          }
          .disabled(currentIndex == 0)
          
          Spacer()
          
          Button("Next") {
            if currentIndex < cards.count - 1 {
              currentIndex += 1
            }
          }
          .disabled(currentIndex == cards.count - 1)
        }
        .padding(.horizontal, 40)
      } else {
        Text("No cards available")
          .font(.title2)
          .foregroundColor(.secondary)
      }
    }
    .padding()
  }
  
  private func bestText(for card: Card) -> String {
    let lang = Locale.current.language.languageCode?.identifier ?? "en"
    if let exactMatch = card.texts[lang] {
      return exactMatch
    }
    // fallback to any available text
    return card.texts.values.first ?? ""
  }
}

#Preview {
  let modelContainer = try! ModelContainer(for: Card.self, inMemory: true)
  let context = modelContainer.mainContext
  
  let card1 = Card(texts: ["en": "Hello", "es": "Hola", "fr": "Bonjour"])
  let card2 = Card(texts: ["en": "Goodbye", "de": "Auf Wiedersehen"])
  let card3 = Card(texts: ["ja": "こんにちは", "en": "Hi"])
  
  context.insert(card1)
  context.insert(card2)
  context.insert(card3)
  
  try? context.save()
  
  return CardsView()
    .modelContainer(modelContainer)
}
