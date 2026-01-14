import Observation
import Foundation
import SwiftData

enum GameLoopError: Error, Equatable {
    case notEnoughPlayersForBlinds
    case bettingRoundDidNotConverge
    case invalidFirstPlayer
    case unknownAIAction
    case userCancelled
    case sbNotFound
    case bbNotFound
    case winnerNotFound
    case apiNotSet
}

struct SidePot {
    let amount: Double
    let eligiblePlayers: [AIPlayer]
    let winners: [String]
    let splitAmount: Double
}


@MainActor
@Observable
class AIGameManager {
    // Data saving info
    var context: ModelContext?
    var vsAiAPI: VsAIAPI?
    
    var profile: Profile? = nil
    var isPaid: Bool = false
    var gameLog: Game?
    var aiHandLog: AIGameLog?
    // Game state variables
    var aiPlayers: [AIPlayer] = []
    var pot = 0.0
    var round = 0 // Preflop = 0, Flop = 1, Turn = 2, River = 3
    var game = 0 // Iterates upwards
    var lastPlayerBet = 0.0
    let deck = Deck() // Create a shared deck
    var board: [Card] = []
    var isShowdown = false
    var winnersThisHand: Set<String> = []
    var showdownHandNames: [String: String] = [:]
    
    // Used to handle user input
    var waitingForUserInput: Bool = false
    var pendingUserMoveContinuation: CheckedContinuation<(String, Double), Never>?
    
    // User start/continue input buttons
    var waitingForContinueButton: Bool = false
    var waitingForStartorRetryButton: Bool = false
    
    // Error handling
    var isLoading = false
    var errorMessage: String?
    var showToast = false

    // User configs
    let sleepTime: UInt64
    var tableSize: String = "6"
    
    // Computed for simplicity
    var canSkip: Bool {
        !skipActive &&
        !waitingForUserInput &&
        !waitingForStartorRetryButton &&
        !waitingForContinueButton &&
        !isLoading &&
        errorMessage == nil
    }
    
    var skipActive: Bool = false

    init(testingMode: Bool = false) {
        self.sleepTime = testingMode ? 0 : 1_200_000_000
    }
    
    
    /// Called from the UI on load. Retrieves the AI names and sets stacks
    func populateAINames() async {
        isLoading = true
        let aiNames = await getAIPlayerNames()
        aiPlayers = createRandomPlayers(aiNames: aiNames)
        
        // This still needs to be set to true regardless of any errors retrieving names
        isLoading = false
        waitingForStartorRetryButton = true
    }

    func startGame() async {
        gameLog = Game(gameType: .aiVsHuman)
        context?.insert(gameLog!)
        
        // Deal cards
        for player in aiPlayers {
            player.hand.append(deck.dealCard())
            player.hand.append(deck.dealCard())
        }
        
        await sleepFunction(sleepTime)
        await gameLoop()
    }
    
    func canStartNewGame() -> Bool {
        guard let user = aiPlayers.first(where: { $0.isUser }) else {
            Log.aiGame.info("Validation failed: no user found")
            return false
        }
        
        let playersWithChips = aiPlayers.filter { $0.stack > 0 }
        if playersWithChips.count < 2 {
            Log.aiGame.info("Validation failed: not enough players with chips")
            return false
        }
        
        // Check if user is in the game
        if user.stack <= 0 {
            Log.aiGame.info("Validation failed: user is out of money")
            return false
        }
        
        return true
    }
    
    func startNextGame() async {
        if !canStartNewGame() {
            return
        }
        
        // Reset necessarry variables and trigger a new hand deal out
        isShowdown = false
        winnersThisHand = []
        showdownHandNames = [:]
        board = []
        deck.resetDeck() // Creates new shuffled deck
        round = 0
        game += 1
        
        gameLog = Game(gameType: .aiVsHuman)
        context?.insert(gameLog!)
        
        // Need to shift positions
        rotatePositions()
        
        // Also need to reset all players last moves and deal new cards
        for player in aiPlayers {
            player.hand.removeAll()
            if !player.isOutOfMoney(game: game) {
                player.hand = [deck.dealCard(), deck.dealCard()]
            }
        }
        
        await gameLoop()
    }
    
