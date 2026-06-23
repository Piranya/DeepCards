//
//  DeepCardsApp.swift
//  DeepCards
//
//  Created by Nick on 03/06/2026.
//

import SwiftUI
import SwiftData

@main
struct DeepCardsApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            DeckCard.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.sharedModelContainer = container
            Task { @MainActor in
                let context = ModelContext(container)
                print("[Seeding] Starting initial data seed…")
                do {
                    try CardLoader.removeAllCards(in: context)

                    try await CardLoader.seedIfNeeded(in: context)
                    print("[Seeding] Completed successfully!")
                    let existing = try context.fetch(FetchDescriptor<DeckCard>())
                      guard existing.isEmpty else { return }
                    print("[Seeding] Existing DeckCard count: \(existing.count)")
                } catch {
                    print("[Seeding] Failed with error: \(error)")
                }
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CardsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 165 / 255, green: 166 / 255, blue: 212 / 255),
                                Color(red: 77 / 255, green: 170 / 255, blue: 94 / 255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    )
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    
}
