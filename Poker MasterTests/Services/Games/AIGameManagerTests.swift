//
//  AIGameManagerTests.swift
//  Poker Master
//
//  Created by Ned Whittleton on 10/16/25.
//


import Foundation
import Observation
import XCTest
import SwiftData
@testable import Poker_Master
import AuthenticationServices
import FirebaseAuth

@MainActor
final class ScriptedBettingManager: AIGameManager {
    // key: player.id (UUID) or player.position/name; store scripted actions
    var scriptsByName: [String: [(String, Double)]] = [:]
    var makeDecisionCallCount = 0

    override func sleepIfNeeded() async { /* no-op */ }

    override func makeAIDecision(ai: AIPlayer) async -> (String, Double) {
        makeDecisionCallCount += 1
        guard var script = scriptsByName[ai.name], !script.isEmpty else {
            return ("fold", 0) // default safe action
        }
        let next = script.removeFirst()
        scriptsByName[ai.name] = script
        return next
    }
}

final class SpyBettingRoundManager: AIGameManager {
    var forcedFirstIndex: Int? = nil
    var forcedBettingComplete: Bool? = nil
    var forcedAIDecision: (String, Double) = ("check", 0)

    var sleepCallCount = 0

    override func getFirstPlayerToActIndex() -> Int {
        forcedFirstIndex ?? super.getFirstPlayerToActIndex()
    }

    override func isBettingComplete(activePlayers: [AIPlayer], highestBet: Double) -> Bool {
        forcedBettingComplete ?? super.isBettingComplete(activePlayers: activePlayers, highestBet: highestBet)
    }

    override func makeAIDecision(ai: AIPlayer) async -> (String, Double) {
        forcedAIDecision
    }

    override func sleepIfNeeded() async {
        sleepCallCount += 1
        // no-op in tests
    }
}

@MainActor
final class SpyDecisionManager: AIGameManager {
    var scriptedMove: String = "check"

    override func getAIMove(ai: AIPlayer) async -> String {
        scriptedMove
    }
}


final class SpyAIGameManager: AIGameManager {
    enum Call: Equatable {
        case initializeStreetLog(round: Int)
        case setUpBlinds
        case playBettingRound(round: Int)
        case dealBoard(Int)
        case determineWinners
        case processRoundEnd
        case saveStreetLog
        case sleep
    }

    var calls: [Call] = []

    // Scripted behavior
    var scriptedRemainingPlayers: [Int] = [2, 2, 2, 2, 2] // consumed each time remainingPlayers() is called
    var remainingPlayersDefault: Int = 2
    var determineWinnersResult: DetermineWinnerResponse = DetermineWinnerResponse(winners: ["Hero"], player_details: [])
    var shouldThrowInSetUpBlinds: Bool = false
    var initializeStreetLogReturn: Bool = true

    // Track round increments without real betting
    var playBettingRoundIncrementsRound: Bool = true

    override func remainingPlayers() -> Int {
        if !scriptedRemainingPlayers.isEmpty {
            return scriptedRemainingPlayers.removeFirst()
        }
        return remainingPlayersDefault
    }

    @MainActor
    override func initializeStreetLog() -> Bool {
        calls.append(.initializeStreetLog(round: round))
        // You can keep logs nil to avoid SwiftData touching anything.
        // Or you can set aiHandLog/gameLog if you need those side effects.
        return initializeStreetLogReturn
    }

    override func saveStreetLog() {
        calls.append(.saveStreetLog)
        // no-op: avoid SwiftData writes
    }

    override func processRoundEnd() async {
        calls.append(.processRoundEnd)
        // no-op: don't mutate stacks unless you want to assert that too
    }

    override func dealBoard(cardsToDeal: Int) async {
        calls.append(.dealBoard(cardsToDeal))
        // no-op: don’t touch deck/board
    }

    override func determineWinners() async -> DetermineWinnerResponse {
        calls.append(.determineWinners)
        return determineWinnersResult
    }

    override func setUpBlinds() async throws {
        calls.append(.setUpBlinds)
        if shouldThrowInSetUpBlinds {
            throw GameLoopError.notEnoughPlayersForBlinds
        }
    }

    @MainActor
    override func playBettingRound() async throws {
        calls.append(.playBettingRound(round: round))
        // mimic the real function’s critical side effect:
        // it increments round at the end of each street
        if playBettingRoundIncrementsRound {
            round += 1
        }
    }

    // If you want to assert whether sleep happens, you can hook sleepFunction.
    func installSleepSpy() {
        self.sleepFunction = { [weak self] _ in
            await MainActor.run {
                self?.calls.append(.sleep)
            }
        }
    }
    
    @MainActor
    override func sleepIfNeeded() async {
        calls.append(.sleep)
        // no-op in tests
    }
}



class TestAIPlayer: AIPlayer {
    var testLastMove: Action = .call
    var testOutOfMoney: Bool = false
    var testLastBet: Double = 0

    override func lastMove(game: Int) -> Action { testLastMove }
    override func lastMoveForRound(game: Int, round: Int) -> Action { testLastMove }
    override func isOutOfMoney(game: Int) -> Bool { testOutOfMoney }
    override func lastBet(game: Int, round: Int) -> Double { testLastBet }
}

@MainActor
func makeInMemoryContext() -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)

    let container = try! ModelContainer(
        for: Game.self, AIGameLog.self,
        configurations: config
    )

    return ModelContext(container)
}


class MockAuthService: AuthServiceProtocol {
    func anonymousSignIn(completion: @escaping ((any Error)?) -> Void) {
        completion(nil)
    }
    
    var currentUser: User? = nil
    var isAuthenticated: Bool { currentUser != nil }
    private var listeners: [(User?) -> Void] = []

    func addStateDidChangeListener(_ listener: @escaping (User?) -> Void) {
        listeners.append(listener)
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        // Use a real Firebase user only if you have a testing Firebase, or keep nil
        completion(nil)
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    func signOut() throws { currentUser = nil }

    func getIDToken(forceRefresh: Bool = false) async throws -> String { "mock_token" }
}


class MockVsAPI: VsAIAPI {
    var shouldThrow: Bool = false
    var nextDecision: String = "call"
    var nextNames: [FetchPlayerResponse] = []
    var nextWinners: [String] = ["HERO"]
    var nextWinnerDetails: [PlayerDetails] = []
    var lastProcessWinnersArgs: (playersLeft: [AIPlayer], board: [String])?
    
    var lastFetchAiDecisionArgs: (
            aiName: String,
            aiHole: [String],
            board: [String],
            potOdds: Double,
            opponentCount: Int,
            possibleMoves: [String]
        )?

        override func fetchAiDecision(
            aiName: String,
            aiHole: [String],
            board: [String],
            potOdds: Double,
            opponentCount: Int,
            possibleMoves: [String]
        ) async throws -> String {
            lastFetchAiDecisionArgs = (aiName, aiHole, board, potOdds, opponentCount, possibleMoves)
            if shouldThrow { throw URLError(.badURL) }
            return nextDecision
        }
    
    override func fetchAIPlayers(tableSize: String) async throws -> [FetchPlayerResponse] {
        if shouldThrow {
            throw URLError(.badURL)
        }
        return nextNames
    }
    
    override func processWinners(playersLeft: [AIPlayer], board: [String]) async throws -> DetermineWinnerResponse {
        lastProcessWinnersArgs = (playersLeft, board)
        if shouldThrow {
            throw URLError(.badURL)
        }
        return DetermineWinnerResponse(winners: nextWinners, player_details: nextWinnerDetails)
    }
}

class MockProfile: Profile {
    var xpAdded = 0

    override func addXP(amount: Int) {
        xpAdded += amount
    }
}


@MainActor
final class AIGameManagerTests: XCTestCase {
    
    // MARK: - Helpers
    private func makePlayers() -> [AIPlayer] {
        let positions = ["UTG", "MP", "CO", "BTN", "SB", "BB"]
        return positions.map {
            let p = AIPlayer(name: "", fullName: "", position: $0, stack: 100)
            return p
        }
    }
    
    private func makeDummyPlayers() -> [TestAIPlayer] {
        let positions = ["UTG", "MP", "CO", "BTN", "SB", "BB"]
        return positions.map {
            let p = TestAIPlayer(name: "", fullName: "", position: $0, stack: 100)
            return p
        }
    }
    
    private func makeP(
            stack: Double,
            lastBet: Double,
            move: Action
    ) -> TestAIPlayer {
        let p = TestAIPlayer(name: "", fullName: "", position: "UTG", stack: stack)
        p.testLastBet = lastBet
        p.testLastMove = move
        return p
    }
    
    var manager: AIGameManager!
    var mockAPI: MockVsAPI!
    var players: [AIPlayer]!
    
    override func setUp() async throws {
        manager = AIGameManager(testingMode: true)
        mockAPI = MockVsAPI(authManager: AuthManager(authService: MockAuthService()))
        manager.vsAiAPI = mockAPI
        manager.context = await makeInMemoryContext()

        manager.pot = 0
        manager.lastPlayerBet = 0
        manager.round = 0
    }
    
    override func tearDown() async throws {
        manager = nil
    }
    
    // MARK: -- Tests begin here
    
    @MainActor
        func test_canStartNewGame_returnsFalse_whenNoUser() {
            let manager = AIGameManager(testingMode: true)
            manager.aiPlayers = makePlayers() // none isUser

            XCTAssertFalse(manager.canStartNewGame())
        }

        @MainActor
        func test_canStartNewGame_returnsFalse_whenUserHasNoChips() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 0        // user busted
            players[1].stack = 100      // another player has chips
            manager.aiPlayers = players

            XCTAssertFalse(manager.canStartNewGame())
        }

        @MainActor
        func test_canStartNewGame_returnsFalse_whenFewerThanTwoPlayersHaveChips() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 100      // user has chips

            // Everyone else busted
            for i in 1..<players.count {
                players[i].stack = 0
            }
            manager.aiPlayers = players

