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
    let deck: Deck = Deck()
    var turn: Int = 0
    var betNumber: Int = 1
    var lastRaise: Double = 0.0
    var villian: Player? = nil
    let decisionMaker: DecisionMaker
    
    var gameplaySpeed: Int
    
    
    init(decisionMaker: DecisionMaker = DecisionMaker(), gameplaySpeed: Int = 3) {
        self.gameplaySpeed = gameplaySpeed // Controls speed of play
        self.decisionMaker = decisionMaker
        players = createRandomPlayers()
        user = players[0]
        // deal two cards to each player
        for player in players {
            player.hand.append(deck.dealCard())
            player.hand.append(deck.dealCard())
            pot = 3
        }
        // set the playerTurn variable equal to the index that of the utg player
        turn = players.firstIndex(where: { $0.position == "UTG" })!
        
        
    }
    
    func startGame() async {
        print("Game has started")
        for player in players {
            print(player.toString())
        }
        let gameTask = Task {
            await executeLoop()
        }
        
        await gameTask.value
        
        for player in players {
            print(player.toString())
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
            
            // check if the player is the user
            if (user?.position == players[turn].position) {
                // wait for user to make a move
                //turn = (turn + 1) % 6
                //continue
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
            
            let decision = decisionMaker.determineMovePreFlop(hero: players[turn], villian: villian ?? nil, betNumber: betNumber)
            let playerCopy = Player(position: players[turn].position, stack: players[turn].stack, betAmount: players[turn].currentBetAmount, hand: players[turn].hand, lastMove: players[turn].lastMove)
            playerCopy.hand = players[turn].hand
            if (decision == "raise") {
                // Update players fields
                let potIncrease = playerCopy.raise(amountRaisingTo: lastRaise + 10.0)
                betNumber += 1
                lastRaise = playerCopy.currentBetAmount
                villian = players[turn]
                pot += potIncrease
                print("Player \(playerCopy.position) has raised to \(playerCopy.currentBetAmount) ---------- Pot Now: " + String(pot))
            }
            else if (decision == "call") {
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
        print("Pre flop betting is over players remaining: ")
        for p in players {
            if p.lastMove != LastMove.fold {
                print(p.position + ": " + String(p.currentBetAmount))
            }
        }
        print("Pot = " + String(pot))
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
    
    // right a toString functiobn
    func toString() -> String {
        return "Players: " + players[0].toString() + players[1].toString() + players[2].toString() + players[3].toString() + players[4].toString() + players[5].toString()
    }
    
}
