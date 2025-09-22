//
//  DecisionMaker.swift
//  Poker Master
//
//  Created by Ned Whittleton on 5/28/24.
//
import Foundation


enum DecisionError: Error {
    case issueWithDecisionMaker(String)
}

// btn sb bb utg mp co
// btn sb bb lj hj co
class DecisionMaker {
    let rangeHelper = RangeHelper()
    let playerCount: String
    
    init(playerCount: String = "6") {
        self.playerCount = playerCount
    }
    
    func determineMovePreFlop(hero: Player, villian: Player?, betNumber: Int) -> Action {
        var raiseHands: [String] = []
        var callHands: [String] = []

        switch betNumber {
        case 1:
            let scenario = "open"
            raiseHands = rangeHelper.raiseRanges(for: scenario, hero: hero.position, villain: "")
        case 2...5:
            guard let villianPosition = villian?.position else { return .fold }
            let scenario = "bet\(betNumber)"
            
            raiseHands = rangeHelper.raiseRanges(for: scenario, hero: hero.position, villain: villianPosition)
            callHands = rangeHelper.callRanges(for: scenario, hero: hero.position, villain: villianPosition)
        default:
            return .fold
        }

        if raiseHands.contains(hero.getHand()) {
            return .raise
        }
        if callHands.contains(hero.getHand()) {
            return .call
        }
        
        // Means that hand is not in range
        return .fold
    }
}

