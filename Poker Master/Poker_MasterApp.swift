//
//  Poker_MasterApp.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/11/24.
//

import SwiftUI
import SwiftData

@main
struct Poker_MasterApp: App {
    init() {
        RangesFileManager.loadInitialRangesIfNeeded()  // Ensure the file is copied from bundle to Documents directory
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.font, .custom("Exo2-Regular", size: 18))
        }
        .modelContainer(sharedModelContainer)
    }
}
