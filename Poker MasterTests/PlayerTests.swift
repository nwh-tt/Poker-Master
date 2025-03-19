//
//  PlayerTests.swift
//  Poker MasterTests
//
//  Created by Ned Whittleton on 3/18/25.
//

import XCTest
@testable import Poker_Master

final class PlayerTests: XCTestCase {

    func testPlayerInitialization() {
        let player = Player(position: "BTN", stack: 1000.0)
        
        XCTAssertEqual(player.position, "BTN")
        XCTAssertEqual(player.stack, 1000.0)
        XCTAssertEqual(player.lastMove, LastMove.none)
        XCTAssertEqual(player.currentBetAmount, 0.0)
        XCTAssertTrue(player.hand.isEmpty)
    }

    func testBetFunctionality() {
        let player = Player(position: "CO", stack: 1000.0)
        player.bet(amount: 100.0)
        
        XCTAssertEqual(player.stack, 900.0)
        XCTAssertEqual(player.currentBetAmount, 100.0)
    }

    func testRaiseDefaultFunctionality() {
        let player = Player(position: "MP", stack: 1000.0)
        player.raise(amountRaisingTo: 150.0)
        
        XCTAssertEqual(player.stack, 850.0)
        XCTAssertEqual(player.currentBetAmount, 150.0)
        XCTAssertEqual(player.lastMove, LastMove.raise)
    }
    
    func testRaiseWithPreviousBetFunctionality() {
        let player = Player(position: "MP", stack: 1000.0)
        player.raise(amountRaisingTo: 50)
        player.raise(amountRaisingTo: 150.0)
        
        XCTAssertEqual(player.stack, 850.0)
        XCTAssertEqual(player.currentBetAmount, 150.0)
        XCTAssertEqual(player.lastMove, LastMove.raise)
    }

    func testCallDefaultFunctionality() {
        let player = Player(position: "SB", stack: 1000.0)
        player.call(amountCallingTo: 50.0)
        
        XCTAssertEqual(player.stack, 950.0)
        XCTAssertEqual(player.currentBetAmount, 50.0)
        XCTAssertEqual(player.lastMove, LastMove.call)
    }
    
    func testCallRaiseFunctionality() {
        let player = Player(position: "SB", stack: 1000.0)
        player.raise(amountRaisingTo: 50)
        // Imagine someone else raises to 100 and they want to call
        player.call(amountCallingTo: 100.0)
        
        XCTAssertEqual(player.stack, 900.0)
        XCTAssertEqual(player.currentBetAmount, 100.0)
        XCTAssertEqual(player.lastMove, LastMove.call)
    }
    
    

    func testDealFunctionality() {
        let player = Player(position: "BB", stack: 1000.0)
        let card1 = Card(suit: "spade", rank: "A")
        let card2 = Card(suit: "spade", rank: "K")
        
        player.deal(card: card1)
        player.deal(card: card2)
        
        XCTAssertEqual(player.hand.count, 2)
        XCTAssertEqual(player.hand[0].rank, "A")
        XCTAssertEqual(player.hand[1].rank, "K")
    }

    func testGetHandSuited() {
        let player = Player(position: "HJ", stack: 1000.0)
        let card1 = Card(suit: "spade", rank: "A")
        let card2 = Card(suit: "spade", rank: "K")
        
        player.deal(card: card1)
        player.deal(card: card2)
        
        XCTAssertEqual(player.getHand(), "AKs")
    }

    func testGetHandOffSuit() {
        let player = Player(position: "UTG", stack: 1000.0)
        let card1 = Card(suit: "diamond", rank: "J")
        let card2 = Card(suit: "spade", rank: "Q")
        
        player.deal(card: card1)
        player.deal(card: card2)
        
        XCTAssertEqual(player.getHand(), "QJo")
    }

    func testGetHandPair() {
        let player = Player(position: "CO", stack: 1000.0)
        let card1 = Card(suit: "club", rank: "9")
        let card2 = Card(suit: "diamond", rank: "9")
        
        player.deal(card: card1)
        player.deal(card: card2)
        
        XCTAssertEqual(player.getHand(), "99")
    }
}

