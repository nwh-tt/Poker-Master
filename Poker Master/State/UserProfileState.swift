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
    @Published var user: User
    
    init(context: ModelContext) {
        do {
            let fetchDescriptor = FetchDescriptor<User>(predicate: nil)
            let users = try context.fetch(fetchDescriptor)
            if let firstUser = users.first {
                self.user = firstUser
                print("Fetched user: \(firstUser.username)")
            } else {
                print("No user found, creating default user")
                // Create a default user if none exists
                let newUser = User(username: "DefaultUser")
                context.insert(newUser)
                try context.save()
                self.user = newUser
            }
        } catch {
            fatalError("Failed to fetch or create user: \(error)")
        }
    }
    
    func addXP(_ amount: Int) {
        user.addXP(amount: amount)
        // Save to context if needed
    }
}