    @MainActor
    func initializeStreetLog() -> Bool {
        guard let currentGameLog = gameLog else {
            Log.data.error("No game log found - No vsAI data will be saved")
            return false
        }
        
        guard let user = aiPlayers.first(where: { $0.isUser }) else {
            Log.aiGame.error("No user found in aiGame - No data will be saved")
            return false
        }
        
        guard Street.allCases.indices.contains(round) else {
            Log.aiGame.error("initializeStreetLog failed: invalid round index \(self.round, privacy: .public)")
            return false
        }
        
        let street = Street.allCases[round]
        let boardString = board.map { $0.toString() }
        
        aiHandLog = AIGameLog(hand: user.hand.handToString(), board: boardString, street: street, game: currentGameLog)
        
        return true
        
    }
    
    @MainActor
    func saveStreetLog() {
        guard let currentLog = aiHandLog else {
            Log.data.error("No game log found - No vsAI data will be saved")
            return
        }
        
        currentLog.pot = pot
        context?.insert(currentLog)
        do {
            try context?.save()
        } catch {
            Log.data.error("Failed to save vs ai game: \(error, privacy: .private)")
        }
    }
    
    @MainActor
    func gameLoop() async {
        do {
            let didInitPreflopLog = initializeStreetLog()
            try await setUpBlinds()
            try await playBettingRound()
            
            if didInitPreflopLog {
                saveStreetLog()
            }
            
            if remainingPlayers() > 1 {
                let didInitFlopLog = initializeStreetLog()
                await dealBoard(cardsToDeal: 3)
                try await playBettingRound()
                
                if didInitFlopLog {
                    saveStreetLog()
                }
            }
            
            if remainingPlayers() > 1 {
                let didInitTurnLog = initializeStreetLog()
                await dealBoard(cardsToDeal: 1)
                try await playBettingRound()
                if didInitTurnLog {
                    saveStreetLog()
                }
            }
            
            if remainingPlayers() > 1 {
                let didInitRiverLog = initializeStreetLog()
                await dealBoard(cardsToDeal: 1)
                try await playBettingRound()
                if didInitRiverLog {
                    saveStreetLog()
                }
            }
            
            // Process round - split winnings etc
            try await processRoundEnd()
            
            
            waitingForContinueButton = true
            skipActive = false
            saveStreetLog()
            
            pot = 0
        }
        catch GameLoopError.userCancelled {
            // exit silently
            return
        }
        catch {
            Log.aiGame.error("Error in game loop: \(error, privacy: .public)")
            
           // TODO: Show game over screen and prompt user to leave
           waitingForContinueButton = true
       }
    }
    
    func processRoundEnd() async throws {
        // Case 1: Single player left auto wins
        if remainingPlayers() == 1 {
            // Winner by last standing
            guard let winnerPlayer = aiPlayers.first(
                where: { $0.lastMove(game: game) != .fold && !$0.isOutOfMoney(game: game) }
            ) else {
                Log.aiGame.error("Expected singular winner, but none found. Players: \(self.aiPlayers, privacy: .public)")
                throw GameLoopError.winnerNotFound
            }
            aiHandLog?.reachedShowdown = false
            distributePot(to: winnerPlayer, amount: pot)
            return
        }
        
        // Case 2: Showdown between multiple players
        let winnersAndDetails = try await determineWinners()
        
        let activePlayers = getActivePlayers()
        
        showdownHandNames = Dictionary(
            uniqueKeysWithValues: winnersAndDetails.player_details.map { ($0.name, $0.hand_name) }
        )
        let sidePots = determineSidePots(players: aiPlayers, remainingDetails: winnersAndDetails.player_details)
        
        for sidePot in sidePots {
            for winnerName in sidePot.winners {
                winnersThisHand.insert(winnerName)
                guard let player = activePlayers.first(where: { $0.name == winnerName }) else {
                    Log.aiGame.error("Side pot winner not found in remaining players. Winner name: \(winnerName) Remaining players: \(activePlayers.map { $0.name })")
                    throw GameLoopError.winnerNotFound
                }
                
                distributePot(to: player, amount: sidePot.splitAmount)
                Log.aiGame.info("Distributed \(sidePot.splitAmount, privacy: .public) to \(player.name, privacy: .public)")
            }
            
            // Capture showdown details if user is present in winners
            if sidePot.eligiblePlayers.contains(where: { $0.isUser }) {
                aiHandLog?.showdownPlayers = sidePot.eligiblePlayers.filter { $0.isUser }.map({ $0.name })
            }
        }
        
        isShowdown = true
        aiHandLog?.reachedShowdown = true
    }
    
