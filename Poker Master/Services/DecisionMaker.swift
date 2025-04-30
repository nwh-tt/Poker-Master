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
    var loadedRanges: [String: [String]] = [:]
    
    init() {
        loadRanges()
    }
    
    // Load ranges once
    private func loadRanges() {
        self.loadedRanges = RangesFileManager.loadRanges()
    }
    
    func determineMovePreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []

        switch betNumber {
        case 1:
            let raiseKey = "open_\(hero.position)_raise"
            raiseHands = loadedRanges[raiseKey] ?? []

        case 2...5:
            guard let villianPosition = villian?.position else { return .fold }

            let raiseKey = "bet\(betNumber)_\(hero.position)_v_\(villianPosition)_raise"
            let callKey = "bet\(betNumber)_\(hero.position)_v_\(villianPosition)_call"

            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []
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

