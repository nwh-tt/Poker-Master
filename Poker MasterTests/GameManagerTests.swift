//
//  GameManagerTests.swift
//  Poker MasterTests
//
//  Created by Ned Whittleton on 4/21/24.
//

import XCTest

@testable import Poker_Master

//class MockDecisionMaker: DecisionMakerProtocol {
//    var forcedMove: String = "call"  // Default behavior
//
//    func determineMovePreFlop(hero: Player, villian: Player?, betNumber: Int) -> String {
//        return forcedMove  // Return whatever move we want for testing
//    }
//}

class MockDecisionMaker: DecisionMaker {
    var moveSequence: [LastMove] = []
    private var moveIndex = 0
    
    override func determineMovePreFlop(hero: Player, villian: Player?, betNumber: Int) -> LastMove {
        guard moveIndex < moveSequence.count else { return .fold }
        let move = moveSequence[moveIndex]
        moveIndex += 1
        return move
    }
}

final class GameManagerTests: XCTestCase {
    var gameManager: GameManager!
    var mockDecisionMaker: MockDecisionMaker!

    override func setUp() {
        super.setUp()
        mockDecisionMaker = MockDecisionMaker()
        gameManager = GameManager(decisionMaker: mockDecisionMaker, gameplaySpeed: 5, testingMode: true)
    }

    override func tearDown() {
        gameManager = nil
        mockDecisionMaker = nil
        super.tearDown()
    }
    
    func testGameManagerInitialization() {
            
            XCTAssertEqual(gameManager.players.count, 6) // Assuming createRandomPlayers() generates 6 players
            XCTAssertNotNil(gameManager.user)
            XCTAssertEqual(gameManager.players.first?.position, gameManager.user?.position)
            XCTAssertGreaterThanOrEqual(gameManager.pot, 3.0) // SB + BB
            
            // Ensure SB and BB have correct starting bet
            let smallBlind = gameManager.players.first(where: { $0.position == "SB" })
            let bigBlind = gameManager.players.first(where: { $0.position == "BB" })
            
            XCTAssertEqual(smallBlind?.currentBetAmount, 1.0)
            XCTAssertEqual(bigBlind?.currentBetAmount, 2.0)
    }
    
    func testStartGame_Single() async {
            
        // Run the game
        await gameManager.startGame()
            
        // Ensure either one player remains unfolded OR only one raise occurred
        let remainingPlayers = gameManager.players.filter { $0.lastMove != .fold }.count
        let raiseCount = gameManager.players.filter { $0.lastMove == .raise }.count
        print(remainingPlayers, raiseCount)
        XCTAssert(remainingPlayers == 1 || raiseCount == 1,
                          "Either only one player should remain, or only one raise should have occurred, but not necessarily both.")
                
        // Calculate total missing stack (total chips bet)
        let totalChipsLost = gameManager.players.reduce(0.0) { sum, player in
            return sum + (100 - player.stack)
        }
            
        // Pot should match total chips lost
        XCTAssertEqual(totalChipsLost, gameManager.pot, accuracy: 0.01, "The total chips bet should be equal to the pot")
    }
    
    func testStartGame_Many() async {
        for _ in 1...5 {  // Run multiple times for consistency
            let gameManager = GameManager(gameplaySpeed: 5, testingMode: true)
                
            // Run the game
            await gameManager.startGame()
                
            // Ensure either one player remains unfolded OR only one raise occurred
            let remainingPlayers = gameManager.players.filter { $0.lastMove != .fold }.count
            let raiseCount = gameManager.players.filter { $0.lastMove == .raise }.count
                    
            XCTAssert(remainingPlayers == 1 || raiseCount == 1,
                              "Either only one player should remain, or only one raise should have occurred, but not necessarily both.")
                    
            // Calculate total missing stack (total chips bet)
            let totalChipsLost = gameManager.players.reduce(0.0) { sum, player in
                return sum + (100 - player.stack)
            }
                
            // Pot should match total chips lost
            XCTAssertEqual(totalChipsLost, gameManager.pot, accuracy: 0.01, "The total chips bet should be equal to the pot")
                }
        }
    
    func testResetAndStartNewGameDealsNewCards() {
            
        // Act: Call the reset function
        gameManager.resetAndStartNewGame()
            
        // Assert: Each player has two new cards dealt
        for player in gameManager.players {
            XCTAssertEqual(player.hand.count, 2)
        }
    }
    
