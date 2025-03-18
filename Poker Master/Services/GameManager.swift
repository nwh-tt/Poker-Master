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
    let decisionMaker: DecisionMaker = DecisionMaker()
    
    
    init() {
        players = createRandomPlayers()
        user = players[0]
        // deal two cards to each player
        for player in players {
            player.hand.append(deck.dealCard())
            player.hand.append(deck.dealCard())
            if (player.position == "SB") {
                player.betAmount = 1.0
                pot += 1.0
            }
            if (player.position == "BB") {
                player.betAmount = 2.0
                pot += 2.0
            }
        }
        // set the playerTurn variable equal to the index that of the utg player
        turn = players.firstIndex(where: { $0.position == "UTG" })!
    }
    
    func startGame() async {
        var bettingOver = false
        
        
        
        print("Game has started")
        for player in players {
            print(player.toString())
        }
        let gameTask = Task {
            await executeLoop()
        }
        
        await gameTask.value
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
            if (lastRaise != 0.0 && players[turn].betAmount == lastRaise) {
                break
            }
            
            let decision = decisionMaker.determineMovePreFlop(hero: players[turn], villian: villian ?? nil, betNumber: betNumber)
            let playerCopy = Player(position: players[turn].position, stack: players[turn].stack)
            playerCopy.hand = players[turn].hand
            if (decision == "raise") {
                // Update players fields
                playerCopy.raise(amount: lastRaise + 10.0)
                betNumber += 1
                lastRaise = playerCopy.betAmount
                villian = players[turn]
                pot += lastRaise
                print("Player \(playerCopy.position) has raised to \(playerCopy.betAmount) ---------- Pot Now: " + String(pot))
            }
            else if (decision == "call") {
                playerCopy.call(amount: lastRaise)
                
                pot += lastRaise
                print("Player \(playerCopy.position) has called ---------- Pot Now: " + String(pot))
            }
            else {
                playerCopy.lastMove = LastMove.fold
                activePlayers -= 1
                print("Player \(playerCopy.position) has folded leaving \(activePlayers) players remaining")
            }
                
            players[turn] = playerCopy
            turn = (turn + 1) % 6
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        print("Pre flop betting is over players remaining: ")
        for p in players {
            if p.lastMove != LastMove.fold {
                print(p.position + ": " + String(p.betAmount))
            }
        }
        print("Pot = " + String(pot))
    }
        
    
    func createRandomPlayers() -> [Player] {
        let positionList = ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        let userPosition = positionList.randomElement()!
        
        return reorderPlayers(playerPosition: userPosition)
    }
    
    func reorderPlayers(playerPosition: String) -> [Player] {
        let positionList = ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        var playersReordered: [Player] = []
        var index = positionList.firstIndex(of: playerPosition)!
        
        for _ in 1...6 {
            playersReordered.append(Player(position: positionList[index], stack: 100.0))
            index = (index + 1) % 6
        }
         
        return playersReordered
    }
    
    func determineMove(player: Player) {
        
        
    }
    
    // right a toString functiobn
    func toString() -> String {
        return "Players: " + players[0].toString() + players[1].toString() + players[2].toString() + players[3].toString() + players[4].toString() + players[5].toString()
    }
    
}