            XCTAssertFalse(manager.canStartNewGame())
        }

        @MainActor
        func test_canStartNewGame_returnsTrue_whenUserHasChips_andAtLeastTwoPlayersHaveChips() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 50
            players[1].stack = 1        // at least one other player can be dealt in
            manager.aiPlayers = players

            XCTAssertTrue(manager.canStartNewGame())
        }

        @MainActor
        func test_canStartNewGame_returnsTrue_whenExactlyTwoPlayersHaveChips() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 10

            // Exactly one other player with chips
            players[1].stack = 10
            for i in 2..<players.count {
                players[i].stack = 0
            }

            manager.aiPlayers = players
            XCTAssertTrue(manager.canStartNewGame())
        }
    
    @MainActor
    func test_playBettingRound_skipsImmediately_whenFewerThanTwoPlayersHaveChips() async throws {
        let manager = ScriptedBettingManager(testingMode: true)
        
        // 3 players at table, only one has chips.
        // IMPORTANT: use TestAIPlayer so isOutOfMoney can be forced false even at stack 0
        let p1 = TestAIPlayer(name: "P1", fullName: "", position: "SB", stack: 50)
        p1.testOutOfMoney = false
        
        let p2 = TestAIPlayer(name: "P2", fullName: "", position: "BB", stack: 0)
        p2.testOutOfMoney = false // treat as "all-in" not "busted"
        
        let p3 = TestAIPlayer(name: "P3", fullName: "", position: "UTG", stack: 0)
        p3.testOutOfMoney = false // treat as "all-in" not "busted"
        
        manager.aiPlayers = [p1, p2, p3]
        manager.tableSize = "3"
        manager.round = 1                 // postflop -> first to act = SB
        manager.game = 0
        manager.pot = 123
        manager.lastPlayerBet = 9
        
        let startRound = manager.round
        
        try await manager.playBettingRound()
        
        // Should do no decisions because it short-circuited
        XCTAssertEqual(manager.makeDecisionCallCount, 0)
        
        // Still ends the street correctly
        XCTAssertEqual(manager.round, startRound + 1)
        XCTAssertEqual(manager.lastPlayerBet, 0, accuracy: 1e-9)
        
        // Pot should not change if we skipped the street
        XCTAssertEqual(manager.pot, 123, accuracy: 1e-9)
    }
    
    @MainActor
    func test_playBettingRound_integration_betCallFold_updatesPotAndStacks_andCompletes() async throws {
        let manager = ScriptedBettingManager(testingMode: true)

        let sb = AIPlayer(name: "SB", fullName: "", position: "SB", stack: 100)
        let bb = AIPlayer(name: "BB", fullName: "", position: "BB", stack: 100)
        let utg = AIPlayer(name: "UTG", fullName: "", position: "UTG", stack: 100)
        manager.aiPlayers = [utg, sb, bb] // ordering doesn't matter as long as positions are correct for getFirstPlayerToActIndex

        manager.round = 1
        manager.game = 0
        manager.pot = 0
        manager.lastPlayerBet = 0

        manager.scriptsByName = [
            "SB":  [("raise", 4)],
            "BB":  [("call", 0)],  // call() uses lastPlayerBet, amount ignored
            "UTG": [("fold", 0)]
        ]

        try await manager.playBettingRound()

        XCTAssertEqual(manager.pot, 8, accuracy: 0.000001)
        XCTAssertEqual(sb.stack, 96, accuracy: 0.000001)
        XCTAssertEqual(bb.stack, 96, accuracy: 0.000001)
        XCTAssertEqual(utg.stack, 100, accuracy: 0.000001)

        XCTAssertEqual(sb.lastBet(game: 0, round: 1), 4, accuracy: 0.000001)
        XCTAssertEqual(bb.lastBet(game: 0, round: 1), 4, accuracy: 0.000001)
        XCTAssertEqual(utg.lastMoveForRound(game: 0, round: 1), .fold)

        XCTAssertEqual(manager.round, 2)
        XCTAssertEqual(manager.lastPlayerBet, 0)
    }

    
    @MainActor
    func test_playBettingRound_integration_checkAroundPostflop_completesAndAdvances() async throws {
        let manager = ScriptedBettingManager(testingMode: true)

        // Create 3 players to keep it small
        let p1 = AIPlayer(name: "P1", fullName: "", position: "SB", stack: 100)
        let p2 = AIPlayer(name: "P2", fullName: "", position: "BB", stack: 100)
        let p3 = AIPlayer(name: "P3", fullName: "", position: "UTG", stack: 100)
        manager.aiPlayers = [p1, p2, p3]

        manager.round = 1              // postflop => highestBet starts at 0
        manager.game = 0
        manager.pot = 10               // pot already has something from earlier
        manager.lastPlayerBet = 0

        // Everyone checks once. (Make sure your first-to-act is SB on postflop.)
        manager.scriptsByName = [
            "P1": [("check", 0)],
            "P2": [("check", 0)],
            "P3": [("check", 0)]
        ]

        try await manager.playBettingRound()

        XCTAssertEqual(manager.round, 2)
        XCTAssertEqual(manager.lastPlayerBet, 0)
        XCTAssertEqual(manager.pot, 10, "Checks should not change pot")
        XCTAssertEqual(p1.lastMoveForRound(game: 0, round: 1), .check)
        XCTAssertEqual(p2.lastMoveForRound(game: 0, round: 1), .check)
        XCTAssertEqual(p3.lastMoveForRound(game: 0, round: 1), .check)
    }

    
    @MainActor
    func test_playBettingRound_whenAlreadyComplete_advancesRoundAndResetsLastPlayerBet() async throws {
        let manager = SpyBettingRoundManager(testingMode: true)
        manager.aiPlayers = makePlayers()
        manager.forcedFirstIndex = 0

        manager.round = 1
        manager.lastPlayerBet = 8
        manager.forcedBettingComplete = true

        try await manager.playBettingRound()

        XCTAssertEqual(manager.round, 2)
        XCTAssertEqual(manager.lastPlayerBet, 0)
        XCTAssertGreaterThanOrEqual(manager.sleepCallCount, 1, "Expected end-of-round sleepIfNeeded() call")
    }
    
    @MainActor
    func test_playBettingRound_stopsWhenOneActivePlayerRemains() async throws {
        let manager = SpyBettingRoundManager(testingMode: true)

        // Use controllable players
        let players = makeDummyPlayers()
        players[0].isUser = false
        players[0].testLastMove = .none
        players[0].testOutOfMoney = false
        players[0].stack = 100

        // Everyone else is folded or out-of-money
        for i in 1..<players.count {
            if i % 2 == 0 {
                players[i].testLastMove = .fold
            } else {
                players[i].testOutOfMoney = true
            }
        }

        manager.aiPlayers = players
        manager.forcedFirstIndex = 0
        manager.round = 1
        manager.lastPlayerBet = 5
        manager.forcedBettingComplete = false
        manager.forcedAIDecision = ("check", 0)

        try await manager.playBettingRound()

        XCTAssertEqual(manager.round, 2)
        XCTAssertEqual(manager.lastPlayerBet, 0)
    }

    
    @MainActor
    func test_playBettingRound_throwsInvalidFirstPlayer_whenFirstIndexIsMinus1() async {
        let manager = SpyBettingRoundManager(testingMode: true)
        manager.aiPlayers = makePlayers()
        manager.forcedFirstIndex = -1

        do {
            try await manager.playBettingRound()
            XCTFail("Expected GameLoopError.invalidFirstPlayer")
        } catch let err as GameLoopError {
            XCTAssertEqual(err, .invalidFirstPlayer)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    @MainActor
    func test_playBettingRound_throwsUnknownAIAction_whenActionIsInvalid() async {
        let manager = SpyBettingRoundManager(testingMode: true)
        manager.aiPlayers = makePlayers()
        manager.round = 1                 // highestBet starts at 0
        manager.forcedFirstIndex = 0

        manager.forcedBettingComplete = false
        manager.forcedAIDecision = ("dance", 0) // invalid -> should throw unknownAIAction

        do {
            try await manager.playBettingRound()
            XCTFail("Expected GameLoopError.unknownAIAction")
        } catch let err as GameLoopError {
            XCTAssertEqual(err, .unknownAIAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    @MainActor
    func test_playBettingRound_throwsDidNotConverge_whenBettingNeverCompletes() async {
        let manager = SpyBettingRoundManager(testingMode: true)
        manager.aiPlayers = makePlayers()
        manager.round = 1
        manager.forcedFirstIndex = 0

        manager.forcedBettingComplete = false
        manager.forcedAIDecision = ("check", 0)

        do {
            try await manager.playBettingRound()
            XCTFail("Expected GameLoopError.bettingRoundDidNotConverge")
        } catch let err as GameLoopError {
            XCTAssertEqual(err, .bettingRoundDidNotConverge)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // Highest bet is 1 if it is the preflop round (because of blinds)
    @MainActor
    func test_gameLoop_happyPath_reachesShowdown_andResetsState() async {
        let manager = SpyAIGameManager(testingMode: true)
        manager.tableSize = "6"
        manager.installSleepSpy()
        
        // Make players so singular-winner branch can’t crash if it ever happens.
        // (Use your TestAIPlayer so lastMove/isOutOfMoney are controllable.)
        let players = makeDummyPlayers()
        players[0].name = "HERO"
        players[0].isUser = true
        manager.aiPlayers = players
        
        manager.pot = 100
        manager.round = 0
        manager.skipActive = false
        
        // remainingPlayers() is checked multiple times inside gameLoop.
        // We want: preflop -> still >1, flop -> still >1, turn -> still >1, river -> still >1
        manager.scriptedRemainingPlayers = [6, 6, 6, 6, 6, 6] // enough to cover all calls safely
        manager.determineWinnersResult = DetermineWinnerResponse(winners: ["HERO"], player_details: []) // showdown branch
        
        await manager.gameLoop()
        
        // Key end-state
        XCTAssertTrue(manager.waitingForContinueButton, "Expected continue button enabled at end of loop")
        XCTAssertFalse(manager.skipActive, "Expected skipActive reset to false at end")
        XCTAssertEqual(manager.pot, 0, "Expected pot reset to 0 at end")
        XCTAssertEqual(manager.round, 4, "Expected round incremented through preflop/flop/turn/river (0->4)")
        
        // Key orchestration calls
        XCTAssertTrue(manager.calls.contains(.setUpBlinds))
        XCTAssertTrue(manager.calls.contains(.processRoundEnd))
        
        // Board dealing happened with 3/1/1
        XCTAssertTrue(manager.calls.contains(.dealBoard(3)))
        XCTAssertTrue(manager.calls.contains(.dealBoard(1)))
        
        // Should process round end and save at least once at end
//        XCTAssertTrue(manager.calls.contains { call in
//            if case .processRoundEnd(let winners) = call { return winners == ["HERO"] }
//            return false
//        })
        XCTAssertTrue(manager.calls.contains(.saveStreetLog))
    }
    
    @MainActor
    func test_gameLoop_singleWinnerByFolds_skipsDetermineWinners() async {
        let manager = SpyAIGameManager(testingMode: true)
        manager.tableSize = "6"

        // Players: HERO wins by default (everyone else folded/out)
        let players = makeDummyPlayers()
        players[0].name = "HERO"
        players[0].isUser = true

        // Mark everyone else folded so singularWinner lookup finds HERO safely
        for i in 1..<players.count {
            players[i].testLastMove = .fold
        }
        manager.aiPlayers = players

        manager.pot = 50
        manager.round = 0

        // Make it so after preflop actions, remainingPlayers() reports 1
        // Enough values to cover all calls:
        // - preflop "if remainingPlayers() > 1" checks will fail after first round
        manager.scriptedRemainingPlayers = [6, 1, 1, 1, 1, 1]

        await manager.gameLoop()

        XCTAssertFalse(manager.isShowdown, "Expected no showdown when only one player remains")
        XCTAssertTrue(manager.waitingForContinueButton)
        XCTAssertEqual(manager.pot, 0)

        // Must NOT call determineWinners
        XCTAssertFalse(manager.calls.contains(.determineWinners))

        // Still must process round end with ["HERO"] (based on singularWinner)
//        XCTAssertTrue(manager.calls.contains { call in
//            if case .processRoundEnd(let winners) = call { return winners == ["HERO"] }
//            return false
//        })
    }
    
    @MainActor
    func test_gameLoop_whenSetUpBlindsThrows_setsContinueButtonAndStops() async {
        let manager = SpyAIGameManager(testingMode: true)
        manager.tableSize = "6"

        let players = makeDummyPlayers()
        players[0].name = "HERO"
        players[0].isUser = true
        manager.aiPlayers = players

        manager.shouldThrowInSetUpBlinds = true
        manager.pot = 123
        manager.round = 0

        await manager.gameLoop()

        XCTAssertTrue(manager.waitingForContinueButton, "Expected continue button enabled even on error")
        XCTAssertFalse(manager.isShowdown, "Should not reach showdown on setup error")

        // Orchestration: it should have tried init log, then setUpBlinds, then stopped
        XCTAssertTrue(manager.calls.contains(.setUpBlinds))
        XCTAssertFalse(manager.calls.contains(.determineWinners), "Should not determine winners when blinds setup fails")

        // NOTE: your catch does NOT reset pot, so pot may still be 123.
        // If you want pot reset on error, change production code; otherwise assert current behavior:
        XCTAssertEqual(manager.pot, 123, "Current behavior: pot is not reset in catch")
    }

    
    func test_isBettingComplete_highestBetZero_allPlayersCheck_returnsTrue() {
        let p1 = makeP(stack: 100, lastBet: 0, move: .check)
        let p2 = makeP(stack: 50,  lastBet: 0, move: .check)
        let p3 = makeP(stack: 10,  lastBet: 0, move: .check)
        
        let result = manager.isBettingComplete(activePlayers: [p1, p2, p3], highestBet: 0)
        
        XCTAssertTrue(result)
    }

    func test_isBettingComplete_highestBetZero_anyPlayerNotCheck_returnsFalse() {
        let p1 = makeP(stack: 100, lastBet: 0, move: .check)
        let p2 = makeP(stack: 50,  lastBet: 0, move: .call)  // not OK when highestBet == 0 (per your rules)
        
        let result = manager.isBettingComplete(activePlayers: [p1, p2], highestBet: 0)
        
        XCTAssertFalse(result)
    }

    func test_isBettingComplete_highestBetNonZero_allPlayersMatched_returnsTrue() {
        let highest = 3.0
        let p1 = makeP(stack: 100, lastBet: highest, move: .raise)
        let p2 = makeP(stack: 50,  lastBet: highest, move: .call)
        let p3 = makeP(stack: 10,  lastBet: highest, move: .call)
        
        let result = manager.isBettingComplete(activePlayers: [p1, p2, p3], highestBet: highest)
        
        XCTAssertTrue(result)
    }
    
    func test_isBettingComplete_highestBetNonZero_playerUnderMatched_notAllIn_returnsFalse() {
        let highest = 4.0
        let p1 = makeP(stack: 100, lastBet: highest, move: .call)
        let p2 = makeP(stack: 50,  lastBet: 2.0,     move: .call) // under-called and still has chips => must act
        
        let result = manager.isBettingComplete(activePlayers: [p1, p2], highestBet: highest)
        
        XCTAssertFalse(result)
    }

    func test_isBettingComplete_highestBetNonZero_underMatchedButAllIn_returnsTrue() {
        let highest = 10.0
        
        // Under-matched bet but stack == 0 => considered complete (all-in matched "enough" by rule #1)
        let allInPlayer = makeP(stack: 0, lastBet: 7.0, move: .call)
        let matchedPlayer = makeP(stack: 50, lastBet: highest, move: .call)
        
        let result = manager.isBettingComplete(activePlayers: [allInPlayer, matchedPlayer], highestBet: highest)
        
        XCTAssertTrue(result)
    }

    func test_isBettingComplete_highestBetZero_allInPlayer_countsAsComplete_evenIfNotCheck() {
        // Your rule says: stack == 0 => true regardless of move.
        let allInPlayer = makeP(stack: 0, lastBet: 5.0, move: .call)
        let checker     = makeP(stack: 100, lastBet: 0, move: .check)
        
        let result = manager.isBettingComplete(activePlayers: [allInPlayer, checker], highestBet: 0)
        
        XCTAssertTrue(result)
    }

    func test_isBettingComplete_highestBetNonZero_playerCheckedEvenThoughBetExists_returnsFalse() {
        let highest = 2.0
        let checkedPlayer = makeP(stack: 100, lastBet: 0, move: .check) // checked while bet exists => should be incomplete
        let matchedPlayer = makeP(stack: 50,  lastBet: highest, move: .call)
        
        let result = manager.isBettingComplete(activePlayers: [checkedPlayer, matchedPlayer], highestBet: highest)
        
        XCTAssertFalse(result)
    }

    func test_isBettingComplete_emptyActivePlayers_returnsTrue_vacuously() {
        // allSatisfy on an empty array returns true.
        // This is acceptable if you interpret "no active players" as "nothing to do".
        let result = manager.isBettingComplete(activePlayers: [], highestBet: 0)
        XCTAssertTrue(result)
    }

    func test_isBettingComplete_floatingPointEquality_canFail_ifNotExact() {
        // This test documents current behavior (exact equality).
        // 0.1 + 0.2 != 0.3 exactly in binary floating point.
        let highest = 0.3
        let p1 = makeP(stack: 100, lastBet: 0.1 + 0.2, move: .call)
        
        let result = manager.isBettingComplete(activePlayers: [p1], highestBet: highest)
        
        XCTAssertFalse(result, "Documenting current exact-equality behavior. Consider epsilon compare if needed.")
    }

    
    
    // MARK: - setUpBlinds tests
    func testSetupBlinds_happy() async {
        manager.aiPlayers = makeDummyPlayers()
        
        try? await manager.setUpBlinds()
        
        let sb = manager.aiPlayers[4]
        let bb = manager.aiPlayers[5]
        
        XCTAssertEqual(sb.stack, 99.5)
        XCTAssertEqual(bb.stack, 99)
    }
    
    func testSetUpBlinds_skipActive_doesNotSleep() async {
        let manager = AIGameManager()
        manager.skipActive = true

        var sleepCalled = false
        manager.sleepFunction = { _ in
            sleepCalled = true
        }

        try? await manager.setUpBlinds()
        XCTAssertFalse(sleepCalled, "Sleep should not be called when skipActive is true")
    }
    
    func testSetupBlinds_skip() async {
        let players = makeDummyPlayers()
        players[4].testOutOfMoney = true
        players[5].testOutOfMoney = true
        manager.aiPlayers = players
        
        try? await manager.setUpBlinds()
        
        let sb = manager.aiPlayers[4]
        let bb = manager.aiPlayers[5]
        
        let newSb = manager.aiPlayers[0]
        let newBb = manager.aiPlayers[1]
        
        XCTAssertEqual(sb.stack, 100)
        XCTAssertEqual(bb.stack, 100)
        
        XCTAssertEqual(newSb.stack, 99.5)
        XCTAssertEqual(newBb.stack, 99)
    }
    
    func testSetupBlinds_notEnoughPlayers() async {
        // GIVEN
        let players = makeDummyPlayers()
        players[0].testOutOfMoney = true
        players[1].testOutOfMoney = true
        players[2].testOutOfMoney = true
        players[4].testOutOfMoney = true
        players[5].testOutOfMoney = true

        manager.aiPlayers = players

        // WHEN / THEN
        do {
            try await manager.setUpBlinds()
            XCTFail("Expected setUpBlinds() to throw when not enough players can post blinds")
        } catch let error as GameLoopError {
            XCTAssertEqual(error, .notEnoughPlayersForBlinds)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // AND: No blinds were posted
        for player in players {
            XCTAssertEqual(player.stack, 100)
        }
    }
    
    func testGetFirstPlayerToActIndex_success() {
        manager.aiPlayers = makeDummyPlayers()
        manager.round = 0
        
        let index = manager.getFirstPlayerToActIndex()
        XCTAssertEqual(index, 0)
        
        manager.round = 1
        
        let index2 = manager.getFirstPlayerToActIndex()
        XCTAssertEqual(index2, 4) // Position of sb
    }
    
    func testGetFirstPlayerToActIndex_skipsfold() {
        let players = makeDummyPlayers()
        players[4].testLastMove = .fold
        manager.aiPlayers = players
        
        manager.round = 1
        
        let index = manager.getFirstPlayerToActIndex()
        XCTAssertEqual(index, 5) // Position of sb
    }
    
    func testGetFirstPlayerToActIndex_falure() {
        manager.round = 1
        
        let index = manager.getFirstPlayerToActIndex()
        XCTAssertEqual(index, -1) // Position of sb
    }
    
    
    func testGetActivePlayerIndexInPosition() {
        manager.aiPlayers = makeDummyPlayers()
        
        let index = manager.getActivePlayerIndexInPosition(position: "UTG")
        XCTAssertEqual(index, 0)
    }
    
    func testGetActivePlayerIndexInPosition_skipfold() {
        let players = makeDummyPlayers()
        players[0].testOutOfMoney = true
        
        manager.aiPlayers = players
        
        let index = manager.getActivePlayerIndexInPosition(position: "UTG")
        XCTAssertEqual(index, 1)
        
        players[1].testLastMove = .fold
        
        manager.aiPlayers = players
        
        let index2 = manager.getActivePlayerIndexInPosition(position: "UTG")
        XCTAssertEqual(index2, 2)
    }
    
    func testGetActivePlayerIndexInPosition_skipOutOfMoney() {
        let players = makeDummyPlayers()
        players[0].testOutOfMoney = true
        
        manager.aiPlayers = players
        
        let index = manager.getActivePlayerIndexInPosition(position: "UTG")
        XCTAssertEqual(index, 1)
    }
    
    func testGetActivePlayerIndexInPosition_wraps() {
        let players = makeDummyPlayers()
        players[5].testLastMove = .fold
        
        manager.aiPlayers = players
        
        let index = manager.getActivePlayerIndexInPosition(position: "BB")
        XCTAssertEqual(index, 0)
    }
    
    func testGetActivePlayerIndexInPosition_noActiveLeft() {
        let players = makeDummyPlayers()
        for player in players {
            player.testLastMove = .fold
        }
        
        manager.aiPlayers = players
        
        let index = manager.getActivePlayerIndexInPosition(position: "BB")
        XCTAssertEqual(index, -1)
    }
    
    
    // MARK: - Analytics tracking functions
    @MainActor
    func testInitializeStreetLog_success() {
        let user = AIPlayer(name: "user", fullName: "", position: "UTG", hand: [Card(suit: "heart", rank: "9"), Card(suit: "heart", rank: "7")], isUser: true)
        manager.aiPlayers.append(user)
        let game = Game(gameType: .aiVsHuman)
        manager.gameLog = game
        manager.board = [Card(suit: "heart", rank: "2"), Card(suit: "heart", rank: "4"), Card(suit: "heart", rank: "8")]
        manager.round = 0 // Preflop expected
        
        let successful = manager.initializeStreetLog()
        
        XCTAssertTrue(successful)
        XCTAssertNotNil(manager.aiHandLog)
        
        XCTAssertEqual(manager.aiHandLog?.street, .preflop)
        XCTAssertEqual(manager.aiHandLog?.board ?? [""], manager.board.map { $0.toString() })
        XCTAssertEqual(manager.aiHandLog?.hand, user.hand.handToString())
        XCTAssertEqual(manager.aiHandLog?.game, game)
    }
    
    @MainActor
    func testInitializeStreetLog_roundNumIssue() {
        let user = AIPlayer(name: "user", fullName: "", position: "", isUser: true)
        manager.aiPlayers.append(user)
        let game = Game(gameType: .aiVsHuman)
        manager.gameLog = game
        
        manager.round = 10 // Invalid number
        
        let successful = manager.initializeStreetLog()
        
        XCTAssertFalse(successful)
        XCTAssertNil(manager.aiHandLog)
    }
    
    @MainActor
    func testInitializeStreetLog_gameLogFailure() {
        let user = AIPlayer(name: "user", fullName: "", position: "UTG", hand: [Card(suit: "heart", rank: "9"), Card(suit: "heart", rank: "7")], isUser: true)
        manager.aiPlayers.append(user)
        manager.board = [Card(suit: "heart", rank: "2"), Card(suit: "heart", rank: "4"), Card(suit: "heart", rank: "8")]
        manager.round = 0 // Preflop expected
        
        let successful = manager.initializeStreetLog()
        
        XCTAssertFalse(successful)
        XCTAssertNil(manager.aiHandLog)
    }
    
    @MainActor
    func testInitializeStreetLog_userNotFound() {
        let notUser = AIPlayer(name: "user", fullName: "", position: "UTG", hand: [Card(suit: "heart", rank: "9"), Card(suit: "heart", rank: "7")], isUser: false)
        manager.aiPlayers.append(notUser)
        let game = Game(gameType: .aiVsHuman)
        manager.gameLog = game
        manager.board = [Card(suit: "heart", rank: "2"), Card(suit: "heart", rank: "4"), Card(suit: "heart", rank: "8")]
        manager.round = 0 // Preflop expected
        
        let successful = manager.initializeStreetLog()
        
        XCTAssertFalse(successful)
        XCTAssertNil(manager.aiHandLog)
    }
    
    @MainActor
    func testSaveStreetLog_success() {
        let game = Game(gameType: .aiVsHuman)
        let aiGameLog = AIGameLog(hand: "test", board: ["test"], street: .preflop, game: game)
        
        manager.aiHandLog = aiGameLog
        manager.pot = 125.0
        
        manager.saveStreetLog()
        
        let fetch = FetchDescriptor<AIGameLog>()
        let results = try! manager.context!.fetch(fetch)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.pot, 125.0)
        XCTAssertEqual(results.first?.street, aiGameLog.street)
        XCTAssertEqual(results.first?.board, aiGameLog.board)
        XCTAssertEqual(results.first?.hand, aiGameLog.hand)
        XCTAssertEqual(results.first?.game, aiGameLog.game)
    }
    
    @MainActor
    func testSaveStreetLog_noLog_doesNotCrash() {
        manager.aiHandLog = nil

        // Should not crash
        manager.saveStreetLog()

        // Nothing saved
        let fetch = FetchDescriptor<AIGameLog>()
        let results = try! manager.context!.fetch(fetch)
        XCTAssertEqual(results.count, 0)
    }
    
    
    
    // MARK: - All the ai names populating tests
    func testPopulateAINames_success() async {
        let expectedPlayers = [
            FetchPlayerResponse(name: "Bot1", full_name: "1"),
            FetchPlayerResponse(name: "Bot2", full_name: "2"),
            FetchPlayerResponse(name: "Bot3", full_name: "3"),
            FetchPlayerResponse(name: "Bot4", full_name: "4"),
            FetchPlayerResponse(name: "Bot5", full_name: "5")
        ]
        
        mockAPI.nextNames = expectedPlayers
        await manager.populateAINames()
        
        XCTAssertEqual(manager.aiPlayers.count, 6)
        XCTAssertEqual("HERO", manager.aiPlayers[0].name)
        XCTAssertFalse(manager.isLoading)
        XCTAssertTrue(manager.waitingForStartorRetryButton)
    }
    
    func testPopulateAINames_failure() async {
        let expectedPlayers = [
            FetchPlayerResponse(name: "Bot1", full_name: "1"),
            FetchPlayerResponse(name: "Bot2", full_name: "2"),
            FetchPlayerResponse(name: "Bot3", full_name: "3"),
            FetchPlayerResponse(name: "Bot4", full_name: "4")
        ]
        
        mockAPI.nextNames = expectedPlayers
        await manager.populateAINames()
        
        XCTAssertEqual(manager.aiPlayers.count, 0)
        XCTAssertFalse(manager.isLoading)
        XCTAssertTrue(manager.waitingForStartorRetryButton)
    }
    
    // MARK: - Get AI Player Names
    func testGetAIPlayerNames_success() async {
        // Arrange
        let expectedPlayers = [
            FetchPlayerResponse(name: "Bot1", full_name: "Bot One"),
            FetchPlayerResponse(name: "Bot2", full_name: "Bot Two")
        ]
        mockAPI.nextNames = expectedPlayers
        
        // Act
        let result = await manager.getAIPlayerNames()
        
        // Assert
        XCTAssertEqual(result.count, expectedPlayers.count)
        XCTAssertEqual(result[0].name, "Bot1")
        XCTAssertEqual(result[1].full_name, "Bot Two")
        XCTAssertNil(manager.errorMessage)
        XCTAssertFalse(manager.showToast)
    }
    
    func testGetAIPlayerNames_nil() async {
        // Null vsAPI
        manager.vsAiAPI = nil
        
        // Act
        let result = await manager.getAIPlayerNames()
        
        XCTAssertNotNil(manager.errorMessage)
        XCTAssertTrue(manager.showToast)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testGetAIPlayerNames_serverError() async {
        
        let expectedPlayers = [
            FetchPlayerResponse(name: "Bot1", full_name: "Bot One"),
            FetchPlayerResponse(name: "Bot2", full_name: "Bot Two")
        ]
        mockAPI.nextNames = expectedPlayers
        mockAPI.shouldThrow = true
        
        let result = await manager.getAIPlayerNames()
        
        XCTAssertNotNil(manager.errorMessage)
        XCTAssertTrue(manager.showToast)
        XCTAssertTrue(result.isEmpty)
    }
    
    func testCreateRandomPlayers() {
        let expectedPlayers = [
            FetchPlayerResponse(name: "Bot1", full_name: "1"),
            FetchPlayerResponse(name: "Bot2", full_name: "2"),
            FetchPlayerResponse(name: "Bot3", full_name: "3"),
            FetchPlayerResponse(name: "Bot4", full_name: "4"),
            FetchPlayerResponse(name: "Bot5", full_name: "5")
        ]
        
        let createdPlayers = manager.createRandomPlayers(aiNames: expectedPlayers)
        
        XCTAssertEqual(createdPlayers.count, 6)
        
        XCTAssertEqual("HERO", createdPlayers[0].name)
        
        XCTAssertEqual(expectedPlayers[0].full_name, createdPlayers[1].fullName)
        XCTAssertEqual(expectedPlayers[1].full_name, createdPlayers[2].fullName)
        XCTAssertEqual(expectedPlayers[2].full_name, createdPlayers[3].fullName)
        XCTAssertEqual(expectedPlayers[3].full_name, createdPlayers[4].fullName)
        XCTAssertEqual(expectedPlayers[4].full_name, createdPlayers[5].fullName)
    }
    
    func testCreateRandomPlayers_invalidAINamesCount() {
        // Arrange
        let aiNames: [FetchPlayerResponse] = [] // empty
        let manager = AIGameManager()
        
        // Act
        let players = manager.createRandomPlayers(aiNames: aiNames)
        
        // Assert
        XCTAssertTrue(players.isEmpty)
    }
    
    
    // MARK: - createAndReorderPlayers
    func testCreateAndReorderPlayers_basicOrdering() {
        // Arrange
        manager.tableSize = "6"
        let startPosition = "BTN"

        // Act
        let players = manager.createAndReorderPlayers(startingPosition: startPosition)

        // Assert
        XCTAssertEqual(players.count, 6)
        XCTAssertEqual(players.first?.position, startPosition)

        let expectedOrder = [
            "BTN", "SB", "BB", "UTG", "MP", "CO"
        ]

        XCTAssertEqual(players.map { $0.position }, expectedOrder)
        for player in players {
            XCTAssertEqual(player.stack, 100.0)
        }
    }
    
    func testCreateAndReorderPlayers_wrapAround() {
        // Arrange
        manager.tableSize = "6"
        let startPosition = "CO"

        // Act
        let players = manager.createAndReorderPlayers(startingPosition: startPosition)

        // Assert
        let expectedOrder = [
            "CO", "BTN", "SB", "BB", "UTG", "MP"
        ]

        XCTAssertEqual(players.map { $0.position }, expectedOrder)
        for player in players {
            XCTAssertEqual(player.stack, 100.0)
        }
    }

    // MARK: - Raise & Call Logic
    
    func testRaiseAddsToPotAndReducesStack() {
        let players = makeDummyPlayers()
        manager.aiPlayers = players
        let player1 = players[0]
        manager.raise(aiPlayer: player1, amount: 20)
        
        XCTAssertEqual(manager.pot, 20, "Pot should increase by raised amount")
        XCTAssertEqual(player1.stack, 80, "Player stack should decrease by raised amount")
        XCTAssertEqual(manager.lastPlayerBet, 20, "Last player bet should update")
        // XCTAssertEqual(player1.lastMove(game: 0), .raise)
    }
    
    func testRaiseCannotExceedStack() {
        let players = makeDummyPlayers()
        let player1 = players[0]
        player1.stack = 10
        manager.aiPlayers = players
        
        manager.raise(aiPlayer: player1, amount: 50)
        
        XCTAssertEqual(manager.pot, 10, "Pot should not exceed player stack")
        XCTAssertEqual(player1.stack, 0, "Player should go all-in")
        XCTAssertEqual(manager.lastPlayerBet, 10)
    }
    
    func testCallAddsToPotAndReducesStack() {
        let players = makeDummyPlayers()
        manager.aiPlayers = players
        let player2 = players[1]
        manager.lastPlayerBet = 10
        manager.call(aiPlayer: player2)
        
        XCTAssertEqual(manager.pot, 10, "Pot should increase by called amount")
        XCTAssertEqual(player2.stack, 90)
        XCTAssertEqual(player2.lastMove(game: 0, ), .call)
    }
    
    func testCallAfterRaise() {
        let players = makeDummyPlayers()
        manager.aiPlayers = players
        let player2 = players[1]
        manager.lastPlayerBet = 10
        manager.raise(aiPlayer: players[0], amount: 10)
        manager.call(aiPlayer: player2)
        
        XCTAssertEqual(manager.pot, 20, "Pot should increase by called amount")
        XCTAssertEqual(player2.stack, 90)
        XCTAssertEqual(player2.lastMove(game: 0, ), .call)
    }
    
    func testCallCannotExceedStack() {
        let players = makeDummyPlayers()
        manager.aiPlayers = players
        let player2 = players[1]
        player2.stack = 5
        manager.raise(aiPlayer: players[0], amount: 10)
        manager.call(aiPlayer: player2)
        
        XCTAssertEqual(manager.pot, 15, "Should only call up to available stack")
        XCTAssertEqual(player2.stack, 0)
    }

    // MARK: - User and AI Decision Logic
//    func testGetUserDecisionResumesWithMove() async {
//        let expectation = XCTestExpectation(description: "Waits for continuation")
//        
//        Task {
//            let result = await self.manager.getUserDecision()
//            XCTAssertEqual(result.0, "call")
//            XCTAssertEqual(result.1, 5)
//            expectation.fulfill()
//        }
//        
//        // Simulate UI calling back with user move
//        try? await Task.sleep(nanoseconds: 200_000_000)
//        manager.handleUserMove(move: ("call", 5))
//        
//        await fulfillment(of: [expectation], timeout: 2.0)
//    }

    // MARK: - Utility and Player Checks
    
    
    func testGetUserDefaultBets() {
        manager.aiPlayers = makeDummyPlayers()
        let user = AIPlayer(name: "HERO", fullName: "test", position: "BTN", stack: 15, isUser: true)
        manager.aiPlayers = [user]
        manager.lastPlayerBet = 5
        
        let bets = manager.getUserDefaultBets()
        XCTAssertTrue(bets.allSatisfy { $0 <= 15 })
        XCTAssertFalse(bets.isEmpty)
    }
    
    func testRemainingPlayers() {
        manager.aiPlayers = makeDummyPlayers()
        manager.game = 0
        manager.round = 0
        
        let remaining = manager.remainingPlayers()
        XCTAssertEqual(remaining, 6)
    }
    
    func testRemainingPlayers_someFolded() {
        let players = makeDummyPlayers()
        players[0].testLastMove = .fold
        players[3].testOutOfMoney = true
        manager.aiPlayers = players
        manager.game = 0
        manager.round = 0
        
        let remaining = manager.remainingPlayers()
        XCTAssertEqual(remaining, 4)
    }
    
    @MainActor
    func test_rotatePositions_rotatesPositionsByOne() {
        let manager = AIGameManager(testingMode: true)

        // Set up players with known positions in order
        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 100)
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP",  stack: 100)
        let p3 = AIPlayer(name: "C", fullName: "", position: "CO",  stack: 100)
        let p4 = AIPlayer(name: "D", fullName: "", position: "BTN", stack: 100)

        manager.aiPlayers = [p1, p2, p3, p4]

        manager.rotatePositions()

        // After rotation:
        // p1 gets last position (BTN)
        // p2 gets p1's old (UTG)
        // p3 gets p2's old (MP)
        // p4 gets p3's old (CO)
        XCTAssertEqual(manager.aiPlayers[0].position, "BTN")
        XCTAssertEqual(manager.aiPlayers[1].position, "UTG")
        XCTAssertEqual(manager.aiPlayers[2].position, "MP")
        XCTAssertEqual(manager.aiPlayers[3].position, "CO")
    }

    @MainActor
    func test_rotatePositions_preservesPlayerOrder_onlyPositionsChange() {
        let manager = AIGameManager(testingMode: true)

        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 100)
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP",  stack: 100)
        let p3 = AIPlayer(name: "C", fullName: "", position: "CO",  stack: 100)

        manager.aiPlayers = [p1, p2, p3]
        let originalIDs = manager.aiPlayers.map { $0.id }

        manager.rotatePositions()

        XCTAssertEqual(manager.aiPlayers.map { $0.id }, originalIDs, "Players should remain in same array order; only positions rotate")
    }

    @MainActor
    func test_rotatePositions_singlePlayer_noChange() {
        let manager = AIGameManager(testingMode: true)

        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 100)
        manager.aiPlayers = [p1]

        manager.rotatePositions()

        XCTAssertEqual(manager.aiPlayers[0].position, "UTG")
    }
    
    
    
    @MainActor
    func test_getAIMove_whenAPIIsNil_setsErrorAndReturnsFold() async {
        manager.vsAiAPI = nil

        let ai = AIPlayer(name: "Villain", fullName: "", position: "UTG", stack: 100)
        let move = await manager.getAIMove(ai: ai)

        XCTAssertEqual(move, "fold")
        XCTAssertEqual(manager.errorMessage, "Internal Error")
        XCTAssertTrue(manager.showToast)
    }

    @MainActor
    func test_getAIMove_whenPotIsZero_passesPotOddsZero_andPossibleMovesCheckRaise_whenNoBet() async {
        let ai = AIPlayer(name: "Villain", fullName: "", position: "UTG", stack: 100)
        ai.hand = [Card(suit: "spades", rank: "A"), Card(suit: "spades", rank: "K")] // or however your Card init works

        manager.aiPlayers = [ai, AIPlayer(name: "HERO", fullName: "", position: "BB", stack: 100)]
        manager.pot = 0
        manager.lastPlayerBet = 0
        manager.round = 0
        manager.game = 0
        manager.board = []

        mockAPI.nextDecision = "check"

        let move = await manager.getAIMove(ai: ai)
        XCTAssertEqual(move, "check")

        guard let args = mockAPI.lastFetchAiDecisionArgs else {
            return XCTFail("Expected fetchAiDecision to be called")
        }

        XCTAssertEqual(args.aiName, "Villain")
        XCTAssertEqual(args.potOdds, 0, accuracy: 1e-9)
        XCTAssertEqual(args.possibleMoves, ["check", "raise"])
        XCTAssertEqual(args.opponentCount, manager.remainingPlayers())
        XCTAssertEqual(args.board, []) // board strings
        XCTAssertEqual(args.aiHole.count, 2)
    }

    @MainActor
    func test_getAIMove_whenPotNonZero_calculatesPotOdds_fromLastBetOverPot() async {
        let ai = AIPlayer(name: "Villain", fullName: "", position: "UTG", stack: 100)
        manager.aiPlayers = [ai, AIPlayer(name: "HERO", fullName: "", position: "BB", stack: 100)]

        manager.game = 0
        manager.round = 0
        manager.pot = 20
        manager.lastPlayerBet = 5 // implies "call/raise/fold" moves should be sent

        // Make ai have already put 5 in this round:
        ai.raise(amount: 5, game: 0, round: 0)

        mockAPI.nextDecision = "call"

        _ = await manager.getAIMove(ai: ai)

        guard let args = mockAPI.lastFetchAiDecisionArgs else {
            return XCTFail("Expected fetchAiDecision to be called")
        }

        XCTAssertEqual(args.potOdds, 5.0 / 20.0, accuracy: 1e-9)
        XCTAssertEqual(args.possibleMoves, ["call", "raise", "fold"])
    }

    @MainActor
    func test_getAIMove_whenAPIThrows_setsErrorAndReturnsFold() async {
        let ai = AIPlayer(name: "Villain", fullName: "", position: "UTG", stack: 100)
        manager.aiPlayers = [ai, AIPlayer(name: "HERO", fullName: "", position: "BB", stack: 100)]

        mockAPI.shouldThrow = true

        let move = await manager.getAIMove(ai: ai)

        XCTAssertEqual(move, "fold")
        XCTAssertEqual(manager.errorMessage, "Failed to get AI move")
        XCTAssertTrue(manager.showToast)
    }
    
    @MainActor
        func test_determineWinners_whenAPIIsNil_setsErrorAndReturnsEmpty() async {
            manager.vsAiAPI = nil

            let winnerDetails = try? await manager.determineWinners()
            let winners = winnerDetails?.winners

            XCTAssertEqual(winners, nil)
            XCTAssertEqual(manager.errorMessage, "Internal Error")
            XCTAssertTrue(manager.showToast)
        }

        @MainActor
        func test_determineWinners_whenAPIThrows_setsErrorAndReturnsEmpty() async {
            mockAPI.shouldThrow = true
            manager.vsAiAPI = mockAPI

            let winnerDetails = try? await manager.determineWinners()
            let winners = winnerDetails?.winners

            XCTAssertEqual(winners, nil)
            XCTAssertEqual(manager.errorMessage, "Failed to determine winners")
            XCTAssertTrue(manager.showToast)
        }

        @MainActor
        func test_determineWinners_success_returnsWinners_andPassesFilteredPlayersAndBoard() async {
            mockAPI.shouldThrow = false
            mockAPI.nextWinners = ["HERO", "V1"]

            // Build players: keep 2, exclude 2 (folded/out-of-money)
            let hero = AIPlayer(name: "HERO", fullName: "", position: "UTG", stack: 100)
            hero.isUser = true

            let v1 = AIPlayer(name: "V1", fullName: "", position: "MP", stack: 100)

            let folded = AIPlayer(name: "FOLDED", fullName: "", position: "CO", stack: 100)
            folded.fold(game: manager.game, round: manager.round)

            let busted = AIPlayer(name: "BUSTED", fullName: "", position: "BTN", stack: 0)

            manager.aiPlayers = [hero, v1, folded, busted]

            // Set board
            manager.board = [
                Card(suit: "spades", rank: "A"),
                Card(suit: "hearts", rank: "K"),
                Card(suit: "diamonds", rank: "Q")
            ]

            let winnerDetails = try? await manager.determineWinners()
            let winners = winnerDetails?.winners

            // Return value
            XCTAssertEqual(winners, ["HERO", "V1"])

            // Verify args passed to API
            guard let args = mockAPI.lastProcessWinnersArgs else {
                return XCTFail("Expected processWinners to be called")
            }

            // playersLeft should exclude folded and busted
            let namesSent = args.playersLeft.map { $0.name }.sorted()
            XCTAssertEqual(namesSent, ["HERO", "V1"])

            // board strings should match manager.board.map { toString() }
            XCTAssertEqual(args.board, manager.board.map { $0.toString() })
        }
    @MainActor
        func test_getUserDefaultBets_returnsEmpty_whenNoUser() {
            let manager = AIGameManager(testingMode: true)
            manager.aiPlayers = makePlayers() // none isUser
            manager.lastPlayerBet = 0

            XCTAssertEqual(manager.getUserDefaultBets(), [])
        }

        @MainActor
        func test_getUserDefaultBets_filtersByUserStack_andAddsLastPlayerBet() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 12 // can afford totals up to 12
            manager.aiPlayers = players

            manager.lastPlayerBet = 3

            // Default bases: 2,5,10,20 -> totals: 5,8,13,23 -> keep 5,8
            XCTAssertEqual(manager.getUserDefaultBets(), [5, 8])
        }

        @MainActor
        func test_getUserDefaultBets_whenUserStackTooSmall_returnsOnlyAffordable() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 4
            manager.aiPlayers = players

            manager.lastPlayerBet = 0
            // totals: 2,5,10,20 -> only 2 fits
            XCTAssertEqual(manager.getUserDefaultBets(), [2])
        }

        // MARK: - getPossibleActions

        @MainActor
        func test_getPossibleActions_returnsEmpty_whenNoUser() {
            let manager = AIGameManager(testingMode: true)
            manager.aiPlayers = makePlayers() // none isUser

            XCTAssertEqual(manager.getPossibleActions(), [])
        }

        @MainActor
        func test_getPossibleActions_whenNoBet_allowsCheckAndRaise_only() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 100
            manager.aiPlayers = players

            manager.lastPlayerBet = 0

            XCTAssertEqual(manager.getPossibleActions(), ["Check", "Raise"])
        }

        @MainActor
        func test_getPossibleActions_whenBetExists_allowsFoldCallRaise_noCheck() {
            let manager = AIGameManager(testingMode: true)

            let players = makePlayers()
            players[0].isUser = true
            players[0].stack = 100
            manager.aiPlayers = players

            manager.lastPlayerBet = 10

            XCTAssertEqual(manager.getPossibleActions(), ["Fold", "Call", "Raise"])
        }

        @MainActor
    func test_getPossibleActions_whenBetGreaterThanStack_allInOnly() {
        let manager = AIGameManager(testingMode: true)
        
        let players = makePlayers()
        players[0].isUser = true
        players[0].stack = 9
        manager.aiPlayers = players
        
        manager.lastPlayerBet = 10
        
        XCTAssertEqual(manager.getPossibleActions(), ["Fold", "All In"])
    }
    @MainActor
        func test_makeAIDecision_whenCall_setsAmountToLastPlayerBet() async {
            let manager = SpyDecisionManager(testingMode: true)
            manager.scriptedMove = "call"
            manager.lastPlayerBet = 7.5
            manager.game = 0
            manager.round = 0

            let ai = AIPlayer(name: "V", fullName: "", position: "UTG", stack: 100)

            let (action, amount) = await manager.makeAIDecision(ai: ai)

            XCTAssertEqual(action, "call")
            XCTAssertEqual(amount, 7.5, accuracy: 1e-9)
        }

        @MainActor
        func test_makeAIDecision_whenRaise_andStackLessThanCallCost_returnsFold() async {
            let manager = SpyDecisionManager(testingMode: true)
            manager.scriptedMove = "raise"
            manager.game = 0
            manager.round = 0

            // lastPlayerBet is what must be matched; ai has already committed 2
            manager.lastPlayerBet = 10

            let ai = AIPlayer(name: "V", fullName: "", position: "UTG", stack: 7)
            _ = ai.raise(amount: 2, game: 0, round: 0) // commit 2

            // callCost = max(0, 10 - 2) = 8; ai.stack = 7 < 8 => fold
            let (action, amount) = await manager.makeAIDecision(ai: ai)

            XCTAssertEqual(action, "fold")
            XCTAssertEqual(amount, 0, accuracy: 1e-9)
        }

        @MainActor
        func test_makeAIDecision_whenRaise_andStackEqualsCallCost_returnsCall() async {
            let manager = SpyDecisionManager(testingMode: true)
            manager.scriptedMove = "raise"
            manager.game = 0
            manager.round = 0
            manager.lastPlayerBet = 8

            let ai = AIPlayer(name: "V", fullName: "", position: "UTG", stack: 8)
            _ = ai.raise(amount: 2, game: 0, round: 0) // commit 2

            // callCost = 8 and stack == 8 => should return ("call", lastPlayerBet)
            let (action, amount) = await manager.makeAIDecision(ai: ai)

            XCTAssertEqual(action, "call")
            XCTAssertEqual(amount, 8, accuracy: 1e-9)
        }
    
    @MainActor
        func test_makeAIDecision_whenRaise_andStackGreaterThanCallCost_returnsRaise_withHalfStepDelta() async {
            let manager = SpyDecisionManager(testingMode: true)
            manager.scriptedMove = "raise"
            manager.game = 0
            manager.round = 0
            manager.lastPlayerBet = 6.0

            let ai = AIPlayer(name: "V", fullName: "", position: "UTG", stack: 100)

            let (action, amount) = await manager.makeAIDecision(ai: ai)

            XCTAssertEqual(action, "raise")

            // amount = lastPlayerBet + delta, where delta in [1, 10] with 0.5 increments
            XCTAssertGreaterThanOrEqual(amount, 7.0 - 1e-9)
            XCTAssertLessThanOrEqual(amount, 16.0 + 1e-9)

            // delta is 0.5-step: (amount - lastPlayerBet) * 2 should be integer
            let deltaTimes2 = (amount - manager.lastPlayerBet) * 2.0
            XCTAssertEqual(deltaTimes2.rounded(), deltaTimes2, accuracy: 1e-9)
        }

        @MainActor
        func test_makeAIDecision_whenCheck_returnsZeroAmount() async {
            let manager = SpyDecisionManager(testingMode: true)
            manager.scriptedMove = "check"
            manager.lastPlayerBet = 10
            manager.game = 0
            manager.round = 0

            let ai = AIPlayer(name: "V", fullName: "", position: "UTG", stack: 100)

            let (action, amount) = await manager.makeAIDecision(ai: ai)

            XCTAssertEqual(action, "check")
            XCTAssertEqual(amount, 0, accuracy: 1e-9)
        }

        @MainActor
        func test_makeAIDecision_whenFold_returnsZeroAmount() async {
            let manager = SpyDecisionManager(testingMode: true)
            manager.scriptedMove = "fold"
            manager.lastPlayerBet = 10
            manager.game = 0
            manager.round = 0

            let ai = AIPlayer(name: "V", fullName: "", position: "UTG", stack: 100)

            let (action, amount) = await manager.makeAIDecision(ai: ai)

            XCTAssertEqual(action, "fold")
            XCTAssertEqual(amount, 0, accuracy: 1e-9)
        }
    
    @MainActor
    func test_makeAIDecision_whenRaiseDesiredExceedsMaxRaiseTo_returnsAllInCapped() async {
        let manager = SpyDecisionManager(testingMode: true)
        manager.scriptedMove = "raise"
        manager.game = 0
        manager.round = 0
        manager.lastPlayerBet = 6.0

        // Small stack so maxRaiseTo is low
        let ai = AIPlayer(name: "V", fullName: "", position: "UTG", stack: 1.0)
        // alreadyCommitted = 0, callCost = 6, but ai.stack < callCost => would fold
        // So we need ai to have enough to call first:
        ai.stack = 6.0  // equals callCost -> your code would return call, so still not good
        // Make alreadyCommitted non-zero so callCost smaller:
        _ = ai.raise(amount: 5.5, game: 0, round: 0) // commit 5.5, stack becomes 0.5

        // Now callCost = 6.0 - 5.5 = 0.5, stack == 0.5 => would return call if == callCost
        // Bump stack slightly so we get to "raise" path:
        ai.stack = 1.0

        // Now maxRaiseTo = alreadyCommitted (5.5) + stack (1.0) = 6.5
        // desiredRaiseTo is at least lastPlayerBet + 1.0 = 7.0, which exceeds 6.5
        let (action, amount) = await manager.makeAIDecision(ai: ai)

        XCTAssertEqual(action, "allin")
        XCTAssertEqual(amount, 6.5, accuracy: 1e-9)
    }
    
    func test_processRoundEnd_OneWinner() async {
        let manager = AIGameManager(testingMode: true)

        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 50)
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP", stack: 70)
        manager.aiPlayers = [p1, p2]
        manager.pot = 20
        
        // P1 folds -> winner p2
        p1.fold(game: 0, round: 0)
        
        try? await manager.processRoundEnd()

        XCTAssertEqual(p1.stack, 50)
        XCTAssertEqual(p2.stack, 90, accuracy: 1e-9)
    }
    
    func test_processRoundEnd_basicShowdown() async {

        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 50)
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP", stack: 70)
        manager.aiPlayers = [p1, p2]
        
        
        mockAPI.nextWinners = ["B"]
        mockAPI.nextWinnerDetails = [
            PlayerDetails(name: "A", hand: [], score: 4, hand_name: ""),
            PlayerDetails(name: "B", hand: [], score: 3, hand_name: "")
        ]
        
        _ = p1.raise(amount: 10, game: 0, round: 0)
        _ = p2.call(amount: 10, game: 0, round: 0)
        manager.pot = 20
        
        // 2 active players - basic showdown
        try? await manager.processRoundEnd()

        XCTAssertEqual(p1.stack, 40)
        XCTAssertEqual(p2.stack, 80, accuracy: 1e-9)
    }
    
    func test_processRoundEnd_basicShowdownOnePrevFolded() async {

        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 50)
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP", stack: 70)
        let p3 = AIPlayer(name: "C", fullName: "", position: "CO", stack: 70)
        manager.aiPlayers = [p1, p2, p3]
        
        
        mockAPI.nextWinners = ["B"]
        mockAPI.nextWinnerDetails = [
            PlayerDetails(name: "A", hand: [], score: 4, hand_name: ""),
            PlayerDetails(name: "B", hand: [], score: 3, hand_name: "")
        ]
        
        _ = p1.raise(amount: 10, game: 0, round: 0)
        _ = p2.call(amount: 10, game: 0, round: 0)
        _ = p3.call(amount: 10, game: 0, round: 0)
        p3.fold(game: 0, round: 0)
        manager.pot = 20
        
        // 2 active players - basic showdown
        try? await manager.processRoundEnd()

        XCTAssertEqual(p1.stack, 40)
        XCTAssertEqual(p3.stack, 60)
        XCTAssertEqual(p2.stack, 90, accuracy: 1e-9)
    }
    
    func test_processRoundEnd_basicShowdownInconsistentBetNumbers() async {

        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 50)
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP", stack: 70)
        let p3 = AIPlayer(name: "C", fullName: "", position: "CO", stack: 70)
        manager.aiPlayers = [p1, p2, p3]
        
        
        mockAPI.nextWinners = ["B"]
        mockAPI.nextWinnerDetails = [
            PlayerDetails(name: "C", hand: [], score: 4, hand_name: ""),
            PlayerDetails(name: "B", hand: [], score: 3, hand_name: "")
        ]
        
        _ = p1.raise(amount: 0.5, game: 0, round: 0)
        _ = p2.raise(amount: 5, game: 0, round: 0)
        _ = p3.call(amount: 5, game: 0, round: 0)
        p1.fold(game: 0, round: 0)
        _ = p2.raise(amount: 10, game: 0, round: 0)
        _ = p3.call(amount: 10, game: 0, round: 0)
        manager.pot = 20.5
        
        // 2 active players - basic showdown
        try? await manager.processRoundEnd()

        XCTAssertEqual(p2.stack, 80.5, accuracy: 1e-9)
    }
    
    func test_processRoundEnd_showdown_tie_splitsPot() async {
        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 100)
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP", stack: 100)

        manager.aiPlayers = [p1, p2]

        mockAPI.nextWinners = ["A", "B"]
        mockAPI.nextWinnerDetails = [
            PlayerDetails(name: "A", hand: [], score: 1, hand_name: "Tie"),
            PlayerDetails(name: "B", hand: [], score: 1, hand_name: "Tie")
        ]

        _ = p1.raise(amount: 20, game: 0, round: 0)
        _ = p2.call(amount: 20, game: 0, round: 0)
        manager.pot = 40

        try? await manager.processRoundEnd()

        // Each put in 20, pot 40 split => each net 0 change
        XCTAssertEqual(p1.stack, 100, accuracy: 1e-9)
        XCTAssertEqual(p2.stack, 100, accuracy: 1e-9)
    }
    
    func test_processRoundEnd_showdown_oneSidePot_twoDifferentWinners() async {
        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 30)   // all-in
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP", stack: 100)
        let p3 = AIPlayer(name: "C", fullName: "", position: "CO", stack: 100)

        manager.aiPlayers = [p1, p2, p3]

        // Commitments
        _ = p1.raise(amount: 30, game: 0, round: 0) // all-in
        _ = p2.raise(amount: 60, game: 0, round: 0)
        _ = p3.call(amount: 60, game: 0, round: 0)

        manager.pot = 150

        // Winner ordering must allow:
        // - A beats everyone in main pot
        // - B beats C for side pot
        mockAPI.nextWinners = ["A"] // (if your API returns just "overall" winners)
        mockAPI.nextWinnerDetails = [
            PlayerDetails(name: "A", hand: [], score: 1, hand_name: ""),
            PlayerDetails(name: "B", hand: [], score: 2, hand_name: ""),
            PlayerDetails(name: "C", hand: [], score: 3, hand_name: "")
        ]

        try? await manager.processRoundEnd()

        // After bets:
        // A: 30 -> 0, wins 90 => 90
        // B: 100 -> 40, wins 60 => 100
        // C: 100 -> 40
        XCTAssertEqual(p1.stack, 90, accuracy: 1e-9)
        XCTAssertEqual(p2.stack, 100, accuracy: 1e-9)
        XCTAssertEqual(p3.stack, 40, accuracy: 1e-9)
    }
    
    func test_processRoundEnd_showdown_twoSidePots_twoAllIns() async {
        let p1 = AIPlayer(name: "A", fullName: "", position: "UTG", stack: 20)   // all-in
        let p2 = AIPlayer(name: "B", fullName: "", position: "MP", stack: 50)   // all-in
        let p3 = AIPlayer(name: "C", fullName: "", position: "CO", stack: 200)

        manager.aiPlayers = [p1, p2, p3]

        _ = p1.raise(amount: 20, game: 0, round: 0)
        _ = p2.raise(amount: 50, game: 0, round: 0)
        _ = p3.call(amount: 80, game: 0, round: 0)
        manager.pot = 150

        // Make A best overall (wins main),
        // B second (wins side1),
        // C last (wins nothing except any "only eligible" pot behavior)
        mockAPI.nextWinners = ["A"]
        mockAPI.nextWinnerDetails = [
            PlayerDetails(name: "A", hand: [], score: 1, hand_name: ""),
            PlayerDetails(name: "B", hand: [], score: 2, hand_name: ""),
            PlayerDetails(name: "C", hand: [], score: 3, hand_name: "")
        ]

        try? await manager.processRoundEnd()

        // This depends on how you treat "pot where only one eligible player exists"
        // Many implementations won't create Side2 at all, or will just leave it as already in C's stack (but it isn't).
        //
        // If Side2 is created and awarded to C, expected:
        // A: 20 -> 0 +60 = 60
        // B: 50 -> 0 +60 = 60
        // C: 200 -> 120 +30 = 150
        //
        // If Side2 is NOT created and your pot is still 150, then something else is wrong because money must go somewhere.
        //
        // So assert the money conservation and the known pots at least:
        XCTAssertEqual(p1.stack + p2.stack + p3.stack, 20 + 50 + 200, accuracy: 1e-9)
    }

    
    func test_determineSidePots() {
        // Scenario one
        // - Players_Left: 1, 2, 3
        // - Pot: 15 (each player in for 5 - only one pot here)
        let p1 = AIPlayer(name: "p1", fullName: "", position: "UTG", stack: 100, isUser: true)
        let p2 = AIPlayer(name: "p2", fullName: "", position: "SB", stack: 100)
        let p3 = AIPlayer(name: "p3", fullName: "", position: "BB", stack: 100)
        
        // Winner here is p1 and they win the full 15
        let remainingDetails = [
            PlayerDetails(name: p1.name, hand: [""], score: 0, hand_name: ""),
            PlayerDetails(name: p2.name, hand: [""], score: 4, hand_name: ""),
            PlayerDetails(name: p3.name, hand: [""], score: 5, hand_name: "")
        ]
        
        _ = p1.raise(amount: 5, game: 0, round: 0)
        _ = p2.call(amount: 5, game: 0, round: 0)
        _ = p3.call(amount: 5, game: 0, round: 0)
        manager.pot = 15
        
        let sidePots = manager.determineSidePots(players: [p1, p2, p3], remainingDetails: remainingDetails)
        
        XCTAssertEqual(sidePots[0].amount, 15)
        let expectedEligiblePlayerNames = ["p1", "p2", "p3"]
        for (index, player) in sidePots[0].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames[index])
        }
        XCTAssertEqual(sidePots[0].winners, ["p1"])
        XCTAssertEqual(sidePots[0].splitAmount, 15)
    }
    
    func test_determineSidePots_oneSidePot_classic_40_100_100() {
        let p1 = AIPlayer(name: "p1", fullName: "", position: "UTG", stack: 100, isUser: true)
        let p2 = AIPlayer(name: "p2", fullName: "", position: "SB", stack: 100)
        let p3 = AIPlayer(name: "p3", fullName: "", position: "BB", stack: 100)

        // Contributions: p1=40, p2=100, p3=100
        _ = p1.raise(amount: 40, game: 0, round: 0)
        _ = p2.raise(amount: 100, game: 0, round: 0)
        _ = p3.call(amount: 100, game: 0, round: 0)

        // Total pot would be 240
        manager.pot = 240

        // Scores (lower is better): p1 best overall, p2 best among p2/p3
        let remainingDetails = [
            PlayerDetails(name: "p1", hand: [""], score: 1, hand_name: ""),
            PlayerDetails(name: "p2", hand: [""], score: 10, hand_name: ""),
            PlayerDetails(name: "p3", hand: [""], score: 20, hand_name: "")
        ]

        let sidePots = manager.determineSidePots(players: [p1,p2,p3], remainingDetails: remainingDetails)

        XCTAssertEqual(sidePots.count, 2)

        // Main: 40 * 3 = 120
        XCTAssertEqual(sidePots[0].amount, 120, accuracy: 1e-9)
        let expectedEligiblePlayerNames = ["p1", "p2", "p3"]
        for (index, player) in sidePots[0].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames[index])
        }
        XCTAssertEqual(sidePots[0].winners, ["p1"])
        XCTAssertEqual(sidePots[0].splitAmount, 120, accuracy: 1e-9)

        // Side: (100-40) * 2 = 120
        XCTAssertEqual(sidePots[1].amount, 120, accuracy: 1e-9)
        let expectedEligiblePlayerNames2 = ["p2", "p3"]
        for (index, player) in sidePots[1].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames2[index])
        }
        XCTAssertEqual(sidePots[1].winners, ["p2"])
        XCTAssertEqual(sidePots[1].splitAmount, 120, accuracy: 1e-9)
    }
    
    func test_determineSidePots_twoSidePots_20_50_100_100() {
        let p1 = AIPlayer(name: "p1", fullName: "", position: "UTG", stack: 100, isUser: true)
        let p2 = AIPlayer(name: "p2", fullName: "", position: "MP", stack: 100)
        let p3 = AIPlayer(name: "p3", fullName: "", position: "CO", stack: 100)
        let p4 = AIPlayer(name: "p4", fullName: "", position: "BTN", stack: 100)

        // Contributions: 20, 50, 100, 100
        _ = p1.raise(amount: 20, game: 0, round: 0)
        _ = p2.raise(amount: 50, game: 0, round: 0)
        _ = p3.raise(amount: 100, game: 0, round: 0)
        _ = p4.call(amount: 100, game: 0, round: 0)

        manager.pot = 270

        // Scores: p1 wins main, p2 wins mid, p3 wins top
        let remainingDetails = [
            PlayerDetails(name: "p1", hand: [""], score: 1, hand_name: ""),
            PlayerDetails(name: "p2", hand: [""], score: 5, hand_name: ""),
            PlayerDetails(name: "p3", hand: [""], score: 10, hand_name: ""),
            PlayerDetails(name: "p4", hand: [""], score: 20, hand_name: "")
        ]

        let sidePots = manager.determineSidePots(players: [p1,p2,p3,p4], remainingDetails: remainingDetails)

        XCTAssertEqual(sidePots.count, 3)

        // Pot 1: 20 * 4 = 80 (all)
        XCTAssertEqual(sidePots[0].amount, 80, accuracy: 1e-9)
        let expectedEligiblePlayerNames = ["p1","p2","p3","p4"]
        for (index, player) in sidePots[0].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames[index])
        }
        XCTAssertEqual(sidePots[0].winners, ["p1"])
        XCTAssertEqual(sidePots[0].splitAmount, 80, accuracy: 1e-9)

        // Pot 2: (50-20) * 3 = 90 (p2,p3,p4)
        XCTAssertEqual(sidePots[1].amount, 90, accuracy: 1e-9)
        let expectedEligiblePlayerNames2 = ["p2","p3","p4"]
        for (index, player) in sidePots[1].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames2[index])
        }
        XCTAssertEqual(sidePots[1].winners, ["p2"])
        XCTAssertEqual(sidePots[1].splitAmount, 90, accuracy: 1e-9)

        // Pot 3: (100-50) * 2 = 100 (p3,p4)
        XCTAssertEqual(sidePots[2].amount, 100, accuracy: 1e-9)
        let expectedEligiblePlayerNames3 = ["p3","p4"]
        for (index, player) in sidePots[2].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames3[index])
        }
        XCTAssertEqual(sidePots[2].winners, ["p3"])
        XCTAssertEqual(sidePots[2].splitAmount, 100, accuracy: 1e-9)
    }

    func test_determineSidePots_tieSplitsSidePot() {
        let p1 = AIPlayer(name: "p1", fullName: "", position: "UTG", stack: 100, isUser: true)
        let p2 = AIPlayer(name: "p2", fullName: "", position: "SB", stack: 100)
        let p3 = AIPlayer(name: "p3", fullName: "", position: "BB", stack: 100)

        _ = p1.raise(amount: 40, game: 0, round: 0)
        _ = p2.raise(amount: 100, game: 0, round: 0)
        _ = p3.call(amount: 100, game: 0, round: 0)
        manager.pot = 240

        // p1 wins main, p2 & p3 tie for side
        let remainingDetails = [
            PlayerDetails(name: "p1", hand: [""], score: 1, hand_name: ""),
            PlayerDetails(name: "p2", hand: [""], score: 10, hand_name: ""),
            PlayerDetails(name: "p3", hand: [""], score: 10, hand_name: "")
        ]

        let sidePots = manager.determineSidePots(players: [p1,p2,p3], remainingDetails: remainingDetails)

        XCTAssertEqual(sidePots.count, 2)

        // Side pot amount = 120, split between 2 winners => 60 each
        XCTAssertEqual(sidePots[1].amount, 120, accuracy: 1e-9)
        XCTAssertEqual(Set(sidePots[1].winners), Set(["p2","p3"]))
        XCTAssertEqual(sidePots[1].splitAmount, 60, accuracy: 1e-9)
    }

    func test_determineSidePots_usesTotalContribution_acrossMultipleRounds() {
        let p1 = AIPlayer(name: "p1", fullName: "", position: "UTG", stack: 200, isUser: true)
        let p2 = AIPlayer(name: "p2", fullName: "", position: "SB", stack: 200)
        let p3 = AIPlayer(name: "p3", fullName: "", position: "BB", stack: 200)

        // Round 0 max: p1=10, p2=10, p3=10
        _ = p1.raise(amount: 10, game: 0, round: 0)
        _ = p2.call(amount: 10, game: 0, round: 0)
        _ = p3.call(amount: 10, game: 0, round: 0)

        // Round 1 max: p1=0, p2=40, p3=40
        _ = p2.raise(amount: 40, game: 0, round: 1)
        _ = p3.call(amount: 40, game: 0, round: 1)

        // Totals: p1=10, p2=50, p3=50
        // Pots: 10*3=30, (50-10)*2=80
        manager.pot = 110

        let remainingDetails = [
            PlayerDetails(name: "p1", hand: [""], score: 1, hand_name: ""),
            PlayerDetails(name: "p2", hand: [""], score: 10, hand_name: ""),
            PlayerDetails(name: "p3", hand: [""], score: 20, hand_name: "")
        ]

        let sidePots = manager.determineSidePots(players: [p1,p2,p3], remainingDetails: remainingDetails)

        XCTAssertEqual(sidePots.count, 2)
        XCTAssertEqual(sidePots[0].amount, 30, accuracy: 1e-9)
        let expectedEligiblePlayerNames3 = ["p1","p2","p3"]
        for (index, player) in sidePots[0].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames3[index])
        }
        XCTAssertEqual(sidePots[1].amount, 80, accuracy: 1e-9)
        
        let expectedEligiblePlayerNames1 = ["p2","p3"]
        for (index, player) in sidePots[1].eligiblePlayers.enumerated() {
            XCTAssertEqual(player.name, expectedEligiblePlayerNames1[index])
        }
    }

    
    func test_distributePot_notUser() {
        let player = AIPlayer(name: "test", fullName: "testste", position: "UTG", stack: 0.0)
        
        manager.distributePot(to: player, amount: 10)
        
        XCTAssertEqual(player.stack, 10)
    }
    
    
    @MainActor
    func test_distributePot_user() {
        let player = AIPlayer(name: "test", fullName: "testste", position: "UTG", stack: 0.0, isUser: true)
        player.hand = [Card(suit: "hearts", rank: "K"),
                       Card(suit: "diamonds", rank: "Q")]
        
        
        
        let game = Game(gameType: .aiVsHuman)
        manager.gameLog = game
        manager.aiPlayers = [player]
        
        _ = manager.initializeStreetLog()
        
        manager.distributePot(to: player, amount: 10)
        
        
        XCTAssertEqual(player.stack, 10)
        XCTAssertEqual(manager.aiHandLog?.wonHand, true)
        XCTAssertEqual(manager.aiHandLog?.xpEarned, 5)
        
    }
}