    func testResetAndStartNewGameResetsGameVariables() {
            // Arrange: Set some game-related variables before resetting
            gameManager.pot = 10
            gameManager.turn = 2
            gameManager.betNumber = 5
            gameManager.lastRaise = 2.0
            gameManager.villain = gameManager.players[1]
            for player in gameManager.players {
                player.stack = 50 // Temporarily setting stack to a different value
            }
            
            // Act: Call the reset function
            gameManager.resetAndStartNewGame()
            
            // Assert: Game-related variables are reset
            XCTAssertEqual(gameManager.pot, 3)
            XCTAssertEqual(gameManager.turn, gameManager.players.firstIndex(where: { $0.position == "UTG" }) ?? 0)
            XCTAssertEqual(gameManager.betNumber, 1)
            XCTAssertEqual(gameManager.lastRaise, 0.0)
            XCTAssertNil(gameManager.villain)
            XCTAssertFalse(gameManager.waitingForUserInput)
            XCTAssertFalse(gameManager.showIncorrectPopup)
            XCTAssertEqual(gameManager.adviceText, "")
            for player in gameManager.players {
                if player.position == "BB" {
                    XCTAssertEqual(player.stack, 98, "BB's stack should be reset to 98")
                }
                else if player.position == "SB" {
                    XCTAssertEqual(player.stack, 99, "BB's stack should be reset to 99")
                }
                else {
                    XCTAssertEqual(player.stack, 100, "Player's stack should be reset to 100")
                }
            }
        }
    
    @MainActor
    func testExecuteLoop_BB_Calls() async {
        // Make all but one player fold
        mockDecisionMaker.moveSequence = [.fold, .raise, .fold, .fold, .fold, .call]

        let expectation = XCTestExpectation(description: "Execute loop should finish when one player remains")

        Task {
            await gameManager.executeLoop()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 10.0)

        // Only one player should be left
        let activePlayers = gameManager.players.filter { $0.lastMove != .fold }
    }
    
    @MainActor
    func testExecuteLoop_AllFold_OnePlayerRemains() async {
        // Make all but one player fold
        mockDecisionMaker.moveSequence = [.fold, .fold, .fold, .fold, .fold]

        let expectation = XCTestExpectation(description: "Execute loop should finish when one player remains")

        Task {
            await gameManager.executeLoop()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 10.0)

        // Only one player should be left
        let activePlayers = gameManager.players.filter { $0.lastMove != .fold }
        XCTAssertEqual(activePlayers.count, 1, "Only one player should remain after all others fold")
    }
    
    @MainActor
    func testExecuteLoop_AllCall_BettingEnds() async {

        // All players call the last raise
        mockDecisionMaker.moveSequence = [.raise, .call, .call, .call, .call, .call]

        let expectation = XCTestExpectation(description: "Execute loop should finish when betting is complete")

        Task {
            await gameManager.executeLoop()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 10.0)

        // Ensure all players matched the last raise
        for player in gameManager.players {
            XCTAssertEqual(player.currentBetAmount, 10.0, "All players should have matched the last raise")
        }
    }
    
    @MainActor
    func testExecuteLoop_RaisesOccur() async {

        // Players raise in turns
        mockDecisionMaker.moveSequence = [.raise, .raise, .raise, .call, .call]

        let expectation = XCTestExpectation(description: "Execute loop should finish with players raising and calling")

        Task {
            await gameManager.executeLoop()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        // Check if last raise is updated
        XCTAssertEqual(gameManager.lastRaise, 30, "There should be a valid lastRaise amount")
    }
    
    @MainActor
    func testExecuteLoop_CorrectPotCalculation() async {

        // Players make different moves
        mockDecisionMaker.moveSequence = [.raise, .call, .fold, .call, .call]

        let expectation = XCTestExpectation(description: "Execute loop should finish and calculate pot size correctly")

        Task {
            await gameManager.executeLoop()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        // If bb and sb call than the pot will be 40 but could be 41, 42, 43 if they fold
        XCTAssertGreaterThan(gameManager.pot, 39, "Pot should increase after betting")
    }
    
    func testWaitForUserInput() async {
        gameManager.testingMode = false
        let expectedMove: LastMove = .call
        let expectation = expectation(description: "User input should be received")
        
        print(gameManager.testingMode)
        
        Task {
            let result = await gameManager.waitForUserInput()
            XCTAssertEqual(result, expectedMove, "User move should match expected input")
            expectation.fulfill()
        }

        // Simulate user input after a short delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            Task { @MainActor in
                    self.gameManager.userMadeMove(decision: expectedMove)
            }
        }
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testReorderPlayers() throws {
        // ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        var players = gameManager.createAndReorderPlayers(playerPosition: "BB")
        var expectedOrder = ["BB", "UTG", "MP", "CO", "BTN", "SB"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.createAndReorderPlayers(playerPosition: "UTG")
        expectedOrder = ["UTG", "MP", "CO", "BTN", "SB", "BB"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.createAndReorderPlayers(playerPosition: "MP")
        expectedOrder = ["MP", "CO", "BTN", "SB", "BB", "UTG"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.createAndReorderPlayers(playerPosition: "CO")
        expectedOrder = ["CO", "BTN", "SB", "BB", "UTG", "MP"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.createAndReorderPlayers(playerPosition: "BTN")
        expectedOrder = ["BTN", "SB", "BB", "UTG", "MP", "CO"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
        
        players = gameManager.createAndReorderPlayers(playerPosition: "SB")
        expectedOrder = ["SB", "BB", "UTG", "MP", "CO", "BTN"]
        
        for i in 0..<players.count {
            XCTAssertEqual(players[i].position, expectedOrder[i])
        }
    }
}
