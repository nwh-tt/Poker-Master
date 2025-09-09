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
    @StateObject var userProfile: UserProfileState
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            User.self,
            Challenges.self,
            Game.self,
            HandLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        RangesFileManager.loadInitialRangesIfNeeded()  // Ensure the file is copied from bundle to Documents directory
        let context = ModelContext(sharedModelContainer)
        _userProfile = StateObject(wrappedValue: UserProfileState(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(userProfile)
                .task {    // This runs once when ContentView appears
                    let context = ModelContext(sharedModelContainer)
                    await ChallengeDataManager.syncDefaultChallenges(context: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
