//
//  AIGameManagerTests.swift
//  Poker Master
//
//  Created by Ned Whittleton on 10/16/25.
//

import XCTest
@testable import Poker_Master

final class AIGameManagerTests: XCTestCase {
    
    var manager: AIGameManager!
    var players: [AIPlayer]!
    
    override func setUp() async throws {
        manager = AIGameManager(gameplaySpeed: 3, testingMode: true)
        
        players = manager.createRandomPlayers(aiNames: [
            FetchPlayerResponse(name: "Bot1", full_name: "Bot1"),
            FetchPlayerResponse(name: "Bot1", full_name: "Bot1"),
            FetchPlayerResponse(name: "Bot1", full_name: "Bot1"),
            FetchPlayerResponse(name: "Bot1", full_name: "Bot1"),
            FetchPlayerResponse(name: "Bot1", full_name: "Bot1")]
        )
        players[0].isUser = false
        
        manager.pot = 0
        manager.lastPlayerBet = 0
        manager.round = 0
    }
    
    override func tearDown() async throws {
        manager = nil
    }
    
    func testStartGame() async {
        await manager.startGame()
    }

    // MARK: - Raise & Call Logic
    
    func testRaiseAddsToPotAndReducesStack() {
        let player1 = players[0]
        manager.raise(aiPlayer: player1, amount: 20)
        
        XCTAssertEqual(manager.pot, 20, "Pot should increase by raised amount")
        XCTAssertEqual(player1.stack, 80, "Player stack should decrease by raised amount")
        XCTAssertEqual(manager.lastPlayerBet, 20, "Last player bet should update")
        XCTAssertEqual(player1.lastMove(game: 0), .raise)
    }
    
    func testRaiseCannotExceedStack() {
        let player1 = players[0]
        player1.stack = 10
        manager.raise(aiPlayer: player1, amount: 50)
        
        XCTAssertEqual(manager.pot, 10, "Pot should not exceed player stack")
        XCTAssertEqual(player1.stack, 0, "Player should go all-in")
        XCTAssertEqual(manager.lastPlayerBet, 10)
    }
    
    func testCallAddsToPotAndReducesStack() {
        let player2 = players[1]
        manager.lastPlayerBet = 10
        manager.call(aiPlayer: player2)
        
        XCTAssertEqual(manager.pot, 10, "Pot should increase by called amount")
        XCTAssertEqual(player2.stack, 90)
        XCTAssertEqual(player2.lastMove(game: 0, ), .call)
    }
    
    func testCallAfterRaise() {
        let player2 = players[1]
        manager.lastPlayerBet = 10
        manager.raise(aiPlayer: players[0], amount: 10)
        manager.call(aiPlayer: player2)
        
        XCTAssertEqual(manager.pot, 20, "Pot should increase by called amount")
        XCTAssertEqual(player2.stack, 90)
        XCTAssertEqual(player2.lastMove(game: 0, ), .call)
    }
    
    func testCallCannotExceedStack() {
        let player2 = players[1]
        player2.stack = 5
        manager.raise(aiPlayer: players[0], amount: 10)
        manager.call(aiPlayer: player2)
        
        XCTAssertEqual(manager.pot, 15, "Should only call up to available stack")
        XCTAssertEqual(player2.stack, 0)
    }

    // MARK: - User and AI Decision Logic
    func testGetUserDecisionResumesWithMove() async {
        let expectation = XCTestExpectation(description: "Waits for continuation")
        
        Task {
            let result = await self.manager.getUserDecision()
            XCTAssertEqual(result.0, "call")
            XCTAssertEqual(result.1, 5)
            expectation.fulfill()
        }
        
        // Simulate UI calling back with user move
        try? await Task.sleep(nanoseconds: 200_000_000)
        manager.handleUserMove(move: ("call", 5))
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Utility and Player Checks
    
    
    func testGetUserDefaultBets() {
        let user = AIPlayer(name: "HERO", fullName: "test", position: "BTN", stack: 15, isUser: true)
        manager.aiPlayers = [user]
        manager.lastPlayerBet = 5
        
        let bets = manager.getUserDefaultBets()
        XCTAssertTrue(bets.allSatisfy { $0 <= 15 })
        XCTAssertFalse(bets.isEmpty)
    }

    // MARK: - Player Creation
    
    func testCreateAndReorderPlayers() {
        let reordered = manager.createAndReorderPlayers(playerPosition: "BTN")
        XCTAssertEqual(reordered.count, Int(manager.tableSize))
        XCTAssertEqual(reordered.first?.position, "BTN")
    }
}
