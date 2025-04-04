//
//  SimplePreFlopManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/2/25.
//

import Foundation

class SimplePreFlopManager: GameManager {
    
    
    override init(decisionMaker: DecisionMaker = DecisionMaker(), gameplaySpeed: Int, testingMode: Bool) {
        super.init(gameplaySpeed: gameplaySpeed, testingMode: testingMode)
        
        // Select one player to be the villian
        villian = players.randomElement()
        
        // select bet number villian will bet to (1 - open raise, 2 - 3 bet, 3 - 4bet, 4, 5bet
        betNumber = Int.random(in: 1...5)
        
        // Need to set the user hands based on whether they can make it to the villian bet or not
        
    }
    
    override func executeLoop() async {
        while (true) {
            // fold if the player is not the villian
            let playerCopy = Player(position: players[turn].position, stack: players[turn].stack, betAmount: players[turn].currentBetAmount, hand: players[turn].hand, lastMove: players[turn].lastMove)
            playerCopy.hand = players[turn].hand
            
            if (players[turn % 6].position != villian?.position) {
                players[turn % 6].lastMove = .fold
            }
            
            turn = (turn + 1) % 6
        }
    }
    
}
