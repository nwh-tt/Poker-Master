//
//  AIPlayerTests.swift
//  Poker Master
//
//  Created by Ned Whittleton on 10/16/25.
//

import XCTest
@testable import Poker_Master

final class AIPlayerTests: XCTestCase {
    
    var player: AIPlayer!
    
    override func setUp() {
        super.setUp()
        player = AIPlayer(name: "AI1", position: "BB", stack: 100)
    }
    
    override func tearDown() {
        player = nil
        super.tearDown()
    }
    
    func testInitialValues() {
        XCTAssertEqual(player.name, "AI1")
        XCTAssertEqual(player.position, "BB")
        XCTAssertEqual(player.stack, 100)
        XCTAssertTrue(player.moveHistory.isEmpty)
        XCTAssertFalse(player.isOutOfMoney())
        XCTAssertEqual(player.lastMove(), .none)
    }
    
    func testLastBetBlank() {
        let lastBet = player.lastBet(round: 0)
        XCTAssertEqual(lastBet, 0)
    }
    
    func testLastBetRaise() {
        _ = player.raise(amount: 20, round: 0)
        let lastBet = player.lastBet(round: 0)
        XCTAssertEqual(lastBet, 20)
    }
    
    func testLastBetDifferentRound() {
        _ = player.raise(amount: 20, round: 0)
        let lastBet = player.lastBet(round: 1)
        XCTAssertEqual(lastBet, 0)
    }
    
    func testRaiseReducesStackAndRecordsAction() {
        let potIncrease = player.raise(amount: 20, round: 0)
        
        XCTAssertEqual(potIncrease, 20)
        XCTAssertEqual(player.stack, 80)
        XCTAssertEqual(player.lastMove(), .raise)
        XCTAssertEqual(player.moveHistory.count, 1)
        XCTAssertEqual(player.lastBet(round: 0), 20)
    }
    
    func testCallReducesStackAndRecordsAction() {
        let potIncrease = player.call(amount: 15, round: 0)
        
        XCTAssertEqual(potIncrease, 15)
        XCTAssertEqual(player.stack, 85)
        XCTAssertEqual(player.lastMove(), .call)
        XCTAssertEqual(player.lastBet(round: 0), 15)
    }
    
    func testFoldRecordsAction() {
        player.fold(round: 0)
        XCTAssertEqual(player.lastMove(), .fold)
        XCTAssertEqual(player.lastBet(round: 0), 0)
    }
    
    func testRaiseAdjustmentWithinSameRound() {
        _ = player.raise(amount: 10, round: 0)
        let potIncrease = player.raise(amount: 25, round: 0)
        XCTAssertEqual(potIncrease, 15, "Only additional amount should be bet")
        XCTAssertEqual(player.stack, 75)
    }
    
    func testRaiseIgnoresPrevRoundBet() {
        _ = player.raise(amount: 10, round: 0)
        let potIncrease = player.raise(amount: 25, round: 1)
        XCTAssertEqual(potIncrease, 25, "Whole bet should be counted")
        XCTAssertEqual(player.stack, 65)
    }
    
    func testCallDefault() {
        let potIncrease = player.call(amount: 20, round: 0)
        XCTAssertEqual(potIncrease, 20)
        XCTAssertEqual(player.stack, 80)
    }
    
    func testCallAfterPrevBet() {
        _ = player.raise(amount: 10, round: 0)
        let potIncrease = player.call(amount: 20, round: 0)
        XCTAssertEqual(potIncrease, 10)
        XCTAssertEqual(player.stack, 80)
    }
    
    func testCallIgnoresPrevRoundBet() {
        _ = player.raise(amount: 10, round: 0)
        let potIncrease = player.call(amount: 20, round: 1)
        XCTAssertEqual(potIncrease, 20)
        XCTAssertEqual(player.stack, 70)
    }
    
    func testIsOutOfMoney() {
        _ = player.raise(amount: 100, round: 0)
        XCTAssertTrue(player.isOutOfMoney())
    }
    
    func testGetHandPairsSuitedOffsuited() {
        player.hand = [
            Card(suit: "heart", rank: "A"),
            Card(suit: "spade", rank: "A")
        ]
        XCTAssertEqual(player.getHand(), "AA", "Pocket pair should show both ranks")
        
        player.hand = [
            Card(suit: "heart", rank: "A"),
            Card(suit: "heart", rank: "K")
        ]
        XCTAssertEqual(player.getHand(), "AKs", "Suited cards should end with 's'")
        
        player.hand = [
            Card(suit: "heart", rank: "A"),
            Card(suit: "spade", rank: "K")
        ]
        XCTAssertEqual(player.getHand(), "AKo", "Offsuit cards should end with 'o'")
    }
}
