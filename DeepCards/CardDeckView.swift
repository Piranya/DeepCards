import SwiftUI
import SwiftData

@Model
final class DeckCard {
  @Attribute(.unique) var id: UUID
  var texts: [String: String] // languageCode: text
  var decision: Decision?

  init(id: UUID = UUID(), texts: [String: String], decision: Decision? = nil) {
    self.id = id
    self.texts = texts
    self.decision = decision
  }

  enum Decision: String, Codable, CaseIterable {
    case yes = "Yes"
    case dialogue = "Dialogue"
    case no = "No"
  }
}

struct CardsView: View {
  @Query private var cards: [DeckCard]
  @State private var currentIndex = 0
  @State private var selectedFilter: DeckCard.Decision? = nil
  @State private var orderedCards: [DeckCard] = []

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Menu {
          Button(role: .destructive, action: resetDecisions) {
            Label("Reset", systemImage: "arrow.counterclockwise")
          }
        } label: {
          Image(systemName: "line.3.horizontal")
            .imageScale(.large)
            .padding(8)
        }
        Spacer()
      }
      .padding(.bottom, 2)

      // Filter bar
      HStack(spacing: 12) {
        filterButton(for: nil, title: "Unsorted", color: .gray, count: unsortedCount)
        filterButton(for: .yes, title: DeckCard.Decision.yes.rawValue, color: .green, count: yesCount)
        filterButton(for: .dialogue, title: DeckCard.Decision.dialogue.rawValue, color: .orange, count: dialogueCount)
        filterButton(for: .no, title: DeckCard.Decision.no.rawValue, color: .red, count: noCount)
      }
      .padding(.vertical, 4)

      if allCardsCategorized && filteredCards.isEmpty {
        VStack(spacing: 16) {
          Text("No more cards")
            .font(.title2)
            .multilineTextAlignment(.center)
            .padding(.bottom, 8)
        }
        .padding()
      } else if !filteredCards.isEmpty {
        Text(bestText(for: filteredCards[currentIndex]))
          .font(.title)
          .padding()

        // Decision buttons
        HStack(spacing: 16) {
          decisionButton(title: DeckCard.Decision.yes.rawValue, decision: .yes, color: .green)
          decisionButton(title: DeckCard.Decision.dialogue.rawValue, decision: .dialogue, color: .orange)
          decisionButton(title: DeckCard.Decision.no.rawValue, decision: .no, color: .red)
        }

        HStack {
          Button("Previous") {
            if currentIndex > 0 { currentIndex -= 1 }
          }
          .disabled(currentIndex == 0)

          Spacer()

          Button("Next") {
            if currentIndex < filteredCards.count - 1 { currentIndex += 1 }
          }
          .disabled(currentIndex == filteredCards.count - 1)
        }
        .padding(.horizontal, 40)
      } else {
        Text("No cards available")
          .font(.title2)
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .onAppear {
      if orderedCards.isEmpty {
        orderedCards = cards.shuffled()
      }
    }
    // Removed the toolbar Menu showing filter buttons
  }

  @Environment(\.modelContext) private var context

  private var filteredCards: [DeckCard] {
    let source = orderedCards.isEmpty ? cards : orderedCards
    if let selectedFilter {
      return source.filter { $0.decision == selectedFilter }
    } else {
      return source.filter { $0.decision == nil }
    }
  }

  private var allCardsCategorized: Bool {
    return !cards.isEmpty && cards.allSatisfy { $0.decision != nil }
  }

  private func filterButton(for decision: DeckCard.Decision?, title: String, color: Color, count: Int) -> some View {
    let isSelected = selectedFilter == decision
    return Button {
      applyFilter(decision)
    } label: {
      if isSelected {
        Label("\(title) (\(count))", systemImage: "checkmark")
          .frame(minWidth: 80)
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(.thinMaterial)
          .cornerRadius(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.accentColor, lineWidth: 2)
          )
          .foregroundColor(color)
          .minimumScaleFactor(0.75)
      } else {
        Text("\(title) (\(count))")
          .frame(minWidth: 80)
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(Color.clear)
          .cornerRadius(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(color.opacity(0.6), lineWidth: 1)
          )
          .foregroundColor(color)
          .minimumScaleFactor(0.75)
      }
    }
    .buttonStyle(.bordered)
  }

  private func decisionButton(title: String, decision: DeckCard.Decision, color: Color) -> some View {
    let isSelected = !filteredCards.isEmpty && filteredCards[currentIndex].decision == decision
    return Button(title) {
      guard !filteredCards.isEmpty else { return }
      let card = filteredCards[currentIndex]
      card.decision = decision
      try? context.save()

      // Refresh the orderedCards to keep everything in sync
      orderedCards = cards.shuffled()

      // Update filteredCards and move currentIndex appropriately
      let newFiltered = {
        let source = orderedCards.isEmpty ? cards : orderedCards
        if let selectedFilter {
          return source.filter { $0.decision == selectedFilter }
        } else {
          return source.filter { $0.decision == nil }
        }
      }()
      if newFiltered.isEmpty {
        currentIndex = 0
      } else if currentIndex >= newFiltered.count {
        currentIndex = newFiltered.count - 1
      }
    }
    .buttonStyle(.borderedProminent)
    .tint(color)
    .opacity(isSelected ? 1.0 : 0.7)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(isSelected ? Color.accentColor : .clear, lineWidth: isSelected ? 2 : 0)
    )
  }

  private func applyFilter(_ decision: DeckCard.Decision?) {
    selectedFilter = decision
    currentIndex = 0
  }

  private func resetDecisions() {
    for card in cards {
      card.decision = nil
    }
    try? context.save()
    orderedCards = cards.shuffled()
    selectedFilter = nil
    currentIndex = 0
  }

  private func bestText(for card: DeckCard) -> String {
    let lang = Locale.current.language.languageCode?.identifier ?? "en"
    if let exactMatch = card.texts[lang] {
      return exactMatch
    }
    // fallback to any available text
    return card.texts.values.first ?? ""
  }

  private var unsortedCount: Int { (orderedCards.isEmpty ? cards : orderedCards).filter { $0.decision == nil }.count }
  private var yesCount: Int { (orderedCards.isEmpty ? cards : orderedCards).filter { $0.decision == .yes }.count }
  private var dialogueCount: Int { (orderedCards.isEmpty ? cards : orderedCards).filter { $0.decision == .dialogue }.count }
  private var noCount: Int { (orderedCards.isEmpty ? cards : orderedCards).filter { $0.decision == .no }.count }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: DeckCard.self, configurations: config)
  return PreviewCardsView()
    .modelContainer(container)
}

private struct PreviewCardsView: View {
  @Environment(\.modelContext) private var context

  init() {
    // no-op init so we can perform setup in body via .task
  }

  var body: some View {
    CardsView()
      .task {
        // Insert sample data once for previews
        if ((try? context.fetch(FetchDescriptor<DeckCard>()).isEmpty == true) != nil) {
          let card1 = DeckCard(texts: ["en": "Hello", "es": "Hola", "fr": "Bonjour"], decision: .yes)
          let card2 = DeckCard(texts: ["en": "Goodbye", "de": "Auf Wiedersehen"], decision: .dialogue)
          let card3 = DeckCard(texts: ["ja": "こんにちは", "en": "Hi"], decision: .no)
          context.insert(card1)
          context.insert(card2)
          context.insert(card3)
          try? context.save()
        }
      }
  }
}
