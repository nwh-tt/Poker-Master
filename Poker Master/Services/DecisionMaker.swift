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
    
    func determineMovePreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        
        if (hero.position == "BTN") {
            return determineMoveBTNPreFlop(hero: hero, villian: villian, betNumber: betNumber)
        }
        if (hero.position == "SB") {
            return determineMoveSBPreFlop(hero: hero, villian: villian, betNumber: betNumber)
        }
        if (hero.position == "BB") {
            return determineMoveBBPreFlop(hero: hero, villian: villian, betNumber: betNumber)
        }
        if (hero.position == "UTG") {
            return determineMoveUTGPreFlop(hero: hero, villian: villian, betNumber: betNumber)
        }
        if (hero.position == "MP") {
            return determineMoveMPPreFlop(hero: hero, villian: villian, betNumber: betNumber)
        }
        if (hero.position == "CO") {
            return determineMoveCOPreFlop(hero: hero, villian: villian, betNumber: betNumber)
        }
        
        // probably want to throw error here
        return .none
    }
    
    private func determineMoveCOPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        if (betNumber == 1) {
            raiseHands = open_CO_raise
        }
        if (betNumber == 2) {
            return .none
        }
        if (betNumber == 3) {
            switch villian!.position {
            case "BB":
                raiseHands = self.bet3_CO_v_BB_raise
                callHands = self.bet3_CO_v_BB_call
            case "SB":
                raiseHands = self.bet3_CO_v_SB_raise
                callHands = self.bet3_CO_v_SB_call
            case "BTN":
                raiseHands = self.bet3_CO_v_BTN_raise
                callHands = self.bet3_CO_v_BTN_call
            default:
                return .none
            }
        }
        if (betNumber == 4) {
            return .none
        }
        if (betNumber == 5) {
            switch villian!.position {
            case "BB":
                raiseHands = self.bet5_CO_v_BB_raise
                callHands = self.bet5_CO_v_BB_call
            case "SB":
                raiseHands = self.bet5_CO_v_SB_raise
                callHands = self.bet5_CO_v_SB_call
            case "BTN":
                raiseHands = self.bet5_CO_v_BTN_raise
                callHands = self.bet5_CO_v_BTN_call
            default:
                return .none
            }
        }
        
        if (raiseHands.contains(hero.getHand())) {
            return .raise
        }
        if (callHands.contains(hero.getHand())) {
            return .call
        }
        
        return .fold
    }
    
    private func determineMoveMPPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        if (betNumber == 1) {
            raiseHands = open_MP_raise
        }
        if (betNumber == 2) {
            if (villian!.position == "UTG") {
                raiseHands = self.bet_MP_v_UTG_raise
            }
            else {
                return .none
            }
        }
        if (betNumber == 3) {
            switch villian!.position {
            case "BB":
                raiseHands = self.bet3_MP_v_BB_raise
                callHands = self.bet3_MP_v_BB_call
            case "MP":
                raiseHands = self.bet3_MP_v_CO_raise
                callHands = self.bet3_MP_v_CO_call
            case "SB":
                raiseHands = self.bet3_MP_v_SB_raise
                callHands = self.bet3_MP_v_SB_call
            case "BTN":
                raiseHands = self.bet3_MP_v_BTN_raise
                callHands = self.bet3_MP_v_BTN_call
            default:
                return .none
            }
        }
        if (betNumber == 4) {
            if (villian!.position == "UTG") {
                raiseHands = self.bet4_MP_v_UTG_raise
                callHands = self.bet4_MP_v_UTG_call
            }
            else {
                return .none
            }
        }
        if (betNumber == 5) {
            switch villian!.position {
            case "BB":
                raiseHands = self.bet5_MP_v_BB_raise
                callHands = self.bet5_MP_v_BB_call
            case "MP":
                raiseHands = self.bet5_MP_v_CO_raise
                callHands = self.bet5_MP_v_CO_call
            case "SB":
                raiseHands = self.bet5_MP_v_SB_raise
                callHands = self.bet5_MP_v_SB_call
            case "BTN":
                raiseHands = self.bet5_MP_v_BTN_raise
                callHands = self.bet5_MP_v_BTN_call
            default:
                return .none
            }
        }
        
        if (raiseHands.contains(hero.getHand())) {
            return .raise
        }
        if (callHands.contains(hero.getHand())) {
            return .call
        }
        
        return .fold
    }
        
    
    private func determineMoveUTGPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        if (betNumber == 1) {
            raiseHands = open_UTG_raise
        }
        
        if (betNumber == 2) {
            return .none
        }
        if (betNumber == 3) {
            switch villian!.position {
            case "SB":
                raiseHands = self.bet3_UTG_v_SB_raise
                callHands = self.bet3_UTG_v_SB_call
            case "BTN":
                raiseHands = self.bet3_UTG_v_BTN_raise
                callHands = self.bet3_UTG_v_BTN_call
            case "BB":
                raiseHands = self.bet3_UTG_v_BB_raise
                callHands = self.bet3_UTG_v_BB_call
            case "MP":
                raiseHands = self.bet3_UTG_v_MP_raise
                callHands = self.bet3_UTG_v_MP_call
            case "CO":
                raiseHands = self.bet3_UTG_v_CO_raise
                callHands = self.bet3_UTG_v_CO_call
            default:
                return .none
            }
        }
        if (betNumber == 4) {
            return .none
        }
        
        if (betNumber == 5) {
            switch villian!.position {
            case "SB":
                raiseHands = self.bet5_UTG_v_SB_raise
                callHands = self.bet5_UTG_v_SB_call
            case "BTN":
                raiseHands = self.bet5_UTG_v_BTN_raise
                callHands = self.bet5_UTG_v_BTN_call
            case "BB":
                raiseHands = self.bet5_UTG_v_BB_raise
                callHands = self.bet5_UTG_v_BB_call
            case "MP":
                raiseHands = self.bet5_UTG_v_MP_raise
                callHands = self.bet5_UTG_v_MP_call
            case "CO":
                raiseHands = self.bet5_UTG_v_CO_raise
                callHands = self.bet5_UTG_v_CO_call
            default:
                return .none
            }
        }
        
        
        if (raiseHands.contains(hero.getHand())) {
            return .raise
        }
        if (callHands.contains(hero.getHand())) {
            return .call
        }
        
        return .fold
    }
    
    private func determineMoveBBPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        if (betNumber == 1) {
            raiseHands = open_BB_raise
        }
        
        if (betNumber == 2) {
            switch villian!.position {
            case "SB":
                raiseHands = self.bet_BB_v_SB_raise
                callHands = self.bet_BB_v_SB_call
            case "BTN":
                raiseHands = self.bet_BB_v_BTN_raise
                callHands = self.bet_BB_v_BTN_call
            case "UTG":
                raiseHands = self.bet_BB_v_UTG_raise
                callHands = self.bet_BB_v_UTG_call
            case "MP":
                raiseHands = self.bet_BB_v_MP_raise
                callHands = self.bet_BB_v_MP_call
            case "CO":
                raiseHands = self.bet_BB_v_CO_raise
                callHands = self.bet_BB_v_CO_call
            default:
                return .none
            }
        }
        if (betNumber == 3) {
            return .none
        }
        if (betNumber == 4) {
            switch villian!.position {
            case "SB":
                raiseHands = self.bet4_BB_v_SB_raise
                callHands = self.bet4_BB_v_SB_call
            case "BTN":
                raiseHands = self.bet4_BB_v_BTN_raise
                callHands = self.bet4_BB_v_BTN_call
            case "UTG":
                raiseHands = self.bet4_BB_v_UTG_raise
                callHands = self.bet4_BB_v_UTG_call
            case "MP":
                raiseHands = self.bet4_BB_v_MP_raise
                callHands = self.bet4_BB_v_MP_call
            case "CO":
                raiseHands = self.bet4_BB_v_CO_raise
                callHands = self.bet4_BB_v_CO_call
            default:
                return .none
            }
        }
        if (betNumber == 5) {
            return .none
        }
        
        if (raiseHands.contains(hero.getHand())) {
            return .raise
        }
        if (callHands.contains(hero.getHand())) {
            return .call
        }
        
        return .fold
    }
    
    private func determineMoveSBPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        if (betNumber == 1) {
            raiseHands = open_SB_raise
        }
        if (betNumber == 2) {
            switch villian!.position {
            case "UTG":
                raiseHands = self.bet_SB_v_UTG_raise
            case "MP":
                raiseHands = self.bet_SB_v_MP_raise
            case "CO":
                raiseHands = self.bet_SB_v_CO_raise
            case "BTN":
                raiseHands = self.bet_SB_v_BTN_raise
            default:
                return .none
            }
        }
        if (betNumber == 3) {
            if (villian!.position == "BB") {
                raiseHands = self.bet3_SB_v_BB_raise
                callHands = self.bet3_SB_v_BB_call
            }
            else {
                return .none
            }
        }
        if (betNumber == 4) {
            switch villian!.position {
            case "UTG":
                raiseHands = self.bet4_SB_v_UTG_raise
                callHands = self.bet4_SB_v_UTG_call
            case "MP":
                raiseHands = self.bet4_SB_v_MP_raise
                callHands = self.bet4_SB_v_MP_call
            case "CO":
                raiseHands = self.bet4_SB_v_CO_raise
                callHands = self.bet4_SB_v_CO_call
            case "BTN":
                raiseHands = self.bet4_SB_v_BTN_raise
                callHands = self.bet4_SB_v_BTN_call
            default:
                return .none
            }
        }
        if (betNumber == 5) {
            if (villian!.position == "BB") {
                callHands = self.bet5_SB_v_BB_call
            }
            else {
                return .none
            }
        }
        
        if (raiseHands.contains(hero.getHand())) {
            return .raise
        }
        if (callHands.contains(hero.getHand())) {
            return .call
        }
        
        return .fold
        
    }
    
    private func determineMoveBTNPreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        var raiseHands: [String] = []
        var callHands: [String] = []
        
        if (betNumber == 1) {
            raiseHands = open_BTN_raise
        }
        if (betNumber == 2) {
            switch villian!.position {
            case "UTG":
                raiseHands = self.bet_BTN_v_UTG_raise
                callHands = self.bet_BTN_v_UTG_call
            case "MP":
                raiseHands = self.bet_BTN_v_MP_raise
                callHands = self.bet_BTN_v_MP_call
            case "CO":
                raiseHands = self.bet_BTN_v_CO_raise
                callHands = self.bet_BTN_v_CO_call
            default:
                return .none
            }
        }
        if (betNumber == 3) {
            switch villian!.position {
            case "SB":
                raiseHands = self.bet3_BTN_v_SB_raise
                callHands = self.bet3_BTN_v_SB_call
            case "BB":
                raiseHands = self.bet3_BTN_v_BB_raise
                callHands = self.bet3_BTN_v_BB_call
            default:
                return .none
            }
        }
        if (betNumber == 4) {
            switch villian!.position {
            case "UTG":
                raiseHands = self.bet4_BTN_v_UTG_raise
                callHands = self.bet4_BTN_v_UTG_call
            case "MP":
                raiseHands = self.bet4_BTN_v_MP_raise
                callHands = self.bet4_BTN_v_MP_call
            case "CO":
                raiseHands = self.bet4_BTN_v_CO_raise
                callHands = self.bet4_BTN_v_CO_call
            default:
                return .none
            }
        }
        if (betNumber == 5) {
            switch villian!.position {
            case "SB":
                callHands = self.bet5_BTN_v_SB_call
            case "BB":
                callHands = self.bet5_BTN_v_BB_call
            default:
                return .none
            }
        }
        
        if (raiseHands.contains(hero.getHand())) {
            return .raise
        }
        if (callHands.contains(hero.getHand())) {
            return .call
        }
        
        return .fold
    }
    
    // btn hero ranges
    let open_BTN_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
        "AKo", "KK",  "KQs", "KJs", "KTs", "K9s", "K8s", "K7s", "K6s", "K5s", "K4s", "K3s", "K2s",
        "AQo", "KQo", "QQ", "QJs",  "QTs", "Q9s", "Q8s", "Q7s", "Q6s", "Q5s", "Q4s", "Q3s", "Q2s",
        "AJo", "KJo", "QJo", "JJ",  "JTs", "J9s", "J8s", "J7s", "J6s", "J5s", "J4s",
        "ATo", "KTo", "QTo", "JTo", "TT",  "T9s", "T8s", "T7s", "T6s",
        "A9o", "K9o", "Q9o", "J9o", "T9o", "99",  "98s", "97s", "96s",
        "A8o", "K8o",                             "88",  "87s", "86s",
        "A7o",                                           "77",  "76s", "75s",
        "A6o",                                                  "66",  "65s",
        "A5o",                                                         "55",  "54s",
        "A4o",                                                                "44",
        "A3o",                                                                       "33",
                                                                                            "22"
    ]
    
    let bet_BTN_v_UTG_raise = [
        "AA", "AKs", "AQs", "AJs", "ATs", "A9s", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs", "KTs",
        "AQo", "KQo", "QQ", "QJs",
        "JJ",
        "TT",
    ]
    
    let bet_BTN_v_UTG_call = [
        "99", "98s",
        "88", "87s",
        "77", "76s",
        "66", "65s",
        "55", "54s",
        "44"
    ]
    
    let bet_BTN_v_MP_raise = [
        "AA", "AKs", "AQs", "AJs", "ATs", "A9s", "A8s", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs", "KTs",
        "AQo", "KQo",  "QQ", "QJs",
        "AJo", "JJ",
        "TT",
    ]
    
    let bet_BTN_v_MP_call = [
        "99", "98s",
        "88", "87s",
        "77", "76s",
        "66",
        "55",
    ]
    
    let bet_BTN_v_CO_raise = [
        "AA", "AKs", "AQs", "AJs", "ATs", "A9s", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs", "KTs", "K9s",
        "AQo","KQo","QQ", "QJs", "QTs",
        "AJo", "KJo","QJo","JJ", "JTs",
        "ATo", "TT",
    ]
    
    let bet_BTN_v_CO_call = [
        "99", "98s",
        "88", "87s",
        "77", "76s",
    ]
    
    let bet3_BTN_v_SB_raise = [
        "AA", "AKs", "AQs", "A9s", "A8s", "A5s",
        "AKo", "KK",
        "AQo", "QQ",
        "JJ",
        "TT"
    ]
    
    let bet3_BTN_v_SB_call = [
        "AJs", "ATs",
        "KQs", "KJs", "KTs",
        "QJs", "QTs",
        "JTs",
        "T9s",
        "99", "98s",
        "88",
        "77",
    ]
    
    let bet3_BTN_v_BB_raise = [
        "AA", "AKs", "AQs", "A52",
        "AKo", "KK",
        "AQo", "QQ",
        "JJ",
        "TT"
    ]
    
    let bet3_BTN_v_BB_call = [
        "AJs", "ATs", "A9s", "A8s",
        "KQs", "KJs", "KTs", "K9s",
        "QJs", "QTs",
        "JTs",
        "T9s",
        "99", "98s",
        "88", "87s",
        "77", "76s",
        "66", "65s",
        "55"
    ]
    
    let bet4_BTN_v_UTG_raise = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet4_BTN_v_UTG_call = [
        "AQs", "AJs",
        "KQs",
        "QQ",
        "JJ",
    ]
    
    let bet4_BTN_v_MP_raise = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
    ]
    
    let bet4_BTN_v_MP_call = [
        "AQs", "AJs",
        "KQs", "KJs",
        "JJ",
        "TT",
    ]
    
    let bet4_BTN_v_CO_raise = [
        "AKs", "A5s",
        "AKo", "KK",
        "QQ",
        "JJ",
    ]
    
    let bet4_BTN_v_CO_call = [
        "AA", "AQs", "AJs", "ATs",
        "KQs", "KJs", "KTs",
        "TT",
    ]
    
    let bet5_BTN_v_BB_call = [
        "AKs", "AKs",
        "AKo", "KK",
        "QQ",
        "JJ",
    ]
    
    let bet5_BTN_v_SB_call = [
        "AKs", "AKs", "AQs",
        "AKo", "KK",
        "QQ",
        "JJ",
    ]
    
    // SB hero ranges
    let open_SB_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
        "AKo", "KK",  "KQs", "KJs", "KTs", "K9s", "K8s", "K7s", "K6s", "K5s", "K4s", "K3s", "K2s",
        "AQo", "KQo", "QQ", "QJs",  "QTs", "Q9s", "Q8s", "Q7s", "Q6s", "Q5s", "Q4s", "Q3s", "Q2s",
        "AJo", "KJo", "QJo", "JJ",  "JTs", "J9s", "J8s", "J7s", "J6s", "J5s", "J4s",
        "ATo", "KTo", "QTo", "JTo", "TT",  "T9s", "T8s", "T7s", "T6s",
        "A9o", "K9o", "Q9o", "J9o", "T9o", "99",  "98s", "97s", "96s",
        "A8o", "K8o",                             "88",  "87s", "86s",
        "A7o",                                           "77",  "76s", "75s",
        "A6o",                                                  "66",  "65s",
        "A5o",                                                         "55",  "54s",
        "A4o",                                                                "44",
        "A3o",                                                                       "33",
                                                                                            "22"
    ]
    
    let bet_SB_v_UTG_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A5s", "A4s",
        "AKo", "KK",  "KQs", "KJs", "KTs",
        "AQo", "QQ", "QJs",
        "JJ",
        "TT",
    ]
    
    let bet_SB_v_MP_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A5s", "A4s",
        "AKo", "KK",  "KQs", "KJs", "KTs",
        "AQo", "KQo", "QQ", "QJs",
        "AJo", "JJ",
        "TT",
    ]
    
    let bet_SB_v_CO_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A5s", "A4s", "A3s",
        "AKo", "KK",  "KQs", "KJs", "KTs",
        "AQo", "KQo", "QQ", "QJs",  "QTs",
        "AJo", "KJo",       "JJ",   "JTs",
                           "TT",
                                           "99",
    ]
    
    let bet_SB_v_BTN_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s",
        "AKo", "KK",  "KQs", "KJs", "KTs", "K9s",
        "AQo", "KQo", "QQ", "QJs",  "QTs", "Q9s",
        "AJo", "KJo",       "JJ",   "JTs",
        "ATo",                      "TT",  "T9s",
                                           "99",
                                                  "88",
                                                        "77",
    ]
    
    let bet3_SB_v_BB_raise = [
        "AA", "AKs",  "AQs", "A9s","A7s", "A6s", "A5s", "A4s",
        "AKo", "KK",
        "AQo", "QQ",
        "AJo", "JJ",
        "ATo", "TT",
    ]
    
    let bet3_SB_v_BB_call = [
        "AJs", "ATs",
        "KQs", "KJs", "KTs", "K9s",
        "QJs", "QTs", "Q9s",
        "JTs", "J9s",
        "T9s",
        "99",
        "88",
        "77",
    ]
    
    let bet4_SB_v_UTG_raise = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet4_SB_v_UTG_call = [
        "AQs", "AJs",
        "KQs",
        "QQ",
        "JJ",
    ]
    
    let bet4_SB_v_MP_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",
        "QQ",
    ]
    
    let bet4_SB_v_MP_call = [
        "AQs", "AJs",
        "KQs", "KJs",
        "JJ",
        "TT",
    ]
    
    let bet4_SB_v_CO_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",
        "QQ",
        "JJ",
        "TT",
    ]
    
    let bet4_SB_v_CO_call = [
        "AQs", "AJs",
        "KQs",
        "99",
    ]
    
    let bet4_SB_v_BTN_raise = [
        "AA", "AKs",  "AQs", "A5s",
        "AKo", "KK",
        "AQo", "QQ",
        "JJ",
        "TT",
    ]
    
    let bet4_SB_v_BTN_call = [
        "AJs", "ATs",
        "KQs",
        "99",
        "88"
    ]
    
    let bet5_SB_v_BB_call = [
        "AA", "AKs", "AQs",
        "AKo", "KK",
        "QQ",
        "JJ",
        "TT",
    ]
    
    
    // BB hero ranges
    let open_BB_raise: [String] = []
    
    let bet_BB_v_UTG_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A5s", "A4s",
        "AKo", "KK",  "KQs", "KJs",
        "KQo", "QQ",
    ]
    
    let bet_BB_v_UTG_call = [
        "A9s", "A8s", "A7s", "A6s", "A3s", "A2s",
        "KTs", "K9s", "K8s", "K7s", "K6s", "K5s", "K4s", "K3s",
        "AQo", "QJs",  "QTs", "Q9s", "Q8s", "Q7s",
        "AJo", "JJ",  "JTs", "J9s", "J8s",
        "ATo", "TT", "T9s", "T8s", "T7s",
        "99", "98s", "97s", "96s",
        "88", "87s", "86s",
        "77", "76s", "75s",
        "66", "65s", "64s",
        "55", "54s", "53s",
        "44", "43s",
        "33",
        "22"
    ]
    
    let bet_BB_v_MP_raise = [
        "AA", "AKs", "AQs", "A6s", "A5s", "A4s", "A3s", "A2s",
        "AKo", "KK", "K6s", "K5s", "K4s", "K3s", "K2s",
        "KQo", "QQ",
        "JJ"
    ]
    
    let bet_BB_v_MP_call = [
        "AJs", "ATs", "A9s", "A8s", "A7s",
        "KQs", "KJs", "KTs", "K9s", "K8s", "K7s",
        "AQo", "QJs", "QTs", "Q9s", "Q8s", "Q7s", "Q6s",
        "AJo", "KJo", "QJo", "JTs", "J9s", "J8s",
        "ATo", "TT", "T9s", "T8s", "T7s",
        "99", "98s", "97s", "96s",
        "88", "87s", "86s",
        "77", "76s", "75s",
        "66", "65s", "64s",
        "55", "54s", "53s",
        "44", "43s",
        "33",
        "22"
    ]
    
    let bet_BB_v_CO_raise = [
        "AA", "AKs", "AQs", "A6s", "A5s", "A4s", "A3s", "A2s",
        "AKo", "KK", "K6s", "K5s", "K4s", "K3s", "K2s",
        "AQo", "KQo", "QQ",
        "AJo", "JJ"
    ]
    
    let bet_BB_v_CO_call = [
        "AJs", "ATs", "A9s", "A8s", "A7s",
        "KQs", "KJs", "KTs", "K9s", "K8s", "K7s",
        "QJs", "QTs", "Q9s", "Q8s", "Q7s", "Q6s", "Q5s",
        "KJo", "QJo", "JTs", "J9s", "J8s", "J7s", "J6s",
        "ATo", "TT", "T9s", "T8s", "T7s",
        "A9o", "99", "98s", "97s", "96s",
        "88", "87s", "86s",
        "77", "76s", "75s",
        "66", "65s", "64s",
        "55", "54s", "53s",
        "44", "43s",
        "33",
        "22"
    ]
    
    let bet_BB_v_BTN_raise = [
        "AA", "AKs", "AQs", "AJs", "ATs", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs", "KTs", "K9s",
        "AQo", "KQo", "QQ", "QJs", "QTs", "Q9s",
        "AJo", "KJo", "JJ", "JTs", "J9s", "J8s",
        "ATo", "TT", "T9s", "T8s",
        "99", "98s",
    ]
    
    let bet_BB_v_BTN_call = [
        "A9s", "A8s", "A7s", "A6s", "A3s", "A2s",
        "K8s", "K7s", "K6s", "K5s", "K4s", "K3s", "K2s",
        "Q8s", "Q7s", "Q6s", "Q5s", "Q4s", "Q3s", "Q2s",
        "QJo", "J7s", "J6s", "J5s", "J4s",
        "KTo", "QTo", "JTo", "T7s", "T6s",
        "A9o", "K9o", "J9o", "T9o", "97s", "96s",
        "A8o", "88", "87s", "86s", "85s",
        "A7o","77", "76s", "75s", "74s",
        "A6o","66", "65s", "64s",
        "A5o","55", "54s", "53s",
        "44", "43s",
        "33",
        "22"
    ]
    
    let bet_BB_v_SB_raise = [
        "AA", "AKs", "AQs", "AJs", "ATs", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs", "KTs",
        "AQo", "QQ", "QJs",
        "JJ",
        "TT", "T5s", "T4s", "T3s", "T2s",
        "Q8o",
        "A7o", "K7o",
        "A6o", "K6o",
        "A5o", "K5o",
        "A4o",
        "A3o",
        "A2o",
    ]
    
    let bet_BB_v_SB_call = [
        "A9s", "A8s", "A7s", "A6s", "A3s", "A2s",
        "K9s", "K8s", "K7s", "K6s", "K5s", "K4s", "K3s", "K2s",
        "KQo", "QTs", "Q9s", "Q8s", "Q7s", "Q6s", "Q5s", "Q4s", "Q3s", "Q2s",
        "AJo", "KJo", "QJo", "JTs", "J9s", "J8s", "J7s", "J6s", "J5s", "J4s", "J3s", "J2s",
        "ATo", "KTo", "QTo", "JTo", "T9s", "T8s", "T7s", "T6s",
        "A9o", "K9o", "Q9o", "J9o", "T9o", "99",  "98s", "97s", "96s", "95s",
        "A8o", "K8o", "T8o", "88", "87s", "86s", "84s",
        "77",  "76s", "75s", "74s",
        "66", "65s", "64s", "63s",
        "55", "54s", "53s", "52s",
        "44", "43s", "42s",
        "33", "32s",
        "22"
    ]
    
    let bet4_BB_v_UTG_raise = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet4_BB_v_UTG_call = [
        "AQs",
        "QQ",
    ]
    
    let bet4_BB_v_MP_raise = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ"
    ]
    
    let bet4_BB_v_MP_call = [
        "AQs",
        "JJ",
    ]
    
    let bet4_BB_v_CO_raise = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
        "JJ"
    ]
    
    let bet4_BB_v_CO_call = [
        "AQs",
    ]
    
    let bet4_BB_v_BTN_raise = [
        "AA", "AKs", "AQs", "A5s", "A4s",
        "AKo", "KK",
        "QQ",
        "JJ",
        "TT"
    ]
    
    let bet4_BB_v_BTN_call = [
        "AJs",
        "KQs",
        "AQo",
        "99",
    ]
    
    let bet4_BB_v_SB_raise = [
        "AKs",  "A5s", "A4s",
        "AKo", "KK",
        "AQo", "QQ",
        "JJ",
        "TT"
    ]
    
    let bet4_BB_v_SB_call = [
        "AA", "AQs", "AJs", "ATs",
        "KQs", "KJs", "KTs",
        "QJs",
    ]
    
    // UTG (lj) hero ranges
    let open_UTG_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
        "AKo", "KK",  "KQs", "KJs", "KTs", "K9s", "K8s", "K7s", "K6s", "K5s",
        "AQo", "KQo", "QQ", "QJs",  "QTs", "Q9s",
        "AJo", "KJo", "QJo", "JJ",  "JTs",
        "ATo",  "TT",  "T9s",
        "99",
        "88",
        "77",
    ]
    
    let bet3_UTG_v_MP_raise = [
        "AA", "AKs", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs",
        "QQ",
        "JJ",
    ]
    
    let bet3_UTG_v_MP_call = [
        "AQs", "AJs", "ATs",
        "TT",
        "99",
        "88",
    ]
    
    let bet3_UTG_v_CO_raise = [
        "AA", "AKs", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs", "KTs",
        "QQ",
        "JJ",
    ]
    
    let bet3_UTG_v_CO_call = [
        "AQs", "AJs", "ATs",
        "TT",
        "99",
        "88",
    ]
    
    let bet3_UTG_v_BTN_raise = [
        "AA", "AKs", "A5s", "A4s",
        "AKo", "KK", "KQs", "KJs", "KTs",
        "QQ",
        "JJ",
    ]
    
    let bet3_UTG_v_BTN_call = [
        "AQs", "AJs", "ATs",
        "TT",
        "99",
        "88",
        "77",
    ]
    
    let bet3_UTG_v_SB_raise = [
        "AA", "AKs", "A5s", "A4s",
        "AKo", "KK", "KQs",
    ]
    
    let bet3_UTG_v_SB_call = [
        "AQs", "AJs", "ATs",
        "QQ",
        "JJ",
        "TT",
        "99",
        "88",
        "77",
    ]
    
    let bet3_UTG_v_BB_raise = [
        "AA", "AKs", "A5s", "A4s",
        "AKo", "KK",
    ]
    
    let bet3_UTG_v_BB_call = [
        "AQs", "AJs", "ATs",
        "KQs", "KJs",
        "QQ", "QJs",
        "JJ",
        "TT",
        "99",
    ]
    
    let bet5_UTG_v_MP_raise: [String] = []
    
    let bet5_UTG_v_MP_call = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet5_UTG_v_CO_raise: [String] = []
    
    let bet5_UTG_v_CO_call = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet5_UTG_v_BTN_raise: [String] = []
    
    let bet5_UTG_v_BTN_call = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet5_UTG_v_SB_raise: [String] = []
    
    let bet5_UTG_v_SB_call = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet5_UTG_v_BB_raise: [String] = []
    
    let bet5_UTG_v_BB_call = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    // MP (HJ) ranges
    let open_MP_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
        "AKo", "KK",  "KQs", "KJs", "KTs", "K9s", "K8s", "K7s", "K6s", "K5s",
        "AQo", "KQo", "QQ", "QJs",  "QTs", "Q9s", "Q8s",
        "AJo", "KJo", "QJo", "JJ",  "JTs", "J9s",
        "ATo", "KTo", "QTo",  "TT",  "T9s",
        "A9o", "99",
        "88",
        "77",
        "66",
    ]
    
    let bet_MP_v_UTG_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A5s", "A4s",
        "AKo", "KK",  "KQs", "KJs", "KTs",
        "AQo", "KQo", "QQ", "QJs",
        "JJ",
    ]
    
    let bet3_MP_v_CO_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",  "KQs", "KJs", "KTs",
        "AQo", "QQ",
        "JJ",
    ]
    
    let bet3_MP_v_CO_call = [
        "AQs", "AJs", "ATs",
        "TT",
        "99",
        "88",
    ]
    
    let bet3_MP_v_BTN_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",  "KQs", "KJs", "KTs",
        "AQo", "QQ",
        "JJ",
    ]
    
    let bet3_MP_v_BTN_call = [
        "AQs", "AJs", "ATs",
        "TT",
        "99",
        "88",
        "77",
    ]
    
    let bet3_MP_v_SB_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",  "KQs", "KJs", "KTs",
        "AQo", "QQ",
        "JJ",
    ]
    
    let bet3_MP_v_SB_call = [
        "AQs", "AJs", "ATs",
        "TT",
        "99",
        "88",
        "77",
    ]
    
    let bet3_MP_v_BB_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",
        "AQo", "QQ",
    ]
    
    let bet3_MP_v_BB_call = [
        "AQs", "AJs", "ATs",
        "KQs",
        "JJ",
        "TT",
        "99",
        "88",
        "77",
    ]
    
    let bet4_MP_v_UTG_raise = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    let bet4_MP_v_UTG_call = [
        "AQs", "AJs", "ATs",
        "KQs",
        "QQ",
        "JJ",
    ]
    
    let bet5_MP_v_CO_raise: [String] = []
    
    let bet5_MP_v_CO_call = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
    ]
    
    let bet5_MP_v_BTN_raise: [String] = []
    
    let bet5_MP_v_BTN_call = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
    ]
    
    let bet5_MP_v_SB_raise: [String] = []
    
    let bet5_MP_v_SB_call = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
    ]
    
    let bet5_MP_v_BB_raise: [String] = []
    
    let bet5_MP_v_BB_call = [
        "AA", "AKs",
        "AKo", "KK",
    ]
    
    
    // CO ranges
    let open_CO_raise = [
        "AA", "AKs",  "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
        "AKo", "KK",  "KQs", "KJs", "KTs", "K9s", "K8s", "K7s", "K6s", "K5s", "K4s", "K3s",
        "AQo", "KQo", "QQ", "QJs",  "QTs", "Q9s", "Q8s", "Q7s", "Q6s", "Q5s",
        "AJo", "KJo", "QJo", "JJ",  "JTs", "J9s", "J8s", "J7s",
        "ATo", "KTo", "QTo", "JTo", "TT",  "T9s", "T8s",
        "A9o", "K9o", "99",  "98s",
        "A8o", "88",
        "77",
        "66",
        "55",
        "44",
        "33",
        "22"
    ]
    
    let bet3_CO_v_BTN_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",
        "AQo", "QQ",
        "AJo", "JJ", "JTs",
        "ATo",
    ]
    
    let bet3_CO_v_BTN_call = [
        "AQs", "Ajs", "ATs",
        "KQs", "KJs", "KTs",
        "TT", "T9s",
        "99", "98s",
        "88",
        "77",
    ]
    
    let bet3_CO_v_SB_raise = [
        "AA", "AKs", "ATs", "A5s",
        "AKo", "KK", "KTs",
        "AQo", "QQ",
        "JJ",
        "TT",
    ]
    
    let bet3_CO_v_SB_call = [
        "AQs", "Ajs",
        "KQs", "KJs",
        "JTs",
        "99",
        "88",
        "77",
    ]
    
    let bet3_CO_v_BB_raise = [
        "AA", "AKs", "A5s",
        "AKo", "KK",
        "AQo", "QQ",
        "JJ",
    ]
    
    let bet3_CO_v_BB_call = [
        "AQs", "Ajs", "ATs", "A9s",
        "KQs", "KJs", "KTs",
        "QJs",
        "JTs",
        "TT",
        "99",
        "88",
        "77",
    ]
    
    let bet5_CO_v_BTN_raise: [String] = []
    
    let bet5_CO_v_BTN_call = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
        "JJ",
    ]
    
    let bet5_CO_v_SB_raise: [String] = []
    
    let bet5_CO_v_SB_call = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
        "JJ",
        "TT",
    ]
    
    let bet5_CO_v_BB_raise: [String] = []
    
    let bet5_CO_v_BB_call = [
        "AA", "AKs",
        "AKo", "KK",
        "QQ",
        "JJ",
    ]
    
}
