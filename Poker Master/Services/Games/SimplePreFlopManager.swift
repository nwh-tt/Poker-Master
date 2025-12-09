//
//  SimplePreFlopManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/2/25.
//

import Foundation
import SwiftData

@MainActor
class SimplePreFlopManager: ObservableObject {
    @Published var players: [Player] = []
    @Published var user: Player? = nil
    @Published var pot: Double = 0.0
    @Published var waitingForUserInput: Bool = false
    @Published var score: Int = 0
    @Published var handsPlayed: Int = 0
    @Published var isGameOver: Bool = false
    var context: ModelContext?
    
    // variables needed for incorrect or correct move
    @Published var showIncorrectPopup: Bool = false
    @Published var adviceText: String = ""
    var rangesUsed: String = ""
    
    // Database values
    var game: Game
    var profile: Profile? = nil
    
    let deck: Deck = Deck()
    var turn: Int = 0
    var betNumber: Int = 1
    var lastRaise: Double = 0.0
    var villain: Player? = nil
    let decisionMaker: DecisionMaker
    
    var correctMove: Action = .none // used to check if the user made the correct move and update ui
    var pendingUserMoveContinuation: CheckedContinuation<Action, Never>?
    
    // user configs and parameters
    var gameplaySpeed: Double
    var testingMode: Bool
    
    let size: String
    let selectedPosition: String
    let selectedAction: String
    
    // variable for ranges
    var betToStopOn: Int = 1
    
    // Range helper
    let rangeHelper = RangeHelper()
    
    
    
    init(decisionMaker: DecisionMaker = DecisionMaker(), gameplaySpeed: Double = 3, testingMode: Bool = false, selectedPosition: String = "any", selectedAction: String = "any", size: String) {
        self.decisionMaker = decisionMaker
        self.gameplaySpeed = gameplaySpeed // Controls speed of play
        self.testingMode = testingMode
        self.selectedPosition = selectedPosition
        self.selectedAction = selectedAction.lowercased()
        self.size = size
        print("Size: \(size)")
        // create game to later be inserted
        game = Game(date: Date(), gameType: .preFlop, totalHands: 0, duration: 0.0)
        
        players = createRandomPlayers()
        user = players[0]
        // deal two cards to each player
        for player in players {
            player.hand.append(deck.dealCard())
            player.hand.append(deck.dealCard())
        }
        pot = 1.5
        
        stageTheGame()
    }
    
    func setProfile(profile: Profile) {
        self.profile = profile
        print("Profile set to: \(profile.username)")
    }
    
    // sets villian bet number and determines hand
    func stageTheGame() {
        isGameOver = false
        
        guard let user = user else {
            fatalError("User must not be nil when starting game")
        }
        
        let heroPosition = user.position
        
        // take user position and use heroBetMapping to select random bet number
        let betNumber: String
        if selectedAction.lowercased() == "any" {
            guard let randomBet = rangeHelper.getBetOptions(heroPosition: heroPosition, size: size).randomElement() else {
                fatalError("No bet mapping found for hero position: \(heroPosition)")
            }
            betNumber = randomBet
        } else {
            betNumber = selectedAction
        }
        
        let numberPart = String(betNumber.dropFirst(3))
        betToStopOn = betNumber == "open" ? 1 : Int(numberPart)!
        
        
        guard let villainPosition = rangeHelper.getVillains(scenario: betNumber, heroPosition: heroPosition, size: size).randomElement() ?? (betNumber == "open" ? "" : nil) else {
            fatalError("No villain position found for bet number: \(betNumber) and hero position: \(heroPosition)")
        }
        
        
        rangesUsed = rangeHelper.buildKey(for: betNumber, hero: heroPosition, villain: villainPosition) // size doesn't matter here
        
        villain = Player(position: villainPosition, stack: 100.0, hand: [deck.dealCard(), deck.dealCard()])
        
        // set user hand
        setUserHand(hero: heroPosition, villian: villainPosition)
        
        // set utg to go first
        turn = players.firstIndex(where: { $0.position == "UTG" })!
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
        if (betToUse == "open") {
            
        }
        let scenario = betToUse == "open" ? "open" : "bet\(betToUse)"
        
        let rasieHands = rangeHelper.raiseRanges(for: scenario, hero: hero, villain: villian, size: size)
        
        if let hand = rasieHands.randomElement() {
            user?.setHand(hand: hand)
        } else {
            fatalError("No possible hands to assign")
        }
    }
    
    func startGame() async {
        print("Game has started")
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
        await executeLoop()
    }
    
