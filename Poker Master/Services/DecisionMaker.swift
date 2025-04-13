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
            print(raiseHands)
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

    
    private func determineMoveCOPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []

        guard let villianPosition = villian?.position else { return .fold }

        switch betNumber {
        case 1:
            raiseHands = loadedRanges["open_CO_raise"] ?? []

        case 2:
            return .fold

        case 3:
            let raiseKey = "bet3_CO_v_\(villianPosition)_raise"
            let callKey = "bet3_CO_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []

        case 4:
            return .fold

        case 5:
            let raiseKey = "bet5_CO_v_\(villianPosition)_raise"
            let callKey = "bet5_CO_v_\(villianPosition)_call"
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

        return .fold
    }

    
    private func determineMoveMPPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        guard let villianPosition = villian?.position else { return .fold }
        
        switch betNumber {
        case 1:
            raiseHands = loadedRanges["open_MP_raise"] ?? []
            
        case 2:
            if villianPosition == "UTG" {
                raiseHands = loadedRanges["bet_MP_v_UTG_raise"] ?? []
            } else {
                return .fold
            }
            
        case 3:
            switch villianPosition {
            case "BB":
                raiseHands = loadedRanges["bet3_MP_v_BB_raise"] ?? []
                callHands = loadedRanges["bet3_MP_v_BB_call"] ?? []
            case "MP": // vs CO open (you're MP)
                raiseHands = loadedRanges["bet3_MP_v_CO_raise"] ?? []
                callHands = loadedRanges["bet3_MP_v_CO_call"] ?? []
            case "SB":
                raiseHands = loadedRanges["bet3_MP_v_SB_raise"] ?? []
                callHands = loadedRanges["bet3_MP_v_SB_call"] ?? []
            case "BTN":
                raiseHands = loadedRanges["bet3_MP_v_BTN_raise"] ?? []
                callHands = loadedRanges["bet3_MP_v_BTN_call"] ?? []
            default:
                return .fold
            }
            
        case 4:
            if villianPosition == "UTG" {
                raiseHands = loadedRanges["bet4_MP_v_UTG_raise"] ?? []
                callHands = loadedRanges["bet4_MP_v_UTG_call"] ?? []
            } else {
                return .fold
            }
            
        case 5:
            switch villianPosition {
            case "BB":
                raiseHands = loadedRanges["bet5_MP_v_BB_raise"] ?? []
                callHands = loadedRanges["bet5_MP_v_BB_call"] ?? []
            case "MP":
                raiseHands = loadedRanges["bet5_MP_v_CO_raise"] ?? []
                callHands = loadedRanges["bet5_MP_v_CO_call"] ?? []
            case "SB":
                raiseHands = loadedRanges["bet5_MP_v_SB_raise"] ?? []
                callHands = loadedRanges["bet5_MP_v_SB_call"] ?? []
            case "BTN":
                raiseHands = loadedRanges["bet5_MP_v_BTN_raise"] ?? []
                callHands = loadedRanges["bet5_MP_v_BTN_call"] ?? []
            default:
                return .fold
            }
            
        default:
            return .fold
        }
        
        if raiseHands.contains(hero.getHand()) {
            return .raise
        }
        if callHands.contains(hero.getHand()) {
            return .call
        }
        
        return .fold
    }
    
    
    
    private func determineMoveUTGPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        guard let villianPosition = villian?.position else { return .fold }
        
        switch betNumber {
        case 1:
            raiseHands = loadedRanges["open_UTG_raise"] ?? []
            
        case 2:
            return .fold
            
        case 3:
            let raiseKey = "bet3_UTG_v_\(villianPosition)_raise"
            let callKey = "bet3_UTG_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []
            
        case 4:
            return .fold
            
        case 5:
            let raiseKey = "bet5_UTG_v_\(villianPosition)_raise"
            let callKey = "bet5_UTG_v_\(villianPosition)_call"
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
        
        return .fold
    }
    
    
    private func determineMoveSBPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []

        guard let villianPosition = villian?.position else { return .fold }

        switch betNumber {
        case 1:
            raiseHands = loadedRanges["open_SB_raise"] ?? []

        case 2:
            let raiseKey = "bet_SB_v_\(villianPosition)_raise"
            raiseHands = loadedRanges[raiseKey] ?? []

        case 3:
            if villianPosition == "BB" {
                raiseHands = loadedRanges["bet3_SB_v_BB_raise"] ?? []
                callHands = loadedRanges["bet3_SB_v_BB_call"] ?? []
            } else {
                return .fold
            }

        case 4:
            let raiseKey = "bet4_SB_v_\(villianPosition)_raise"
            let callKey = "bet4_SB_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []

        case 5:
            if villianPosition == "BB" {
                callHands = loadedRanges["bet5_SB_v_BB_call"] ?? []
            } else {
                return .fold
            }

        default:
            return .fold
        }

        if raiseHands.contains(hero.getHand()) {
            return .raise
        }
        if callHands.contains(hero.getHand()) {
            return .call
        }

        return .fold
    }

    
    private func determineMoveBBPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        guard let villianPosition = villian?.position else { return .fold }
        
        switch betNumber {
        case 1:
            raiseHands = loadedRanges["open_BB_raise"] ?? []
            
        case 2:
            let raiseKey = "bet_BB_v_\(villianPosition)_raise"
            let callKey = "bet_BB_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []
            
        case 3:
            return .fold
            
        case 4:
            let raiseKey = "bet4_BB_v_\(villianPosition)_raise"
            let callKey = "bet4_BB_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []
            
        case 5:
            return .fold
            
        default:
            return .fold
        }
        
        if raiseHands.contains(hero.getHand()) {
            return .raise
        }
        if callHands.contains(hero.getHand()) {
            return .call
        }
        
        return .fold
    }
    
    
    private func determineMoveBTNPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        guard let villianPosition = villian?.position else { return .fold }
        
        switch betNumber {
        case 1:
            raiseHands = loadedRanges["open_BTN_raise"] ?? []
            
        case 2:
            let raiseKey = "bet_BTN_v_\(villianPosition)_raise"
            let callKey = "bet_BTN_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []
            
        case 3:
            let raiseKey = "bet3_BTN_v_\(villianPosition)_raise"
            let callKey = "bet3_BTN_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []
            
        case 4:
            let raiseKey = "bet4_BTN_v_\(villianPosition)_raise"
            let callKey = "bet4_BTN_v_\(villianPosition)_call"
            raiseHands = loadedRanges[raiseKey] ?? []
            callHands = loadedRanges[callKey] ?? []
            
        case 5:
            let callKey = "bet5_BTN_v_\(villianPosition)_call"
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
        
        return .fold
    }
}

