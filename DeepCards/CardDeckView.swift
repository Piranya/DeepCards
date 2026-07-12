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
  
  @State private var selectedCategories: Set<String> = []
  @State private var allCategories: [String] = []
  @State private var deckCardsMirror: [DeckCard] = []
  @State private var deckEntrancePhase: Double = 0
  @State private var navTransitionOffset: CGFloat = 0

  private var filteredCards: [DeckCard] {
    let source = orderedCards.isEmpty ? cards : orderedCards
    // Base filters: unsorted or decision
    let base: [DeckCard]
    if showUnsortedOnly {
      base = source.filter { $0.decision == nil }
    } else if let selectedFilter {
      base = source.filter { $0.decision == selectedFilter }
    } else {
      base = source
    }
    // Category filter: if not all selected, filter to selectedCategories
    if !selectedCategories.isEmpty && selectedCategories.count != allCategories.count {
      return base.filter { card in
        let name = card.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return selectedCategories.contains(name)
      }
    }
    return base
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
          filterBar
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 10)
            .frame(width: contentWidth)
            .padding()
        if allCardsCategorized && filteredCards.isEmpty {
          // Automatically reshuffle and re-enter when all filtered cards are consumed
          Color.clear
            .onAppear {
              reshuffleAndReenterDeck()
            }
        } else if !filteredCards.isEmpty {
            
            
          GenericCardDeck(cards: $deckCardsMirror, visibleCards: 3, entrancePhase: deckEntrancePhase, navOffset: navTransitionOffset, onDeckEmpty: { reshuffleAndReenterDeck() }) { item in
            VStack(spacing: 18) {
              Text(categoryName(for: item))
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)

              Spacer(minLength: 0)

              Text(bestText(for: item))
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
            .background(
              RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(colorForCategory(item.categoryName))
            )
            .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
          }
          .onAppear {
            deckCardsMirror = Array(filteredCards.prefix(10))
            deckEntrancePhase = 0
            withAnimation(.spring(response: 1.6, dampingFraction: 0.78)) {
              deckEntrancePhase = 1
            }
          }

          // Decision buttons
          HStack(spacing: controlSpacing) {
            decisionButton(title: DeckCard.Decision.no.rawValue, decision: .no, color: .red)
            decisionButton(title: DeckCard.Decision.dialogue.rawValue, decision: .dialogue, color: .orange)
            decisionButton(title: DeckCard.Decision.yes.rawValue, decision: .yes, color: .green)
          }
          .frame(width: contentWidth)

//          HStack {
//            cardNavigationButton(systemName: "chevron.left", accessibilityLabel: "Previous card", action: showPreviousCard)
//              .disabled(currentIndex == 0)
//
//            Spacer()
//
//            cardNavigationButton(systemName: "chevron.right", accessibilityLabel: "Next card", action: showNextCard)
//              .disabled(currentIndex == filteredCards.count - 1)
//          }
//          .frame(width: contentWidth)z
        } else {
          Text("No cards available")
            .font(.title2)
            .foregroundColor(.secondary)
        }

        Spacer(minLength: 0)
      }
 

    
    }
    .ignoresSafeArea(.keyboard)
    .onAppear {
      if orderedCards.isEmpty {
        orderedCards = cards.shuffled()
      }
      selectedTab = selectedFilter != nil ? FilterTag(decision: selectedFilter!) ?? .unsorted : .unsorted
      showUnsortedOnly = (selectedFilter == nil)
      
      let names = Set((orderedCards.isEmpty ? cards : orderedCards).compactMap { $0.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
      allCategories = names.sorted()
      
      // Default: All selected
      if selectedCategories.isEmpty { selectedCategories = Set(allCategories) }
    }
    .onChange(of: filteredCards) { _, newValue in
            withAnimation(.easeInOut(duration: 0.25)) {
                deckCardsMirror = Array(newValue.prefix(10))
            }
    }
    .toolbar {
      #if os(macOS)
      // Removed macOS filter picker toolbar item as per instructions
      #endif

      ToolbarItem(placement: .automatic) {
        Menu {
          Section("Topics") {
            // Categories
            ForEach(allCategories, id: \.self) { name in
              Button(action: { toggleCategory(name) }) {
                HStack(spacing: 8) {
                  ZStack {
                    Circle()
                      .stroke(colorForCategory(name), lineWidth: 2)
                      .frame(width: 16, height: 16)
                    if selectedCategories.contains(name) {
                      Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(colorForCategory(name))
                        .font(.system(size: 14))
                    }
                  }
                  Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                  Spacer()
                }
              }
            }
          }
          Section {
            Button(role: .destructive, action: resetDecisions) {
              Label("Reset", systemImage: "arrow.counterclockwise")
            }
          }
        } label: {
          Image(systemName: "line.3.horizontal")
            .imageScale(.large)
        }
      }
    }
  }

  @Environment(\.modelContext) private var context

    private func reshuffleAndReenterDeck() {
        print("ReshuffleAndReenterDeck")

        orderedCards = cards.shuffled()
        currentIndex = 0
        deckEntrancePhase = 0

        let source = orderedCards

        let base: [DeckCard]
        if showUnsortedOnly {
            base = source.filter { $0.decision == nil }
        } else if let selectedFilter {
            base = source.filter { $0.decision == selectedFilter }
        } else {
            base = source
        }

        let final: [DeckCard]
        if !selectedCategories.isEmpty &&
            selectedCategories.count != allCategories.count {

            final = base.filter { card in
                let name = card.categoryName?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return selectedCategories.contains(name)
            }

        } else {
            final = base
        }

        // Clear first so SwiftUI sees a real change
        deckCardsMirror.removeAll()

        DispatchQueue.main.async {

            self.deckCardsMirror = Array(final.prefix(10))

            withAnimation(.spring(response: 1.6,
                                  dampingFraction: 0.78)) {
                self.deckEntrancePhase = 1
            }
        }
    }

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
    .background(
      RoundedRectangle(cornerRadius: cardCornerRadius)
        .fill(colorForCategory(card.categoryName))
    )
    .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    .gesture(cardSwipeGesture)
  }

  private func cardNavigationButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.title3.weight(.semibold))
        .frame(width: 48, height: 48)
        .foregroundStyle(Color.white)
        .contentShape(Circle())
        .background(.thinMaterial)
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
    guard currentIndex > 0 else { return }
    withAnimation(.easeInOut(duration: 1.4)) { navTransitionOffset = -120 }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
      currentIndex -= 1
      withAnimation(.easeInOut(duration: 1.4)) { navTransitionOffset = 0 }
    }
  }

  private func showNextCard() {
    if currentIndex >= filteredCards.count - 1 {
      // At the end for the current filter, reshuffle and re-enter
      return
    }
    withAnimation(.easeInOut(duration: 1.4)) { navTransitionOffset = 120 }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
      currentIndex += 1
      withAnimation(.easeInOut(duration: 1.4)) { navTransitionOffset = 0 }
    }
  }

  private var filterBar: some View {
    GeometryReader { geo in
      let barFrame = geo.frame(in: .local)

      HStack(spacing: 12) {
        filterChip(title: "Unsorted", color: .accentColor, count: unsortedCount, isSelected: showUnsortedOnly) {
          performSelectionHaptic(); applyUnsortedFilter()
        }
        .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .unsorted, rect: anchor)] }
        
          filterChip(title: DeckCard.Decision.no.rawValue, color: .red, count: noCount, isSelected: !showUnsortedOnly && selectedFilter == .no) {
            performSelectionHaptic(); applyFilter(.no)
          }
          .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .no, rect: anchor)] }
          
        filterChip(title: DeckCard.Decision.dialogue.rawValue, color: .orange, count: dialogueCount, isSelected: !showUnsortedOnly && selectedFilter == .dialogue) {
          performSelectionHaptic(); applyFilter(.dialogue)
        }
        .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .dialogue, rect: anchor)] }
          
          
        filterChip(title: DeckCard.Decision.yes.rawValue, color: .green, count: yesCount, isSelected: !showUnsortedOnly && selectedFilter == .yes) {
          performSelectionHaptic(); applyFilter(.yes)
        }
        .anchorPreference(key: ChipAnchorFramesKey.self, value: .bounds) { anchor in [ChipAnchorFrame(id: .yes, rect: anchor)] }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .frame(width: contentWidth)
      
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
          .foregroundStyle(Color.white)
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .frame(minWidth: 56)
          .background(
            {
              let fillColor: Color = {
              return isSelected ? color.opacity(0.8) : color.opacity(0.5)
              }()
              return RoundedRectangle(cornerRadius: 12)
                .fill(fillColor)
            }()
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

      // Apply category selection bounds after decision changes
      let baseSource = orderedCards.isEmpty ? cards : orderedCards
      let base: [DeckCard]
      if showUnsortedOnly {
        base = baseSource.filter { $0.decision == nil }
      } else if let selectedFilter {
        base = baseSource.filter { $0.decision == selectedFilter }
      } else {
        base = baseSource
      }
      let final: [DeckCard]
      if !selectedCategories.isEmpty && selectedCategories.count != allCategories.count {
        final = base.filter { card in
          let name = card.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
          return selectedCategories.contains(name)
        }
      } else {
        final = base
      }
      if final.isEmpty { currentIndex = 0 }
      else if currentIndex >= final.count { currentIndex = max(0, final.count - 1) }
    } label: {
      VStack(spacing: 8) {
        Text(title)
          .font(.headline.weight(.semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Image(systemName: decisionIconName(for: decision))
          .font(.title2.weight(.bold))
      }
      .foregroundStyle(Color.white)
      .frame(width: decisionButtonWidth, height: 84)
//      .contentShape(RoundedRectangle(cornerRadius: cardCornerRadius))
      .background(
        RoundedRectangle(cornerRadius: cardCornerRadius)
          .fill(isSelected ? color.opacity(0.8) : color.opacity(0.50))
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

  private func toggleCategory(_ name: String) {
    if selectedCategories.contains(name) {
      selectedCategories.remove(name)
    } else {
      selectedCategories.insert(name)
    }
    // If after toggling, none are selected, keep it as empty (show no categories)
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

  private func colorForCategory(_ name: String?) -> Color {
    let key = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    switch key {
    case "finances":
      return Color(red: 206/255, green: 182/255, blue: 119/255)
    case "family":
      return Color(red: 206/255, green: 182/255, blue: 119/255)
    case "honesty":
      return Color(red: 134/255, green: 127/255, blue: 171/255)
    case "sexuality":
      return Color(red: 182/255, green: 114/255, blue: 118/255)
    case "living together":
      return Color(red: 186/255, green: 158/255, blue: 155/255)
    case "free time":
      return Color(red: 189/255, green: 135/255, blue: 111/255)
    case "scenarios":
      return Color(red: 104/255, green: 162/255, blue: 133/255)
    default:
      return Color(red: 134/255, green: 127/255, blue: 171/255)
    }
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

  private var unsortedCount: Int {
    let source = (orderedCards.isEmpty ? cards : orderedCards)
    let base = source.filter { $0.decision == nil }
    if !selectedCategories.isEmpty && selectedCategories.count != allCategories.count {
      return base.filter { card in
        let name = card.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return selectedCategories.contains(name)
      }.count
    }
    return base.count
  }
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



private struct CardLayer<Content: View>: View {
  let index: Int
  let drag: CGSize
  let isTop: Bool
  let entrancePhase: Double
  let navOffset: CGFloat
  let content: () -> Content

  var body: some View {
    let baseOffsetY: CGFloat = 160 + CGFloat(index) * 24
    let animatedOffsetY = (1 - entrancePhase) * baseOffsetY
    content()
      .opacity(entrancePhase)
      .offset(x: (isTop ? drag.width : 0) + (isTop ? navOffset : 0),
              y: (isTop ? drag.height : 0) + animatedOffsetY)
      .rotationEffect(.degrees(isTop ? Double(drag.width / 15) : 0))
      .scaleEffect(isTop ? 1.0 : 1.0 - (CGFloat(index) * 0.04))
      .offset(y: CGFloat(index) * 8)
      .animation(.spring(response: 0.32, dampingFraction: 0.85), value: drag)
  }
}

private struct GenericCardDeck<Data: Identifiable, Content: View>: View {
  @Binding var cards: [Data]
  let visibleCards: Int
  let entrancePhase: Double
  let navOffset: CGFloat
  let onDeckEmpty: (() -> Void)?
  let content: (Data) -> Content

  @GestureState private var drag: CGSize = .zero

  init(
    cards: Binding<[Data]>,
    visibleCards: Int = 3,
    entrancePhase: Double,
    navOffset: CGFloat,
    onDeckEmpty: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Data) -> Content
  ) {
    _cards = cards
    self.visibleCards = visibleCards
    self.entrancePhase = entrancePhase
    self.navOffset = navOffset
    self.onDeckEmpty = onDeckEmpty
    self.content = content
  }

  var body: some View {
    ZStack {
      ForEach(Array(cards.prefix(visibleCards).enumerated()), id: \.element.id) { index, card in
        CardLayer(index: index, drag: drag, isTop: index == 0, entrancePhase: entrancePhase, navOffset: navOffset) {
          content(card)
        }
        .gesture(index == 0 ? dragGesture : nil)
        .zIndex(Double(visibleCards - index))
      }
    }
  }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($drag) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let threshold: CGFloat = 140
                guard abs(value.translation.width) > threshold else { return }

                withAnimation(.spring(response: 0.42,
                                      dampingFraction: 0.85)) {

                    guard !cards.isEmpty else { return }

                    cards.removeFirst()

                    // If that was the last visible card,
                    // notify the parent so it can rebuild the deck.
                    if cards.isEmpty {
                        DispatchQueue.main.async {
                            onDeckEmpty?()
                        }
                    }
                }
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
