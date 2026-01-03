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
    
    init(context: ModelContext) {
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
}
