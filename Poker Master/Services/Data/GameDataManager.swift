//
//  GameDataManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/23/25.
//

import Foundation
import SwiftData

struct GameDataManager {
    
    static func createNewGame(game: Game, context: ModelContext) {
        context.insert(game)
        
        do {
            try context.save()
            print("Game saved successfully")
        } catch {
            print("Failed to save game: \(error)")
        }
    }
}