    // Create a function to handle distributing potSplit to players, and stats if the player is a user
    func distributePot(to player: AIPlayer, amount: Double) {
        player.stack += amount
        if player.isUser {
            aiHandLog?.wonHand = true
            let xpEarned = max(Int(amount / 10), 5)
            aiHandLog?.xpEarned += xpEarned
            profile?.addXP(amount: xpEarned)
        }
    }
    
    @MainActor
    func playBettingRound() async throws {
        Log.aiGame.info("Betting round start game=\(self.game, privacy: .public) round=\(self.round, privacy: .public) active=\(self.getActivePlayers().count, privacy: .public) lastBet=\(self.lastPlayerBet, privacy: .public)")
        
        var highestBet = 0.0
        var turn = getFirstPlayerToActIndex()
        
        if turn == -1 {
            throw GameLoopError.invalidFirstPlayer
        }
        
        var iterations = 0
        let maxIterations = aiPlayers.count * 50 // generous
        
        // --- Initialize Betting State ---
        if round == 0 { // if preflop
            highestBet = 1.0   // big blind amount
        } else {
            highestBet = 0.0
        }
        
        // Check if any meaningful action can occur
        let activePlayers = getActivePlayers()
        let playersWithChips = activePlayers.filter { $0.stack > 0 }
        
        if playersWithChips.count < 2 {
            await sleepIfNeeded()
            round += 1
            lastPlayerBet = 0
            
            Log.aiGame.info("Not enough players with chips (someone is likely all in)")
            return
        }
        

        // --- Betting Loop ---
        while true {
            // Prevent infinite loop
            iterations += 1
            if iterations > maxIterations {
                throw GameLoopError.bettingRoundDidNotConverge
            }
            
            let currentPlayer = aiPlayers[turn]
            
            // Skip folded
            if currentPlayer.lastMove(game: game) == .fold || currentPlayer.isOutOfMoney(game: game) {
                turn = (turn + 1) % aiPlayers.count
                continue
            }
            
            let activePlayers = getActivePlayers()
            if  isBettingComplete(activePlayers: activePlayers, highestBet: highestBet) {
                break
            }
            
            var action: String = ""
            var amount: Double = 0
            
            if currentPlayer.isUser {
                if currentPlayer.stack == 0.0 {
                    turn = (turn + 1) % aiPlayers.count
                    continue
                }
                skipActive = false
                (action, amount) = await getUserDecision()
                
                // If user exits
                if action == "cancel" {
                    throw GameLoopError.userCancelled
                }
                
                // Give xp for doing a turn
                aiHandLog?.xpEarned += 1
                profile?.addXP(amount: 1)
                
                waitingForUserInput = false
            }
            else {
                (action, amount) = await makeAIDecision(ai: currentPlayer)
            }
            

            switch action.lowercased() {
            case "fold":
                if currentPlayer.isUser {
                    aiHandLog?.folds += 1
                }
                currentPlayer.fold(game: game, round: round)
            case "check":
                currentPlayer.check(game: game, round: round)
            case "call":
                call(aiPlayer: currentPlayer)
            case "raise":
                raise(aiPlayer: currentPlayer, amount: amount)
                highestBet = max(highestBet, amount) // should be impossible but just in case
            case "allin", "all in":
                let allInAmount = currentPlayer.stack + currentPlayer.lastBet(game: game, round: round)
                raise(aiPlayer: currentPlayer, amount: allInAmount)
                highestBet = max(highestBet, allInAmount)
                if currentPlayer.isUser {
                    aiHandLog?.allIns += 1
                }
            default:
                throw GameLoopError.unknownAIAction
            }
            // Advance turn
            turn = (turn + 1) % aiPlayers.count

            if remainingPlayers() == 1 {
                break
            }
        }
        
        await sleepIfNeeded()
        round += 1
        lastPlayerBet = 0
        
        Log.aiGame.info("Betting round end game=\(self.game, privacy: .public) round=\(self.round, privacy: .public) pot=\(self.pot, privacy: .public) remaining=\(self.remainingPlayers(), privacy: .public)")

    }
    
