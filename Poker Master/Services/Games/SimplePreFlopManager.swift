//
//  SimplePreFlopManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/2/25.
//

import Foundation

// Mapping between hero and possible bets they can face
// hero -> [bet1, bet2, bet3, bet4, bet5]
let heroBetMapping6player = [
    "BTN": ["open", "2", "3", "4", "5"],
    "SB": ["open", "2", "3", "4", "5"],
    "BB": ["2", "4"],
    "UTG": ["open", "3", "5"],
    "MP": ["open", "2", "3", "4", "5"],
    "CO": ["open", "2", "3", "4", "5"]
]


class SimplePreFlopManager: GameManager {
    // variable for ranges
    var ranges: [String: [String]]
    var betToStopOn: Int = 1
    
    override init(decisionMaker: DecisionMaker = DecisionMaker(), gameplaySpeed: Int, testingMode: Bool) {
        self.ranges = RangesFileManager.loadRanges()
        
        super.init(gameplaySpeed: gameplaySpeed, testingMode: testingMode)
        
        stageTheGame()
    }
    
    // sets villian bet number and determines hand
    func stageTheGame() {
        let allKeys = Array(ranges.keys)
        guard let heroPosition = user?.position else { return }
        // take user position and use heroBetMapping to select random bet number
        var betNumber = heroBetMapping6player[heroPosition]?.randomElement() ?? "1"
        betToStopOn = betNumber == "open" ? 1 : Int(betNumber)!
        
        // filter out all keys that don't contain "bet(betNumber)_userPosition"
        let filteredKeys = allKeys.filter { $0.contains("bet\(betNumber)_\(heroPosition)") || $0.contains("\(betNumber)_\(heroPosition)") }
        
        // select a random key from the filtered keys
        guard let randomKey = filteredKeys.randomElement() else {
            return
        }
        
        // Gather possible hands
        let possibleHands = ranges[randomKey] ?? []
        
        // set villian position
        let villainPosition = extractVillainPosition(from: randomKey)
        villain = Player(position: villainPosition, stack: 100.0, hand: [deck.dealCard(), deck.dealCard()])
        
        // set user hand
        setUserHand(hero: heroPosition, villian: villainPosition)
    }
    
    func setUserHand(hero: String, villian: String) {
        if (betToStopOn == 1 || betToStopOn == 2) {
            // open or vs raise means we can stick with the random hand
            // This is because hero has taken no action thus far
            return
        }
        
        // Need to get a hand that would get the user to this point
        // - For that we can select the previous matchup between this hero and villian
        // - If betnumber is a 3 then we take open hands, if its 5 then we take 3 bet range
        let betToUse = betToStopOn == 3 ? "open" : String(betToStopOn - 2)
        
        var key = ""
        if (betToUse == "open") {
            key = "open_\(hero)_raise"
        }
        else {
            key = "bet\(betToUse)_\(hero)_v_\(villian)_raise"
        }
         
        
        let possibleHands = ranges[key] ?? []
        user?.setHand(hand: possibleHands.randomElement() ?? "")
    }
    
    override func executeLoop() async {
        while (true) {
            // fold if the player is not the villian
            let playerCopy = Player(position: players[turn].position, stack: players[turn].stack, betAmount: players[turn].currentBetAmount, hand: players[turn].hand, lastMove: players[turn].lastMove)
            playerCopy.hand = players[turn].hand
            
            if (players[turn % 6].position != villain?.position) {
                players[turn % 6].lastMove = .fold
            }
            
            turn = (turn + 1) % 6
        }
    }
    
    func extractVillainPosition(from key: String) -> String {
        let parts = key.split(separator: "_")
        
        // Look for the "v" and get the next part
        if let vIndex = parts.firstIndex(of: "v"), vIndex + 1 < parts.count {
            return String(parts[vIndex + 1])
        }
        
        return ""
    }
    
}
