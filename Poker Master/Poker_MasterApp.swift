//
//  Poker_MasterApp.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/11/24.
//

import SwiftUI
import SwiftData
import FirebaseCore
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      
    Purchases.logLevel = .debug
    Purchases.configure(withAPIKey: "appl_GQpXusiTmcOvPDpqshsmiyFesMb")

    return true
  }
}

@main
struct Poker_MasterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userProfile: UserProfileState
    @StateObject private var authManager = AuthManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Profile.self,
            Challenges.self,
            Game.self,
            PreflopLog.self,
            EquityLog.self,
            AIGameLog.self
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
                .environmentObject(authManager)
                .task {
                    // Load in any new challenges created
                    let context = ModelContext(sharedModelContainer)
                    await ChallengeDataManager.syncDefaultChallenges(context: context)
                    
                    // Signs user in anonomously only if needed
                    authManager.ensureSignedIn()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