    @MainActor
    func resetGame() {
        // Handle any floating promises
        let cont = pendingUserMoveContinuation
        pendingUserMoveContinuation = nil
        cont?.resume(returning: ("cancel", 0.0))
        
        // gameplay state
        board = []
        deck.resetDeck()
        round = 0
        game = 0
        pot = 0
        lastPlayerBet = 0
        isShowdown = false
        winnersThisHand = []
        showdownHandNames = [:]
        skipActive = false

        // players
        aiPlayers = []

        // UI state
        waitingForUserInput = false
        waitingForContinueButton = false
        waitingForStartorRetryButton = true

        // error state
        isLoading = false
        errorMessage = nil
        showToast = false

        // logging
        gameLog = nil
        aiHandLog = nil
    }

    
    func dealBoard(cardsToDeal: Int) async {
        for _ in 0..<cardsToDeal {
            board.append(deck.dealCard())
        }
        // wait half a second
        await sleepIfNeeded()
    }
    
    
    func setUpBlinds() async throws {
        guard remainingPlayers() >= 2 else {
            throw GameLoopError.notEnoughPlayersForBlinds
        }
        
        let sbIndex = getActivePlayerIndexInPosition(position: "SB")
        
        if sbIndex == -1 {
            throw GameLoopError.sbNotFound
        }
        
        raise(aiPlayer: aiPlayers[sbIndex], amount: 0.5)

        let bbIndex = getNextActivePlayerIndex(startingFrom: sbIndex)
        
        if bbIndex == -1 {
            throw GameLoopError.bbNotFound
        }
        
        // Wait half a second in between
        await sleepIfNeeded()
        
        raise(aiPlayer: aiPlayers[bbIndex], amount: 1.0)
    }
    
    func determineSidePots(players: [AIPlayer], remainingDetails: [PlayerDetails]) -> [SidePot] {
        
        // Lookup between playerName and score
        let scoreByName: [String: Int] = Dictionary(
            uniqueKeysWithValues: remainingDetails.map { ($0.name, $0.score) }
        )
        
        // Lookup between player and contribution (0 shouldn't even be possible here)
        let contribPairs: [(player: AIPlayer, contrib: Double)] =
            players
            .map { ($0, $0.totalContribution(game: game)) }
            .filter { $0.1 > 0 }

        guard !contribPairs.isEmpty else { return [] }

        let levels = Array(Set(contribPairs.map { $0.contrib })).sorted() // ascending
        var pots: [SidePot] = []
        var prevLevel = 0.0

        for level in levels {
            let delta = level - prevLevel
            if delta <= 0 { continue }

            let contributors = contribPairs.filter { $0.contrib >= level }.map { $0.player }
            let potAmount = delta * Double(contributors.count)

            let eligiblePlayers = contributors.filter { $0.lastMove(game: game) != .fold }
            // eligible: contributors that did not fold
            let eligibleNames = eligiblePlayers.map { $0.name }
            
            let eligibleWithScores: [(name: String, score: Int)] = eligibleNames.compactMap { name in
                guard let s = scoreByName[name] else { return nil }
                return (name, s)
            }
            
            let bestScore = eligibleWithScores.map(\.score).min()!
            let winners = eligibleWithScores.filter { $0.score == bestScore }.map(\.name)
            
            let split = winners.isEmpty ? 0.0 : (potAmount / Double(winners.count))

            pots.append(SidePot(amount: potAmount, eligiblePlayers: eligiblePlayers, winners: winners, splitAmount: split))
            prevLevel = level
        }

        return pots
    }
    