    func executeLoop() async {
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
            if (players[turn].lastMove == Action.fold) {
                turn = (turn + 1) % Int(size)!
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
                    let idealDecision = decisionMaker.determineMovePreFlop(hero: players[turn], villian: villain ?? nil, betNumber: betNumber, playerCount: size)
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
            }
            
            
            players[turn] = playerCopy // this updates the ui
            turn = (turn + 1) % Int(size)!
            
            let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s
            try? await Task.sleep(nanoseconds: sleepTime)
        }
    }
    
    func resetAndStartNewGame() {
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
        
        
        
        if (handsPlayed >= 10) {
            // Determine game duration using game.date to current Date
            game.duration = Date().timeIntervalSince(game.date)
            game.totalHands = handsPlayed
            // attempt to save context
            do {
                try context?.save()
            } catch {
                print("Failed to save game: \(error)")
            }
            isGameOver = true
            return
        }
        
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
        stageTheGame()
        // Optionally delay before starting the game again
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            await startGame()
        }
    }
    
    func completeReset() {
        score = 0
        handsPlayed = 0
        isGameOver = false
        game = Game(date: Date(), gameType: .preFlop, totalHands: 0, duration: 0.0)
        resetAndStartNewGame()
    }
    
    func extractVillainPosition(from key: String) -> String {
        let parts = key.split(separator: "_")
        
        // Look for the "v" and get the next part
        if let vIndex = parts.firstIndex(of: "v"), vIndex + 1 < parts.count {
            return String(parts[vIndex + 1])
        }
        
        return ""
    }
    
    func createRandomPlayers() -> [Player] {
        guard let userPosition = pickUserPosition() else {
            fatalError("No valid user position found for \(selectedPosition) with action \(selectedAction)")
        }
        
        return createAndReorderPlayers(playerPosition: userPosition)
    }
    
    func createAndReorderPlayers(playerPosition: String) -> [Player] {
        let positionList = rangeHelper.positionOrders[size]!
        var playersReordered: [Player] = []
        var index = positionList.firstIndex(of: playerPosition)!
        let playerCount = Int(size)!
        
        for _ in 1...playerCount {
            let player: Player = Player(position: positionList[index], stack: 100.0)
            if positionList[index] == "SB" {
                player.currentBetAmount = 0.5
                player.stack -= 0.5
                pot += 0.5
            }
            if positionList[index] == "BB" {
                player.currentBetAmount = 1.0
                player.stack -= 1.0
                pot += 1.0
            }
            
            playersReordered.append(player)
            index = (index + 1) % playerCount
            
        }
         
        return playersReordered
    }
    
    func pickUserPosition() -> String? {
        if selectedPosition.lowercased() == "any" {
            if selectedAction.lowercased() == "any" {
                // any random position
                return rangeHelper.positionOrders[size]?.randomElement()
            } else {
                return rangeHelper.getHeros(scenario: selectedAction, size: size).randomElement()
            }
        } else {
            return selectedPosition.uppercased()
        }
    }
    
    func raise(player: Player) {
        var raiseTo: Double = 0.0

        switch betNumber {
        case 1:
            raiseTo = 2.5
        case 2:
            raiseTo = lastRaise * 4
        case 3:
            raiseTo = lastRaise * 2.5
        case 4:
            raiseTo = player.stack // go all-in
        default:
            raiseTo = player.stack
        }

        // Round to nearest 0.5
        raiseTo = (raiseTo * 2).rounded() / 2

        let potIncrease = player.raise(amountRaisingTo: raiseTo)
        betNumber += 1
        lastRaise = player.currentBetAmount
        pot += potIncrease
    }
    
    @MainActor
    func userMadeMove(decision: Action) -> Bool {
        guard let continuation = pendingUserMoveContinuation else { return false }
        continuation.resume(returning: decision)
        pendingUserMoveContinuation = nil
        return decision == correctMove
    }
    
    @MainActor
    func waitForUserInput() async -> Action {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Action, Never>) in
            // Save the continuation so it can be resumed when the user makes a move
            self.pendingUserMoveContinuation = continuation
        }
    }
    
    func handleUserDecision(playerCopy: Player, turn: Int, idealDecision: Action) async {
        if !testingMode {
            waitingForUserInput = true
            let userDecision = await waitForUserInput()
            waitingForUserInput = false
            
            let raiseType = getRaiseType()
            let betAmountValue = (userDecision == .raise || userDecision == .call) ? players[turn].currentBetAmount : 0
            if game.modelContext == nil {
                context?.insert(game)
            }
            
            // turn position string into enum
            guard let pos = Position(rawValue: user?.position.lowercased() ?? ""),
                  let action = Action(rawValue: userDecision.rawValue.lowercased()) else {
                // handle invalid case here, e.g., return or throw
                return
            }
            
            let handLog = PreflopLog(
                position: pos,
                hand: user?.hand.handToString() ?? "",
                pair: user?.handIsPair() ?? false,
                action: action, raiseType: raiseType,
                betAmount: betAmountValue,
                pot: pot,
                xpEarned: 0,
                isCorrect: false,
                game: game
            )
            context?.insert(handLog)
            if userDecision == idealDecision {
                players[turn] = playerCopy
                handLog.isCorrect = true
                handLog.xpEarned = 10
                // give profile xp
                profile?.addXP(amount: 10)
                
                // Makes sure they update in sync on the ui
                await MainActor.run {
                    score += 1
                    handsPlayed += 1
                }
            } else {
                showIncorrectPopup = true
                adviceText = "Needed to " + idealDecision.rawValue.capitalizeFirst
                players[turn] = playerCopy
                handsPlayed += 1
            }
        } else {
            playerCopy.lastMove = .fold
        }
    }
    
    // returns open, vsRaise, "3bet, 4bet", "5bet"
    func getRaiseType() -> RaiseType {
        if (betNumber == 1) {
            return .open
        }
        else if (betNumber == 2) {
            return .vsRaise
        }
        else if (betNumber == 3) {
            return .threeBet
        }
        else if (betNumber == 4) {
            return .fourBet
        }
        else {
            return .fiveBet
        }
    }
    
    func setContext(_ context: ModelContext) {
        self.context = context
    }
    
    func toString() -> String {
        return "Players: " + players[0].toString() + players[1].toString() + players[2].toString() + players[3].toString() + players[4].toString() + players[5].toString()
    }
}
