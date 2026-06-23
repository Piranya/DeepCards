import SwiftUI
import SwiftData

@Model
final class DeckCard {
  @Attribute(.unique) var id: UUID
  var texts: [String: String] // languageCode: text
  var categoryName: String?
  var decision: Decision?

  init(id: UUID = UUID(), texts: [String: String], categoryName: String? = nil, decision: Decision? = nil) {
    self.id = id
    self.texts = texts
    self.categoryName = categoryName
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

  private let contentWidth: CGFloat = 320
  private let cardCornerRadius: CGFloat = 24
  private let controlSpacing: CGFloat = 8

  private var decisionButtonWidth: CGFloat {
    (contentWidth - controlSpacing * 2) / 3
  }

  var body: some View {
    VStack(spacing: 20) {
      filterNavigationPanel

      if allCardsCategorized && filteredCards.isEmpty {
        VStack(spacing: 16) {
          Text("No more cards")
            .font(.title2)
            .multilineTextAlignment(.center)
            .padding(.bottom, 8)
        }
        .padding()
      } else if !filteredCards.isEmpty {
        activeCard(for: filteredCards[currentIndex])

        // Decision buttons
        HStack(spacing: controlSpacing) {
          decisionButton(title: DeckCard.Decision.no.rawValue, decision: .no, color: .red)
          decisionButton(title: DeckCard.Decision.dialogue.rawValue, decision: .dialogue, color: .orange)
          decisionButton(title: DeckCard.Decision.yes.rawValue, decision: .yes, color: .green)
        }
        .frame(width: contentWidth)

        HStack {
          cardNavigationButton(systemName: "chevron.left", accessibilityLabel: "Previous card", action: showPreviousCard)
            .disabled(currentIndex == 0)

          Spacer()

          cardNavigationButton(systemName: "chevron.right", accessibilityLabel: "Next card", action: showNextCard)
            .disabled(currentIndex == filteredCards.count - 1)
        }
        .frame(width: contentWidth)
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
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Menu {
          Button(role: .destructive, action: resetDecisions) {
            Label("Reset", systemImage: "arrow.counterclockwise")
          }
        } label: {
          Image(systemName: "line.3.horizontal")
            .imageScale(.large)
        }
      }
    }
  }

  @Environment(\.modelContext) private var context

  private func activeCard(for card: DeckCard) -> some View {
    VStack(spacing: 18) {
      Text(categoryName(for: card))
        .font(.caption.weight(.bold))
        .textCase(.uppercase)
        .foregroundStyle(.white.opacity(0.75))
        .lineLimit(1)

      Spacer(minLength: 0)

      Text(bestText(for: card))
        .font(.title2)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .lineLimit(nil)
        .minimumScaleFactor(0.7)

      Spacer(minLength: 0)
    }
    .padding(28)
    .frame(width: contentWidth, height: 260)
    .glassEffect(
      .regular.tint(Color(red: 134 / 255, green: 127 / 255, blue: 171 / 255)),
      in: .rect(cornerRadius: cardCornerRadius)
    )
    .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    .gesture(cardSwipeGesture)
  }

  private func cardNavigationButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.title3.weight(.semibold))
        .frame(width: 48, height: 48)
        .contentShape(Circle())
        .glassEffect(.regular.interactive(), in: .circle)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityLabel)
  }

  private var cardSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 30)
      .onEnded { value in
        handleCardSwipe(value.translation)
      }
  }

  private func handleCardSwipe(_ translation: CGSize) {
    let horizontalDistance = translation.width
    let verticalDistance = translation.height

    guard abs(horizontalDistance) > 60,
          abs(horizontalDistance) > abs(verticalDistance) else {
      return
    }

    if horizontalDistance < 0 {
      showPreviousCard()
    } else {
      showNextCard()
    }
  }

  private func showPreviousCard() {
    if currentIndex > 0 {
      currentIndex -= 1
    }
  }

  private func showNextCard() {
    if currentIndex < filteredCards.count - 1 {
      currentIndex += 1
    }
  }

  private var filterNavigationPanel: some View {
    GlassEffectContainer(spacing: controlSpacing) {
      HStack(spacing: 6) {
        filterButton(for: nil, title: "?", color: .gray, count: unsortedCount)
        filterButton(for: .yes, title: DeckCard.Decision.yes.rawValue, color: .green, count: yesCount)
        filterButton(for: .dialogue, title: DeckCard.Decision.dialogue.rawValue, color: .orange, count: dialogueCount)
        filterButton(for: .no, title: DeckCard.Decision.no.rawValue, color: .red, count: noCount)
      }
      .padding(8)
      .glassEffect(.regular, in: .rect(cornerRadius: 20))
      .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    .padding(.vertical, 4)
  }

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
    let label = "\(title) (\(count))"

    return Button {
      applyFilter(decision)
    } label: {
      HStack(spacing: 4) {
        

        Text(label)
          .font(.caption.weight(.semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      .foregroundStyle(color)
      .padding(.horizontal, 12)
      .frame(minWidth: 44, minHeight: 36)
      .contentShape(RoundedRectangle(cornerRadius: 12))
      .glassEffect(
        isSelected ? .regular.tint(color.opacity(0.18)).interactive() : .regular.interactive(),
        in: .rect(cornerRadius: 12)
      )
    }
    .buttonStyle(.plain)
  }

  private func decisionButton(title: String, decision: DeckCard.Decision, color: Color) -> some View {
    let isSelected = !filteredCards.isEmpty && filteredCards[currentIndex].decision == decision

    return Button {
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
    } label: {
      VStack(spacing: 8) {
        Text(title)
          .font(.headline.weight(.semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Image(systemName: decisionIconName(for: decision))
          .font(.title2.weight(.bold))
      }
      .foregroundStyle(color)
      .frame(width: decisionButtonWidth, height: 84)
      .contentShape(RoundedRectangle(cornerRadius: cardCornerRadius))
      .glassEffect(
        isSelected ? .regular.tint(color.opacity(0.22)).interactive() : .regular.interactive(),
        in: .rect(cornerRadius: cardCornerRadius)
      )
    }
    .buttonStyle(.plain)
    .opacity(isSelected ? 1.0 : 0.9)
  }

  private func decisionIconName(for decision: DeckCard.Decision) -> String {
    switch decision {
    case .yes:
      return "checkmark"
    case .dialogue:
      return "message"
    case .no:
      return "xmark"
    }
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

  private func categoryName(for card: DeckCard) -> String {
    guard let categoryName = card.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines),
          !categoryName.isEmpty else {
      return "Uncategorized"
    }

    return categoryName
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
          let card1 = DeckCard(texts: ["en": "Hello", "es": "Hola", "fr": "Bonjour"], categoryName: "Greetings", decision: .yes)
          let card2 = DeckCard(texts: ["en": "Goodbye", "de": "Auf Wiedersehen"], categoryName: "Farewells", decision: .dialogue)
          let card3 = DeckCard(texts: ["ja": "こんにちは", "en": "Hi"], categoryName: "Introductions", decision: .no)
          context.insert(card1)
          context.insert(card2)
          context.insert(card3)
          try? context.save()
        }
      }
  }
}