    func isBettingComplete(
        activePlayers: [AIPlayer],
        highestBet: Double
    ) -> Bool {
        activePlayers.allSatisfy { player in
            let playerBet = player.lastBet(game: game, round: round)
            let playerMove = player.lastMoveForRound(game: game, round: round)

            if player.stack == 0 { return true } // all-in
            if highestBet != 0 && playerBet == highestBet { return true } // matched
            if playerMove == .check && highestBet == 0 { return true }     // checked and no bet
            return false
        }
    }
    
    func rotatePositions() {
        // Save the last player's position to wrap around
        let lastPosition = aiPlayers.last!.position
        
        // Shift positions from end to start
        for i in stride(from: aiPlayers.count - 1, through: 1, by: -1) {
            aiPlayers[i].position = aiPlayers[i - 1].position
        }
        
        // Set first player's position to last player's old position
        aiPlayers[0].position = lastPosition
    }
    
    @MainActor
    func makeAIDecision(ai: AIPlayer) async -> (String, Double) {
        let action = await getAIMove(ai: ai)
        var amount = 0.0
        
        if action == "raise" {
            let callCost = max(0, lastPlayerBet - ai.lastBet(game: game, round: round))
            if ai.stack < callCost {
                return ("fold", 0.0)
            }
            else if ai.stack == callCost {
                return ("call", lastPlayerBet)
            }
            let maxRaiseTo = ai.lastBet(game: game, round: round) + ai.stack

            let desiredRaiseTo =
                lastPlayerBet + (Double.random(in: 1.0...10.0) * 2).rounded() / 2

            if desiredRaiseTo >= maxRaiseTo {
                // Treat this as all-in (raise-to max)
                return ("allin", maxRaiseTo)
            }

            amount = desiredRaiseTo
        }
        else if action == "call" {
            amount = lastPlayerBet
        }
        
        return (action, amount)
    }
    
    // MARK: Helper functions for processing
    func raise(aiPlayer: AIPlayer, amount: Double) {
        let raiseAmount = min(amount, aiPlayer.stack + aiPlayer.lastBet(game: game, round: round)) // Restrict user to never go over their stack
        let potIncrease = aiPlayer.raise(amount: raiseAmount, game: game, round: round)
        pot += potIncrease
        lastPlayerBet = max(lastPlayerBet, raiseAmount) // should never go down
        
        if aiPlayer.isUser {
            // Need to log this in the data
            aiHandLog?.raises += 1
            aiHandLog?.totalRaised += raiseAmount
        }
    }
    
    func call(aiPlayer: AIPlayer) {
        let callAmount = min(lastPlayerBet, aiPlayer.stack + aiPlayer.lastBet(game: game, round: round)) // Can't bet more than you have
        let potIncrease = aiPlayer.call(amount: callAmount, game: game, round: round)
        pot += potIncrease
        
        if aiPlayer.isUser {
            // Need to log this in the data
            aiHandLog?.calls += 1
            aiHandLog?.totalCalled += callAmount
        }
    }
    
    func remainingPlayers() -> Int {
        return getActivePlayers().count
    }
    
    func getActivePlayers() -> [AIPlayer] {
        aiPlayers.filter { $0.lastMove(game: game) != .fold && !$0.isOutOfMoney(game: game) }
    }
    
