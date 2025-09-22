//
//  RangeHelper.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/21/25.
//

import Foundation


class RangeHelper {
    private var ranges: [String: [String]]
    
    let positionOrders: [String: [String]] = [
            "6": ["UTG", "MP", "CO", "BTN", "SB", "BB"],
            "9": ["UTG", "UTG+1", "MP1", "MP2", "CO", "BTN", "SB", "BB"]
        ]
    
    init(ranges: [String: [String]] = RangesFileManager.loadRanges()) {
            self.ranges = ranges
    }
    
    func buildKey(for scenario: String, hero:String, villain: String = "") -> String {
        if scenario == "open" {
            return "open_\(hero)"
        }
        return "\(scenario)_\(hero)_v_\(villain)"
    }
    
    func rangesFromKey(key: String) -> [String] {
        return ranges[key] ?? []
    }
    
    func callRanges(for scenario: String, hero: String, villain: String, size: String = "6") -> [String] {
        let baseKey = self.buildKey(for: scenario, hero: hero, villain: villain)
        let callKey = "\(baseKey)_call"
        return ranges[callKey] ?? []
    }
    
    func raiseRanges(for scenario: String, hero: String, villain: String, size: String = "6") -> [String] {
        let baseKey = self.buildKey(for: scenario, hero: hero, villain: villain)
        let raiseKey = "\(baseKey)_raise"
        return ranges[raiseKey] ?? []
    }
    
    func getKeys() -> [String] {
        return Array(ranges.keys)
    }
    
    func getHeros(scenario: String, size: String = "6") -> [String] {
            let positionOrder = positionOrders[size] ?? positionOrders["6"]!
            
            let validKeys = self.getKeys().filter { key in
                key.contains(scenario)
            }
            
            let filteredHeros: [String] = validKeys.compactMap { key in
                let parts = key.components(separatedBy: "_")
                if parts.count > 2 {
                    return parts[1] // the hero position
                }
                return nil
            }
            
            let uniqueHeros = Array(Set(filteredHeros))
            
            // Sort by the correct position order for the table size
            let sortedHeros = uniqueHeros.sorted { positionOrder.firstIndex(of: $0) ?? 0 < positionOrder.firstIndex(of: $1) ?? 0 }
            
            return sortedHeros
        }
    
    func getVillains(scenario: String, heroPosition: String, size: String = "6") -> [String] {
        let positionOrder = positionOrders[size] ?? positionOrders["6"]!
        
        if scenario == "open" {
            return []
        }
        // Filter all keys to those that contain both the hero position and the scenario
        let validKeys = self.getKeys().filter { key in
            key.contains(heroPosition) && key.contains(scenario)
        }
        
        // Extract villain positions from the filtered keys
        // Assuming key format is: "scenario_HERO_v_VILLAIN"
        let villains: [String] = validKeys.compactMap { key in
            let parts = key.components(separatedBy: "_")
            if parts[1] != heroPosition { return nil }
            if parts.count > 2 {
                return parts[3] // the villain position
            }
            return nil
        }
        let uniqueVillains = Array(Set(villains))
        
        let sortedVillains = uniqueVillains.sorted { positionOrder.firstIndex(of: $0) ?? 0 < positionOrder.firstIndex(of: $1) ?? 0 }
        
        return sortedVillains
    }
    
    func getBetOptions(heroPosition: String, size: String = "6") -> [String] {
        // Filter keys that contain the hero position
        let validKeys = self.getKeys().filter { key in
            key.contains("\(heroPosition)_v") || key.contains("open_\(heroPosition)")
        }
        
        // Extract the scenario part from each key
        let scenarios: [String] = validKeys.compactMap { key in
            let parts = key.components(separatedBy: "_")
            guard parts.count >= 2 else { return nil }
            
            return parts[0]
        }
        
        // Define desired order
            let order = ["open", "bet2", "bet3", "bet4", "bet5"]
            
            // Keep unique scenarios
            let uniqueScenarios = Array(Set(scenarios))
            
            // Sort according to order array
            let sortedScenarios = uniqueScenarios.sorted { a, b in
                let indexA = order.firstIndex(of: a) ?? Int.max
                let indexB = order.firstIndex(of: b) ?? Int.max
                return indexA < indexB
            }
            
            return sortedScenarios
    }

}
