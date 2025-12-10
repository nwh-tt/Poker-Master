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
        player = AIPlayer(name: "AI1", fullName: "AI Full Name", position: "BB")
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
        XCTAssertFalse(player.isOutOfMoney(game: 0))
        XCTAssertEqual(player.lastMove(game: 0), .none)
    }
    
    func testLastBetBlank() {
        let lastBet = player.lastBet(game: 0, round: 0)
        XCTAssertEqual(lastBet, 0)
    }
    
    func testLastBet_raise() {
        _ = player.raise(amount: 20, game: 0, round: 0)
        let lastBet = player.lastBet(game: 0, round: 0)
        XCTAssertEqual(lastBet, 20)
    }
    
    func testLastBet_call() {
        _ = player.call(amount: 20,game: 0, round: 0)
        let lastBet = player.lastBet(game: 0, round: 0)
        XCTAssertEqual(lastBet, 20)
    }
    
    func testLastBet_differentGame() {
        _ = player.raise(amount: 20,game: 1, round: 0)
        let lastBet = player.lastBet(game: 0, round: 0)
        XCTAssertEqual(lastBet, 0)
    }
    
    func testLastBet_differentRound() {
        _ = player.raise(amount: 20,game: 0, round: 0)
        let lastBet = player.lastBet(game: 0, round: 1)
        XCTAssertEqual(lastBet, 0)
    }
    
    func testLastMoveForRound_differentRound() {
        _ = player.raise(amount: 20, game: 0, round: 0)
        var lastMove = player.lastMoveForRound(game: 0, round: 1)
        XCTAssertEqual(lastMove, .none)
        
        _ = player.raise(amount: 20, game: 1, round: 0)
        lastMove = player.lastMoveForRound(game: 1, round: 1)
        XCTAssertEqual(lastMove, .none)
    }
    
    func testLastMoveForRound_differentGame() {
        _ = player.raise(amount: 20, game: 0, round: 0)
        var lastMove = player.lastMoveForRound(game: 1, round: 0)
        XCTAssertEqual(lastMove, .none)
        
        _ = player.raise(amount: 20, game: 1, round: 0)
        lastMove = player.lastMoveForRound(game: 0, round: 1)
        XCTAssertEqual(lastMove, .none)
    }
    
    func testLastMoveForRound_raise() {
        _ = player.raise(amount: 20,game: 0, round: 0)
        var lastMove = player.lastMoveForRound(game: 0, round: 0)
        XCTAssertEqual(lastMove, .raise)
        
        _ = player.raise(amount: 20,game: 0, round: 1)
        lastMove = player.lastMoveForRound(game: 0, round: 1)
        XCTAssertEqual(lastMove, .raise)
        
        _ = player.raise(amount: 20,game: 1, round: 1)
        lastMove = player.lastMoveForRound(game: 1, round: 1)
        XCTAssertEqual(lastMove, .raise)
    }
    
    func testLastMoveForRound_call() {
        _ = player.call(amount: 20, game: 0, round: 0)
        var lastMove = player.lastMoveForRound(game: 0, round: 0)
        XCTAssertEqual(lastMove, .call)
        
        _ = player.call(amount: 20, game: 0, round: 1)
        lastMove = player.lastMoveForRound(game: 0, round: 1)
        XCTAssertEqual(lastMove, .call)
        
        _ = player.call(amount: 20, game: 1, round: 1)
        lastMove = player.lastMoveForRound(game: 1, round: 1)
        XCTAssertEqual(lastMove, .call)
    }
    
    func testLastMoveForRound_fold() {
        player.fold(game: 0, round: 0)
        var lastMove = player.lastMoveForRound(game: 0, round: 0)
        XCTAssertEqual(lastMove, .fold)
        
        player.fold(game: 0, round: 1)
        lastMove = player.lastMoveForRound(game: 0, round: 1)
        XCTAssertEqual(lastMove, .fold)
        
        player.fold(game: 1, round: 1)
        lastMove = player.lastMoveForRound(game: 1, round: 1)
        XCTAssertEqual(lastMove, .fold)
    }
    
    func testLastMove_differentGame() {
        _ = player.raise(amount: 20, game: 0, round: 0)
        let lastMove = player.lastMove(game: 1)
        XCTAssertEqual(lastMove, .none)
    }
    
    func testLastMove_raise() {
        _ = player.raise(amount: 20,game: 0, round: 0)
        var lastMove = player.lastMove(game: 0)
        XCTAssertEqual(lastMove, .raise)
        
        _ = player.raise(amount: 20,game: 1, round: 1)
        lastMove = player.lastMove(game: 1)
        XCTAssertEqual(lastMove, .raise)
    }
    
    func testLastMove_call() {
        _ = player.call(amount: 20,game: 0, round: 0)
        var lastMove = player.lastMove(game: 0)
        XCTAssertEqual(lastMove, .call)
        
        _ = player.call(amount: 20, game: 1, round: 1)
        lastMove = player.lastMove(game: 1)
        XCTAssertEqual(lastMove, .call)
    }
    
    func testLastMove_fold() {
        player.fold(game: 0, round: 0)
        var lastMove = player.lastMove(game: 0)
        XCTAssertEqual(lastMove, .fold)
        
        player.fold(game: 1, round: 1)
        lastMove = player.lastMove(game: 1)
        XCTAssertEqual(lastMove, .fold)
    }
    
    func testRaise_reducesStackAndRecordsAction() {
        let potIncrease = player.raise(amount: 20, game: 0,  round: 0)
        
        XCTAssertEqual(potIncrease, 20)
        XCTAssertEqual(player.stack, 80)
        XCTAssertEqual(player.lastMoveForRound(game: 0, round: 0), .raise)
        XCTAssertEqual(player.moveHistory.count, 1)
        XCTAssertEqual(player.lastBet(game: 0, round: 0), 20)
    }
    
    func testCall_reducesStackAndRecordsAction() {
        let potIncrease = player.call(amount: 15, game: 0, round: 0)
        
        XCTAssertEqual(potIncrease, 15)
        XCTAssertEqual(player.stack, 85)
        XCTAssertEqual(player.lastMove(game: 0), .call)
        XCTAssertEqual(player.lastBet(game: 0, round: 0), 15)
    }
    
    func testFold_recordsAction() {
        player.fold(game: 0, round: 0)
        XCTAssertEqual(player.lastMove(game: 0), .fold)
        XCTAssertEqual(player.lastBet(game: 0, round: 0), 0)
    }
    
    func testCheck_recordsAction() {
        player.check(game: 0, round: 0)
        XCTAssertEqual(player.lastMove(game: 0), .check)
        XCTAssertEqual(player.lastBet(game: 0, round: 0), 0)
    }
    
    func testRaise_roundSeperation() {
        _ = player.raise(amount: 10, game: 0, round: 0)
        let potIncrease = player.raise(amount: 25, game: 0, round: 0)
        XCTAssertEqual(potIncrease, 15, "Only additional amount should be bet")
        XCTAssertEqual(player.stack, 75)
        
        player.stack = 100
        _ = player.raise(amount: 10, game: 1, round: 0)
        let potIncrease2 = player.raise(amount: 25, game: 1, round: 0)
        XCTAssertEqual(potIncrease2, 15, "Only additional amount should be bet")
        XCTAssertEqual(player.stack, 75)
        
        player.stack = 100
        _ = player.raise(amount: 10, game: 2, round: 0)
        let potIncrease3 = player.raise(amount: 25, game: 2, round: 1)
        XCTAssertEqual(potIncrease3, 25, "Only additional amount should be bet")
        XCTAssertEqual(player.stack, 65)
    }
    
    func testRaise_gameSeperation() {
        _ = player.raise(amount: 10, game: 1, round: 0)
        let potIncrease = player.raise(amount: 25, game: 1, round: 0)
        XCTAssertEqual(potIncrease, 15, "Only additional amount should be bet")
        XCTAssertEqual(player.stack, 75)
        
        player.stack = 100
        _ = player.raise(amount: 10, game: 2, round: 0)
        let potIncrease3 = player.raise(amount: 25, game: 2, round: 1)
        XCTAssertEqual(potIncrease3, 25, "Only additional amount should be bet")
        XCTAssertEqual(player.stack, 65)
        
        player.stack = 100
        _ = player.raise(amount: 10, game: 3, round: 0)
        let potIncrease2 = player.raise(amount: 25, game: 4, round: 0)
        XCTAssertEqual(potIncrease2, 25, "Only additional amount should be bet")
        XCTAssertEqual(player.stack, 65)
    }
    
    func testCall_default() {
        let potIncrease = player.call(amount: 20, game: 0,  round: 0)
        XCTAssertEqual(potIncrease, 20)
        XCTAssertEqual(player.stack, 80)
    }
    
    func testCall_afterPrevBet() {
        _ = player.raise(amount: 10, game: 0, round: 0)
        let potIncrease = player.call(amount: 20, game: 0, round: 0)
        XCTAssertEqual(potIncrease, 10)
        XCTAssertEqual(player.stack, 80)
        
        player.stack = 100
        _ = player.raise(amount: 10, game: 1, round: 0)
        let potIncrease2 = player.call(amount: 20, game: 1, round: 0)
        XCTAssertEqual(potIncrease2, 10)
        XCTAssertEqual(player.stack, 80)
    }
    
    func testCall_ignoresPrevBet() {
        // Test for round
        _ = player.raise(amount: 10, game: 0, round: 0)
        let potIncrease = player.call(amount: 20, game: 0, round: 1)
        XCTAssertEqual(potIncrease, 20)
        XCTAssertEqual(player.stack, 70)
        
        // test for game
        player.stack = 100
        _ = player.raise(amount: 10, game: 1, round: 0)
        let potIncrease2 = player.call(amount: 20, game: 2, round: 0)
        XCTAssertEqual(potIncrease2, 20)
        XCTAssertEqual(player.stack, 70)
        
    }
    
    func testIsOutOfMoney_differentGame() {
        _ = player.raise(amount: 100, game: 0, round: 0)
        XCTAssertTrue(player.isOutOfMoney(game: 1))
    }
    
    func testIsOutOfMoney_noMoveHistory_noMoney() {
        player.stack = 0
        XCTAssertTrue(player.isOutOfMoney(game: 1))
    }
    
    func testIsOutOfMoney_noMoveHistory_withMoney() {
        XCTAssertFalse(player.isOutOfMoney(game: 1))
    }
    
    func testIsOutOfMoney_negativeStack() {
        player.stack = -1
        XCTAssertTrue(player.isOutOfMoney(game: 1))
    }
    
    func testIsOutOfMoneySameGame_AfterRaise() {
        _ = player.raise(amount: 100, game: 0, round: 0)
        XCTAssertFalse(player.isOutOfMoney(game: 0))
    }
    
    func testIsOutOfMoneySameGame_AfterCall() {
        _ = player.call(amount: 100, game: 0, round: 0)
        XCTAssertFalse(player.isOutOfMoney(game: 0))
    }
}