    /// Gets the first player to act in the round
    /// - Returns: index of the first active player
    func getFirstPlayerToActIndex() -> Int {
        guard !aiPlayers.isEmpty else { return -1 }
        
        let startingPosition = round == 0 ? "UTG" : "SB"
        return getActivePlayerIndexInPosition(position: startingPosition)
    }
    
    /// Gets the next active player index in a given position
    /// - Parameter position: string such as "BB"
    /// - Returns: index of the next active player
    func getActivePlayerIndexInPosition(position: String) -> Int {
        // Starting index
        let referenceIndex = aiPlayers.firstIndex(where: { $0.position == position }) ?? 0

        for i in 0...aiPlayers.count {
            let nextIndex = (referenceIndex + i) % aiPlayers.count
            let player = aiPlayers[nextIndex]
            
            // Skip all folded players and players out of money
            if player.lastMove(game: game) != .fold && !player.isOutOfMoney(game: game) {
                return nextIndex
            }
        }
        
        return -1
    }
    
    func getNextActivePlayerIndex(startingFrom index: Int) -> Int {
        guard !aiPlayers.isEmpty else { return -1 }

        for offset in 1..<aiPlayers.count {
            let nextIndex = (index + offset) % aiPlayers.count
            let player = aiPlayers[nextIndex]

            if player.lastMove(game: game) != .fold &&
               !player.isOutOfMoney(game: game) {
                return nextIndex
            }
        }

        return -1
    }
    
    func setAPIManager(authManager: AuthManager) {
        self.vsAiAPI = VsAIAPI(authManager: authManager)
    }
    
    // MARK: UI functions determine what buttons to display to the user
    func getUserDefaultBets() -> [Int] {
        guard let user = aiPlayers.first(where: { $0.isUser }) else { return [] }

        let defaultAmounts = [2.0, 5.0, 10.0, 20.0]

        return defaultAmounts.compactMap { base -> Int? in
            let total = base + lastPlayerBet
            let rounded = Int(total)
            return rounded <= Int(user.stack) ? rounded : nil
        }
    }
    
    func getPossibleActions() -> [String] {
        guard let user = aiPlayers.first(where: { $0.isUser }) else { return [] }
        var allActions = ["Check", "Fold", "Call", "Raise"] // , "All In"] - this is one scenario
        
        if lastPlayerBet == 0 {
            // remove Fold, Call
            allActions.removeAll(where: { $0 == "Fold" || $0 == "Call" })
        } else {
            // Remove check
            allActions.removeAll(where: { $0 == "Check" })
        }
        
        if lastPlayerBet > user.stack {
            allActions = ["Fold", "All In"]
        }
        
        return allActions
    }
    
    // MARK: User Input handling
    func handleUserMove(move: (String, Double)) {
        guard let continuation = pendingUserMoveContinuation else { fatalError("No continuation to resume") }
        continuation.resume(returning: move)
        pendingUserMoveContinuation = nil
    }
    
    func getUserDecision() async -> (String, Double) {
        waitingForUserInput = true
        return await withCheckedContinuation { continuation in
            pendingUserMoveContinuation = continuation
        }
        
    }
    
    // MARK: - Functions to create list of players
    
    ///  Combines AI Player names from the server to the list of AIPlayers
    /// - Parameter aiNames: List of full names and names
    /// - Returns: List of complete AIPlayers
    func createRandomPlayers(aiNames: [FetchPlayerResponse]) -> [AIPlayer] {
        guard
            let positionList = RangeHelper.positionsOrderGlobal[tableSize],
            let playerCount = Int(tableSize),
            aiNames.count == playerCount - 1
        else {
            Log.aiGame.error("Invalid AI names count for table size")
            return []
        }
        
        let userPosition = positionList.randomElement()!
        
        let players = createAndReorderPlayers(startingPosition: userPosition)
        
        // User is always first
        players[0].name = "YOU"
        players[0].isUser = true
        
        for (aiIndex, aiName) in aiNames.enumerated() {
            let playerIndex = aiIndex + 1  // shift for HERO at 0
            guard playerIndex < players.count else { break }
            players[playerIndex].name = aiName.name
            players[playerIndex].fullName = aiName.full_name
        }
        
        return players
    }
    
