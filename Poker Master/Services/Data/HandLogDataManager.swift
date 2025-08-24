//
//  HandLogDataManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/23/25.
//

import Foundation
import SwiftData

struct HandLogDataManager {
    
    static func addHand(
        handLog: HandLog,
        game: Game,
        context: ModelContext
    ) {
        
        // Add to the game's hands array
        game.hands.append(handLog)
        
        // Insert into context
        context.insert(handLog)
        
        do {
            try context.save()
            print("HandLog saved successfully")
        } catch {
            print("Failed to save HandLog: \(error)")
        }
    }
    
    static func addHands(
        handLogs: [HandLog],
        to game: Game,
        context: ModelContext
    ) {
        for handLog in handLogs {
            // Link each hand to the game
            handLog.game = game
            game.hands.append(handLog)
            
            // Insert into context
            context.insert(handLog)
        }
        
        do {
            try context.save()
            print("\(handLogs.count) HandLogs saved successfully")
        } catch {
            print("Failed to save HandLogs: \(error)")
        }
    }
    
    
    
    

}
