//
//  GameManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/18/24.
//

import Foundation

class GameManager: ObservableObject {
    @Published var players: [Player] = []
    @Published var user: Player? = nil
    @Published var pot: Double = 0.0
    @Published var waitingForUserInput: Bool = false
    
    // variables needed for incorrect or correct move
    @Published var showIncorrectPopup: Bool = false
    @Published var adviceText: String = ""
    
    let deck: Deck = Deck()
    var turn: Int = 0
    var betNumber: Int = 1
    var lastRaise: Double = 0.0
    var villain: Player? = nil
    let decisionMaker: DecisionMaker
    
    private var correctMove: LastMove = .none // used to check if the user made the correct move and update ui
    private var pendingUserMoveContinuation: CheckedContinuation<LastMove, Never>?
    
    var gameplaySpeed: Int
    var testingMode: Bool
    
    
    init(decisionMaker: DecisionMaker = DecisionMaker(), gameplaySpeed: Int = 3, testingMode: Bool = false) {
        self.gameplaySpeed = gameplaySpeed // Controls speed of play
        self.decisionMaker = decisionMaker
        self.testingMode = testingMode
        players = createRandomPlayers()
        user = players[0]
        // deal two cards to each player
        for player in players {
            player.hand.append(deck.dealCard())
            player.hand.append(deck.dealCard())
        }
        pot = 3
    }
    
    func startGame() async {
        print("Game has started")
        for player in players {
            print(player.toString())
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
        let gameTask = Task {
            await executeLoop()
        }
        
        await gameTask.value
    }
    
    func resetAndStartNewGame() {
        // Reset players and reinitialize the deck
        deck.resetDeck()
        players = createRandomPlayers()
        user = players[0]
        
        // Deal two new cards to each player
        for player in players {
            player.hand = [deck.dealCard(), deck.dealCard()]
        }
        
        // Reset game-related variables
        pot = 3
        turn = players.firstIndex(where: { $0.position == "UTG" })!
        betNumber = 1
        lastRaise = 0.0
        villain = nil
        correctMove = .none
        pendingUserMoveContinuation = nil
        waitingForUserInput = false
        showIncorrectPopup = false
        adviceText = ""
        
        // Optionally delay before starting the game again
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            await startGame()
        }
    }

    
    @MainActor
    func executeLoop() async {
        var activePlayers = 6
        while (true) {
            // need to check if the betting is over pre flop
            // 1. check if all players have had a turn
            // 2. check if all players have equalled the bet or folded
            // 3. check if only one player remains
            
            // User is the last player - end game
            if (activePlayers == 1) {
                print("Only one player remains")
                break
            }
            
            // check if the cpu player has folded
            if (players[turn % 6].lastMove == LastMove.fold) {
                turn = (turn + 1) % 6
                continue
            }
            
            // need to check if player last bet == last raise - means it checked through and betting is over
            if (lastRaise != 0.0 && players[turn].currentBetAmount == lastRaise) {
                break
            }
            
            let idealDecision = decisionMaker.determineMovePreFlop(hero: players[turn], villian: villain ?? nil, betNumber: betNumber)
            let playerCopy = Player(position: players[turn].position, stack: players[turn].stack, betAmount: players[turn].currentBetAmount, hand: players[turn].hand, lastMove: players[turn].lastMove)
            
            // when in testing mode we skip over waiting for the user
            if (!testingMode) {
                // check if the player is the user
                if (user?.position == players[turn].position) {
                    correctMove = idealDecision
                    waitingForUserInput = true // unlock buttons
                    let userDecision = await waitForUserInput()
                    waitingForUserInput = false // lock buttons again
                    if (userDecision == idealDecision) {
                        break
                    } else {
                        // break loop print incorrect you should have: right move'
                        showIncorrectPopup = true
                        adviceText = "Correct Move: " + idealDecision.rawValue
                        break
                    }
                }
            }
            
            
            if (idealDecision == .raise) {
                // Update players fields
                let potIncrease = playerCopy.raise(amountRaisingTo: lastRaise + 10.0)
                betNumber += 1
                lastRaise = playerCopy.currentBetAmount
                villain = players[turn]
                pot += potIncrease
                print("Player \(playerCopy.position) has raised to \(playerCopy.currentBetAmount) ---------- Pot Now: " + String(pot))
            }
            else if (idealDecision == .call) {
                // need to save pot increase to account for raise -> raise or raise -> call another raise
                let potIncrease = playerCopy.call(amountCallingTo: lastRaise)
                
                pot += potIncrease
                print("Player \(playerCopy.position) has called ---------- Pot Now: " + String(pot))
            }
            else {
                playerCopy.lastMove = LastMove.fold
                activePlayers -= 1
                print("Player \(playerCopy.position) has folded leaving \(activePlayers) players remaining")
            }
                
            players[turn] = playerCopy
            turn = (turn + 1) % 6
            
            let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s
            try? await Task.sleep(nanoseconds: sleepTime)
        }
//        print("Pre flop betting is over players remaining: ")
//        for p in players {
//            if p.lastMove != LastMove.fold {
//                print(p.position + ": " + String(p.currentBetAmount))
//            }
//        }
//        print("Pot = " + String(pot))
    }
    
    @MainActor
    func waitForUserInput() async -> LastMove {
        return await withCheckedContinuation { (continuation: CheckedContinuation<LastMove, Never>) in
            // Save the continuation so it can be resumed when the user makes a move
            self.pendingUserMoveContinuation = continuation
        }
    }
    
    @MainActor
    func userMadeMove(decision: LastMove) -> Bool {
        guard let continuation = pendingUserMoveContinuation else { return false }
        continuation.resume(returning: decision)
        pendingUserMoveContinuation = nil
        return decision == correctMove
    }
        
    
    func createRandomPlayers() -> [Player] {
        let positionList = ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        let userPosition = positionList.randomElement()!
        
        return createAndReorderPlayers(playerPosition: userPosition)
    }
    
    func createAndReorderPlayers(playerPosition: String) -> [Player] {
        let positionList = ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        var playersReordered: [Player] = []
        var index = positionList.firstIndex(of: playerPosition)!
        
        for _ in 1...6 {
            let player: Player = Player(position: positionList[index], stack: 100.0)
            if positionList[index] == "SB" {
                player.currentBetAmount = 1.0
                player.stack -= 1.0
            }
            if positionList[index] == "BB" {
                player.currentBetAmount = 2.0
                player.stack -= 2.0
            }
            
            playersReordered.append(player)
            index = (index + 1) % 6
            
        }
         
        return playersReordered
    }
    
    
    func toString() -> String {
        return "Players: " + players[0].toString() + players[1].toString() + players[2].toString() + players[3].toString() + players[4].toString() + players[5].toString()
    }
    
}
