//
//  UserDataManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/29/25.
//

import Foundation
import SwiftData


struct UserDataManager {

    @MainActor
    static func createUserIfNotExist(context: ModelContext) async {
            
            // Ensure single user exists
            let fetchDescriptor = FetchDescriptor<User>(predicate: nil)
            if let existingUser = try? context.fetch(fetchDescriptor).first {
                // user already exists, do nothing
                print("User already exists: \(existingUser.username)")
            } else {
                // create the single user
                let newUser = User(username: "Player1")
                context.insert(newUser)
                try? context.save()
                print("Created new user: \(newUser.username)")
            }
    }
}

