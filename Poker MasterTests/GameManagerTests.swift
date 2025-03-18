//
//  GameManagerTests.swift
//  Poker MasterTests
//
//  Created by Ned Whittleton on 4/21/24.
//

import XCTest

@testable import Poker_Master

//class MockDecisionMaker: DecisionMakerProtocol {
//    var forcedMove: String = "call" // Default behavior for testing
//
//    func determineMovePreFlop(hero: Player, villian: Player?, betNumber: Int) -> String {
//        return forcedMove
//    }
//}

final class GameManagerTests: XCTestCase {
    let gameManager = GameManager()
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGameManagerInitialization() {
            let gameManager = GameManager()
            
            XCTAssertEqual(gameManager.players.count, 6) // Assuming createRandomPlayers() generates 6 players
            XCTAssertNotNil(gameManager.user)
            XCTAssertEqual(gameManager.players.first?.position, gameManager.user?.position)
            XCTAssertGreaterThanOrEqual(gameManager.pot, 3.0) // SB + BB
            
            // Ensure SB and BB have correct starting bet
            let smallBlind = gameManager.players.first(where: { $0.position == "SB" })
            let bigBlind = gameManager.players.first(where: { $0.position == "BB" })
            
            XCTAssertEqual(smallBlind?.betAmount, 1.0)
            XCTAssertEqual(bigBlind?.betAmount, 2.0)
    }
    
    func testPlayerRaiseDuringGameLoop() async {
            let gameManager = GameManager()
            
            // Mock decision-making to force a raise
            gameManager.decisionMaker.determineMovePreFlop = { _, _, _ in
                return "raise"
            }
            
            let initialPot = gameManager.pot
            let initialStack = gameManager.players[0].stack

            await gameManager.executeLoop()
            
            // Ensure a raise occurred
            XCTAssertEqual(gameManager.players[0].lastMove, LastMove.raise)
            XCTAssertGreaterThan(gameManager.pot, initialPot)
            XCTAssertLessThan(gameManager.players[0].stack, initialStack)
        }
    
    func testGameManager() throws {
        for player in gameManager.players {
            print(player.toString())
        }
    }
    
    func testStartGame() async throws {
        let gameMangerT = GameManager()
        await gameMangerT.startGame()
    }
    
    func testReorderPlayers() throws {
        // ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        var players = gameManager.reorderPlayers(playerPosition: "BB")
        var expectedOrder = ["BB", "UTG", "MP", "CO", "BTN", "SB"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.reorderPlayers(playerPosition: "UTG")
        expectedOrder = ["UTG", "MP", "CO", "BTN", "SB", "BB"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.reorderPlayers(playerPosition: "MP")
        expectedOrder = ["MP", "CO", "BTN", "SB", "BB", "UTG"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.reorderPlayers(playerPosition: "CO")
        expectedOrder = ["CO", "BTN", "SB", "BB", "UTG", "MP"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.reorderPlayers(playerPosition: "BTN")
        expectedOrder = ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.reorderPlayers(playerPosition: "SB")
        expectedOrder = ["SB", "BB", "UTG", "MP", "CO", "BTN"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
