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
    @Published var score: Int = 0
    @Published var handsPlayed: Int = 0
    
    
    // variables needed for incorrect or correct move
    @Published var showIncorrectPopup: Bool = false
    @Published var adviceText: String = ""
    
    let deck: Deck = Deck()
    var turn: Int = 0
    var betNumber: Int = 1
    var lastRaise: Double = 0.0
    var villain: Player? = nil
    let decisionMaker: DecisionMaker
    var activePlayers: Int = 6
    
    var correctMove: LastMove = .none // used to check if the user made the correct move and update ui
    var pendingUserMoveContinuation: CheckedContinuation<LastMove, Never>?
    
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
        pot = 1.5
    }
    
    func startGame() async {
        print("Game has started")
        for player in players {
            print(player.toString())
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
        
        
        await executeLoop()
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
        activePlayers = 6
        
        // Optionally delay before starting the game again
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            await startGame()
        }
    }

    
    @MainActor
    func executeLoop() async {
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
            if (players[turn].lastMove == LastMove.fold) {
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
                raise(player: playerCopy)
                villain = playerCopy
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
            index = (index + 1) % 6
            
        }
         
        return playersReordered
    }
    
    func raise(player: Player) {
        var raiseTo: Double = 0.0

        switch betNumber {
        case 1:
            raiseTo = 2.5
        case 2:
            raiseTo = 2.5 * 3.5
        case 3:
            raiseTo = (2.5 * 3.5) * 2
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

    func handleUserDecision(playerCopy: Player, turn: Int, idealDecision: LastMove) async {
        if !testingMode {
            waitingForUserInput = true
            let userDecision = await waitForUserInput()
            waitingForUserInput = false
                
            if userDecision == idealDecision {
                players[turn] = playerCopy
                // Makes sure they update in sync on the ui
                await MainActor.run {
                    score += 1
                    handsPlayed += 1
                }
            } else {
                showIncorrectPopup = true
                adviceText = "Correct Move: " + idealDecision.rawValue
                players[turn] = playerCopy
                handsPlayed += 1
            }
        } else {
            playerCopy.lastMove = .fold
            activePlayers -= 1
        }
    }
    
    func toString() -> String {
        return "Players: " + players[0].toString() + players[1].toString() + players[2].toString() + players[3].toString() + players[4].toString() + players[5].toString()
    }
    
}