    /// Creates a list of players in order where the passed in position is first
    /// - Parameter startingPosition: The position to sit at 0
    /// - Returns: List of players tableSize long
    func createAndReorderPlayers(startingPosition: String) -> [AIPlayer] {
        let positionList = RangeHelper.positionsOrderGlobal[tableSize]!
        var playersReordered: [AIPlayer] = []
        var index = positionList.firstIndex(of: startingPosition)!
        let playerCount = Int(tableSize)!
        
        for _ in 1...playerCount {
            let player: AIPlayer = AIPlayer(name: "", fullName: "", position: positionList[index], stack: 100.0)
            playersReordered.append(player)
            index = (index + 1) % playerCount
            
        }
         
        return playersReordered
    }
    
    func getAIPlayerNames() async -> [FetchPlayerResponse] {
        guard let api = vsAiAPI else {
            errorMessage = "Internal Error"
            showToast = true
            return []
        }

        do {
            return try await api.fetchAIPlayers(tableSize: tableSize)
        } catch {
            Log.network.error("Failed to fetch AI players from API: \(error, privacy: .public)")
            errorMessage = "Failed to fetch AI players"
            showToast = true
            return []
        }
    }
    
    func getAIMove(ai: AIPlayer) async -> String {
        guard let api = vsAiAPI else {
            errorMessage = "Internal Error"
            showToast = true
            return "fold"
        }
        
        let potOdds: Double
        if pot == 0 {
            potOdds = 0
        } else {
            potOdds = ai.lastBet(game: game, round: round) / pot
        }
        
        var possibleMoves = ["call", "raise", "fold"]
        if lastPlayerBet == 0 {
            possibleMoves = ["check", "raise"]
        }
        
        do {
            let startTime = Date()
            let response = try await api.fetchAiDecision(
                aiName: ai.name,
                aiHole: ai.hand.map { $0.toString() },
                board: board.map { $0.toString() },
                potOdds: potOdds,
                opponentCount: remainingPlayers(),
                possibleMoves: possibleMoves
            )
            let elapsed = Date().timeIntervalSince(startTime)
            await sleepRemaining(targetSeconds: 0.8, elapsedSeconds: elapsed)
            return response
        } catch {
            Log.network.error("Failed to retrieve AI move from API: \(error, privacy: .public)")
            errorMessage = "Failed to get AI move"
            showToast = true
            return "fold"
        }
    }
    
    func determineWinners() async throws -> DetermineWinnerResponse {
        let playersLeft = aiPlayers.filter({ $0.lastMove(game: game) != .fold && !$0.isOutOfMoney(game: game)})
        
        guard let api = vsAiAPI else {
            errorMessage = "Internal Error"
            showToast = true
            throw GameLoopError.apiNotSet
        }
        
        do {
            let startTime = Date()
            let response = try await api.processWinners(playersLeft: playersLeft, board: board.map { $0.toString() })
            let elapsed = Date().timeIntervalSince(startTime)
            await sleepRemaining(targetSeconds: 0.8, elapsedSeconds: elapsed)
            return response
        } catch {
            Log.network.error("Failed to retrieve winners from API: \(error, privacy: .public)")
            errorMessage = "Failed to determine winners"
            showToast = true
            throw GameLoopError.winnerNotFound
        }
    }
    
    @MainActor
    func sleepIfNeeded() async {
        guard !skipActive else { return }
        await sleepFunction(sleepTime)
    }

    @MainActor
    private func sleepRemaining(targetSeconds: TimeInterval, elapsedSeconds: TimeInterval) async {
        guard !skipActive else { return }
        let remaining = max(0, targetSeconds - elapsedSeconds)
        let nanoseconds = UInt64(remaining * 1_000_000_000)
        guard nanoseconds > 0 else { return }
        await sleepFunction(nanoseconds)
    }
    
    var sleepFunction: (UInt64) async -> Void = { nanoseconds in
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
