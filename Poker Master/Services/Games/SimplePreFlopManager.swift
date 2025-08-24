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
    
    
    override init(decisionMaker: DecisionMaker = DecisionMaker(), gameplaySpeed: Int = 3, testingMode: Bool = false) {
        self.ranges = RangesFileManager.loadRanges()
        super.init(gameplaySpeed: gameplaySpeed, testingMode: testingMode)
        
        stageTheGame()
    }
    
    // sets villian bet number and determines hand
    func stageTheGame() {
        let allKeys = Array(ranges.keys)
        guard let heroPosition = user?.position else { return }
        // take user position and use heroBetMapping to select random bet number
        let betNumber = heroBetMapping6player[heroPosition]?.randomElement() ?? "1"
        betToStopOn = betNumber == "open" ? 1 : Int(betNumber)!
        
        // filter out all keys that don't contain "bet(betNumber)_userPosition"
        let filteredKeys = allKeys.filter { $0.contains("bet\(betNumber)_\(heroPosition)") || $0.contains("\(betNumber)_\(heroPosition)") }
        
        // select a random key from the filtered keys
        guard let randomKey = filteredKeys.randomElement() else {
            return
        }
        
        // set villian position
        let villainPosition = extractVillainPosition(from: randomKey)
        villain = Player(position: villainPosition, stack: 100.0, hand: [deck.dealCard(), deck.dealCard()])
        
        // set user hand
        setUserHand(hero: heroPosition, villian: villainPosition)
        turn = players.firstIndex(where: { $0.position == "UTG" })!
        print("Hero: \(user?.position ?? "") Villian: \(villain?.position ?? "") BetToStopOn: \(betToStopOn)")
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
            // We have 3 cases
            // 1. player is the villian
            //    - Always raise
            // 2. player is the user
            //    a.) Reached betToStopOn
            //          - If we are testing we can just fold here
            //          - If we are not testing we need to wait for user input
            //    b.) Not reached betToStopOn
            //          - In this situation always raise
            // 3. player is neither
            //       - For this case we can just auto fold
            
            // Skip any player who already folded
            if (players[turn].lastMove == Move.fold) {
                turn = (turn + 1) % 6
                continue
            }

            // make a copy for ui updates
            let playerCopy = Player(
                position: players[turn].position,
                stack: players[turn].stack,
                betAmount: players[turn].currentBetAmount,
                hand: players[turn].hand, lastMove: players[turn].lastMove
            )
            
            if (playerCopy.position == villain?.position) { // Case 1: Villain always raises
                raise(player: playerCopy)
            } // If is the user
            else if (playerCopy.position == user?.position) { // Case 2: User
                
                if (betToStopOn == betNumber) { // Case 2a: BetToStopOn is reached - take user input
                    let idealDecision = decisionMaker.determineMovePreFlop(hero: players[turn], villian: villain ?? nil, betNumber: betNumber)
                    correctMove = idealDecision
                    await handleUserDecision(playerCopy: playerCopy, turn: turn, idealDecision: idealDecision)
                    break
                }
                else { // Case 2b: BetToStopOn is not reached - raise
                    // If it is not we just raise and move forward
                    raise(player: playerCopy)
                }
            }
            else if (players[turn].position != villain?.position) { // Case 3: Everyone else folds
                playerCopy.lastMove = .fold
                activePlayers -= 1
            }
            
            
            players[turn] = playerCopy // this updates the ui
            turn = (turn + 1) % 6
            
            let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s
            try? await Task.sleep(nanoseconds: sleepTime)
        }
    }
    
    override func resetAndStartNewGame() {
        pot = 0
        betToStopOn = 1
        // Reset players and reinitialize the deck
        deck.resetDeck()
        players = createRandomPlayers()
        user = players[0]
        
        // Deal two new cards to each player
        for player in players {
            player.hand = [deck.dealCard(), deck.dealCard()]
        }
        
        // Determine game duration using game.date to current Date
        // game.duration = Date().timeIntervalSince(game.date)
        // game.totalHands = hands.count
        
        // GameDataManager.createNewGame(game: game, context: modelContext)
        // HandLogDataManager.addHands(handLogs: hands, to: game, context: modelContext)
        
        
        
        
        // Reset game-related variables
        turn = players.firstIndex(where: { $0.position == "UTG" })!
        betNumber = 1
        lastRaise = 0.0
        villain = nil
        correctMove = .none
        pendingUserMoveContinuation = nil
        waitingForUserInput = false
        showIncorrectPopup = false
        adviceText = ""
        activePlayers = 6
        stageTheGame()
        // Optionally delay before starting the game again
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            await startGame()
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
