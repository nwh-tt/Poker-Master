//
//  AdvancedDecisionMaker.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/16/25.
//

import Foundation

class AdvancedDecisionMaker {
    
    func determineMovePreFlop(hero: Player, villian: Player?, pot: Double, callAmount: Double, numOpponents: Int) async -> Action {
        let heroHoleCards = hero.hand.map { $0.toString() }
        let request = MultiwayPreflopEVRequest(hero_hole: heroHoleCards, pot_size: pot, call_amount: callAmount, raise_amount: nil, num_opponents: numOpponents, fold_chance: nil)
        
        do {
            let response = try await fetchMultiwayPreflopEV(requestData: request)
            
            if let raiseEv = response.raise_ev, raiseEv > response.call_ev {
                return .raise
            } else if response.call_ev > 0 {
                return .call
            } else {
                return .fold
            }
        } catch {
            print("Error fetching pre-flop EV: \(error)")
            // Handle the error appropriately, maybe by falling back to a default strategy
            return .fold
        }
    }
}
