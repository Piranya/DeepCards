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
  @State private var selectedTab: FilterTag = .unsorted
  @State private var chipFrames: [ChipFrame] = []
  @State private var showUnsortedOnly: Bool = true

  private var filteredCards: [DeckCard] {
    let source = orderedCards.isEmpty ? cards : orderedCards
    if showUnsortedOnly {
      return source.filter { $0.decision == nil }
    }
    if let selectedFilter {
      return source.filter { $0.decision == selectedFilter }
    } else {
      return source
    }
  }

  private let contentWidth: CGFloat = 320
  private let cardCornerRadius: CGFloat = 24
  private let controlSpacing: CGFloat = 8

  private var decisionButtonWidth: CGFloat {
    (contentWidth - controlSpacing * 2) / 3
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      // Main content
      VStack(spacing: 20) {
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

        Spacer(minLength: 0)
      }
      .padding()

      // Floating bottom filter bar overlay
      bottomFilterBar
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 10)
    }
    .ignoresSafeArea(.keyboard)
    .onAppear {
      if orderedCards.isEmpty {
        orderedCards = cards.shuffled()
      }
      selectedTab = selectedFilter != nil ? FilterTag(decision: selectedFilter!) ?? .unsorted : .unsorted
      showUnsortedOnly = (selectedFilter == nil)
    }
    .toolbar {
      #if os(macOS)
      // Removed macOS filter picker toolbar item as per instructions
      #endif

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

  private var bottomFilterBar: some View {
    GeometryReader { geo in
      let barFrame = geo.frame(in: .local)

      HStack(spacing: 12) {
        filterChip(title: "Unsorted", color: .accentColor, count: unsortedCount, isSelected: showUnsortedOnly) {
          performSelectionHaptic(); applyUnsortedFilter()
        }
        .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .unsorted, rect: anchor)] }

        filterChip(title: DeckCard.Decision.yes.rawValue, color: .green, count: yesCount, isSelected: !showUnsortedOnly && selectedFilter == .yes) {
          performSelectionHaptic(); applyFilter(.yes)
        }
        .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .yes, rect: anchor)] }

        filterChip(title: DeckCard.Decision.dialogue.rawValue, color: .orange, count: dialogueCount, isSelected: !showUnsortedOnly && selectedFilter == .dialogue) {
          performSelectionHaptic(); applyFilter(.dialogue)
        }
        .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .dialogue, rect: anchor)] }

        filterChip(title: DeckCard.Decision.no.rawValue, color: .red, count: noCount, isSelected: !showUnsortedOnly && selectedFilter == .no) {
          performSelectionHaptic(); applyFilter(.no)
        }
        .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .no, rect: anchor)] }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 18)
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
      )
      .frame(width: barFrame.width, alignment: .center)
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            updateSelection(at: value.location, in: geo)
          }
      )
      .onTapGesture { location in
        updateSelection(at: location, in: geo)
        performSelectionHaptic()
      }
      .overlayPreferenceValue(ChipAnchorFramesKey.self) { anchorFrames in
        GeometryReader { innerGeo in
          Color.clear
            .onAppear {
              chipFrames = anchorFrames.map { ChipFrame(id: $0.id, rect: innerGeo[$0.rect]) }
            }
            .onChange(of: anchorFrames) { _, newValue in
              chipFrames = newValue.map { ChipFrame(id: $0.id, rect: innerGeo[$0.rect]) }
            }
        }
      }
    }
    .frame(height: 56)
  }

  private enum ChipID: Hashable { case unsorted, yes, dialogue, no }

  private struct ChipAnchorFrame: Equatable { let id: ChipID; let rect: Anchor<CGRect> }
  private struct ChipAnchorFramesKey: PreferenceKey {
    static var defaultValue: [ChipAnchorFrame] = []
    static func reduce(value: inout [ChipAnchorFrame], nextValue: () -> [ChipAnchorFrame]) {
      value += nextValue()
    }
  }

  private struct ChipFrame: Equatable { let id: ChipID; let rect: CGRect }

  private struct ChipFramesKey: PreferenceKey {
    static var defaultValue: [ChipFrame] = []
    static func reduce(value: inout [ChipFrame], nextValue: () -> [ChipFrame]) {
      value += nextValue()
    }
  }

  private func updateSelection(at location: CGPoint, in geo: GeometryProxy) {
    for chip in chipFrames {
      if chip.rect.contains(location) {
        switch chip.id {
        case .unsorted:
          if !showUnsortedOnly { applyUnsortedFilter() }
        case .yes:
          if selectedFilter != .yes || showUnsortedOnly { applyFilter(.yes) }
        case .dialogue:
          if selectedFilter != .dialogue || showUnsortedOnly { applyFilter(.dialogue) }
        case .no:
          if selectedFilter != .no || showUnsortedOnly { applyFilter(.no) }
        }
        return
      }
    }
  }

  private func filterChip(title: String, color: Color, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      ZStack(alignment: .topTrailing) {
        Text(title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(color)
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .frame(minWidth: 56)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .glassEffect(
                isSelected ? .regular.tint(color.opacity(0.18)).interactive() : .regular.interactive(),
                in: .rect(cornerRadius: 12)
              )
          )
          .contentShape(RoundedRectangle(cornerRadius: 12))

        if count > 0 {
          ZStack {
            Circle().fill(Color.red)
            Text("\(count)")
              .font(.caption2.weight(.bold))
              .foregroundColor(.white)
          }
          .frame(width: 16, height: 16)
          .offset(x: 8, y: -6)
          .transition(.scale(scale: 0.85).combined(with: .opacity))
          .animation(.spring(response: 0.25, dampingFraction: 0.8), value: count)
          .accessibilityLabel("\(count) cards")
        }
      }
    }
    .buttonStyle(.plain)
  }

  private func performSelectionHaptic() {
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    #endif
  }

  private func title(for decision: DeckCard.Decision?) -> String {
    switch decision {
    case .yes: return DeckCard.Decision.yes.rawValue
    case .dialogue: return DeckCard.Decision.dialogue.rawValue
    case .no: return DeckCard.Decision.no.rawValue
    case nil: return "?"
    }
  }

  private func color(for decision: DeckCard.Decision?) -> Color {
    switch decision {
    case .yes: return .green
    case .dialogue: return .orange
    case .no: return .red
    case nil: return .gray
    }
  }

  private func count(for decision: DeckCard.Decision?) -> Int {
    switch decision {
    case .yes: return yesCount
    case .dialogue: return dialogueCount
    case .no: return noCount
    case nil: return unsortedCount
    }
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
        if showUnsortedOnly {
          return source.filter { $0.decision == nil }
        }
        if let selectedFilter {
          return source.filter { $0.decision == selectedFilter }
        } else {
          return source
        }
      }()
      if newFiltered.isEmpty {
        currentIndex = 0
      } else if currentIndex >= newFiltered.count {
        currentIndex = newFiltered.count - 1
      }

      if showUnsortedOnly {
        let source = orderedCards.isEmpty ? cards : orderedCards
        let unsorted = source.filter { $0.decision == nil }
        if unsorted.isEmpty { currentIndex = 0 }
        else if currentIndex >= unsorted.count { currentIndex = max(0, unsorted.count - 1) }
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
    showUnsortedOnly = (decision == nil)
    selectedTab = decision != nil ? FilterTag(decision: decision!) ?? .unsorted : .unsorted
    currentIndex = 0
  }

  private func applyUnsortedFilter() {
    showUnsortedOnly = true
    selectedFilter = nil
    selectedTab = .unsorted
    currentIndex = 0
  }

  private func resetDecisions() {
    for card in cards {
      card.decision = nil
    }
    try? context.save()
    orderedCards = cards.shuffled()
    selectedFilter = nil
    selectedTab = .unsorted
    showUnsortedOnly = true
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
  private var allCount: Int { (orderedCards.isEmpty ? cards : orderedCards).count }

  private var allCardsCategorized: Bool {
    (orderedCards.isEmpty ? cards : orderedCards).allSatisfy { $0.decision != nil }
  }

  enum FilterTag: Hashable {
    case unsorted
    case yes
    case dialogue
    case no

    var decision: DeckCard.Decision? {
      switch self {
      case .unsorted: return nil
      case .yes: return .yes
      case .dialogue: return .dialogue
      case .no: return .no
      }
    }
  }
}

extension CardsView.FilterTag {
  init?(decision: DeckCard.Decision) {
    switch decision {
    case .yes: self = .yes
    case .dialogue: self = .dialogue
    case .no: self = .no
    }
  }
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
