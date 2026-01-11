//
//  UserProfileState.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/29/25.
//

import Foundation
import SwiftData

@MainActor
class UserProfileState: ObservableObject {
    @Published var profile: Profile
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
        do {
            let fetchDescriptor = FetchDescriptor<Profile>(predicate: nil)
            let profiles = try context.fetch(fetchDescriptor)
            if let firstProfile = profiles.first {
                self.profile = firstProfile
                Log.app.info("Fetched user: \(firstProfile.username, privacy: .private)")
            } else {
                Log.app.info("No user found, creating default user")
                // Create a default user if none exists
                let newProfile = Profile(username: "DefaultUser")
                context.insert(newProfile)
                try context.save()
                self.profile = newProfile
            }
        } catch {
            Log.app.fault("Failed to fetch or create profile: \(error, privacy: .public)")
            fatalError("Failed to fetch or create profile \(error)")
        }
    }
    
    func addXP(_ amount: Int) {
        profile.addXP(amount: amount)
    }

    func equityHandsCount(for date: Date = Date()) -> Int {
        let cutoff = Calendar.current.startOfDay(for: date)
        let predicate = #Predicate<EquityLog> { $0.date >= cutoff }
        let descriptor = FetchDescriptor<EquityLog>(predicate: predicate)
        do {
            return try context.fetch(descriptor).count
        } catch {
            Log.data.error("Failed to fetch equity logs: \(error, privacy: .private)")
            return 0
        }
    }

    func aiHandsCount(for date: Date = Date()) -> Int {
        let cutoff = Calendar.current.startOfDay(for: date)
        let predicate = #Predicate<AIGameLog> { $0.date >= cutoff }
        let descriptor = FetchDescriptor<AIGameLog>(predicate: predicate)
        do {
            return try context.fetch(descriptor).count
        } catch {
            Log.data.error("Failed to fetch AI logs: \(error, privacy: .private)")
            return 0
        }
    }

    func hitEquityLimit(isSubscribed: Bool, for date: Date = Date()) -> Bool {
        guard !isSubscribed else { return false } // If user is subscribed no limit applies
        return equityHandsCount(for: date) >= 20
    }

    func hitAILimit(isSubscribed: Bool, for date: Date = Date()) -> Bool {
        guard !isSubscribed else { return false } // If user is subscribed no limit applies
        return aiHandsCount(for: date) >= 20
    }
}
