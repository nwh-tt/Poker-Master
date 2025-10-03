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
                print("Fetched user: \(firstProfile.username)")
            } else {
                print("No user found, creating default user")
                // Create a default user if none exists
                let newProfile = Profile(username: "DefaultUser")
                context.insert(newProfile)
                try context.save()
                self.profile = newProfile
            }
        } catch {
            fatalError("Failed to fetch or create profile: \(error)")
        }
    }
    
    func addXP(_ amount: Int) {
        profile.addXP(amount: amount)
        // Save to context if needed
    }
}
