import Observation
import Foundation
import SwiftData

@Observable
class AIGameManager {
    // Data saving info
    var context: ModelContext?
    var profile: Profile? = nil
    var gameLog: Game?
    var aiGameLog: AIGameLog?
    // Game state variables
    var aiPlayers: [AIPlayer] = []
    var pot = 0.0
    var round = 0 // Preflop = 0, Flop = 1, Turn = 2, River = 3
    var game = 0 // Iterates upwards
    var lastPlayerBet = 0.0
    let deck = Deck() // Create a shared deck
    var board: [Card] = []
    
    // Used to handle user input
    var waitingForUserInput: Bool = false
    var pendingUserMoveContinuation: CheckedContinuation<(String, Double), Never>?
    
    // User start/continue input buttons
    var waitingForContinueButton: Bool = false
    var waitingForStartButton: Bool = false
    
    // Error handling
    var isLoading = true
    var errorMessage: String?
    var showToast = false

    // User configs
    let gameplaySpeed: Double
    let testingMode: Bool
    let tableSize: String = "6"
    
    // Computed for simplicity
    var canSkip: Bool {
        !skipActive &&
        !waitingForUserInput &&
        !waitingForStartButton &&
        !waitingForContinueButton &&
        !isLoading
    }
    
    var skipActive: Bool = false

    init(gameplaySpeed: Double = 3, testingMode: Bool = false) {
        self.gameplaySpeed = gameplaySpeed
        self.testingMode = testingMode
    }
    
    func populateAINames() async {
        isLoading = true
        let aiNames = await fetchAIPlayers()
        aiPlayers = createRandomPlayers(aiNames: aiNames)
        isLoading = false
        waitingForStartButton = true
    }

    func startGame() async {
        gameLog = Game(gameType: .aiVsHuman)
        context?.insert(gameLog!)
        
        // Create deck and deal cards
        for player in aiPlayers {
            player.hand.append(deck.dealCard())
            player.hand.append(deck.dealCard())
        }
        
        try? await Task.sleep(nanoseconds: 250_000_000)
        await gameLoop()
    }
    
    func startNextGame() async {
        // Reset necessarry variables and trigger a new hand deal out
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
    func initializeStreetLog() {
        if let currentGameLog = gameLog {
            let street = Street.allCases[round]
            guard let user = aiPlayers.first(where: { $0.isUser }) else { fatalError("Could not find user") }
            let board = board.map { $0.toString() }
            aiGameLog = AIGameLog(hand: user.hand.handToString(), board: board, street: street, game: currentGameLog)
        } else {
            print("No game log found - No data will be saved")
        }
    }
    
    @MainActor
    func saveStreetLog() {
        if let currentLog = aiGameLog {
            currentLog.pot = pot
            context?.insert(currentLog)
            do {
                try context?.save()
            } catch {
                print("Failed to save game: \(error)")
            }
        } else {
            print("No game log found - No data to be saved")
        }
    }
    
    @MainActor
    func gameLoop() async {
        initializeStreetLog()
        await setUpBlinds()
        await playBettingRound()
        saveStreetLog()
        if remainingPlayers() > 1 {
            initializeStreetLog()
            await dealBoard(cardsToDeal: 3)
            await playBettingRound()
            saveStreetLog()
        }
        
        if remainingPlayers() > 1 {
            initializeStreetLog()
            await dealBoard(cardsToDeal: 1)
            await playBettingRound()
            saveStreetLog()
        }
        
        if remainingPlayers() > 1 {
            initializeStreetLog()
            await dealBoard(cardsToDeal: 1)
            await playBettingRound()
            saveStreetLog()
        }
        
        // Wait half a second
        if !skipActive {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        var winnerNames: [String] = []
        if remainingPlayers() > 1 {
            let winnersList = await determineWinners()
            winnerNames = winnersList
        } else {
            let singularWinner = aiPlayers.first(where: { $0.lastMove(game: game) != .fold && !$0.isOutOfMoney(game: game) })
            winnerNames = [singularWinner!.name]
        }
        
        let playersLeft = aiPlayers.filter({ $0.lastMove(game: game) != .fold && !$0.isOutOfMoney(game: game)})
        // set aiGameLog?.reachedShowdown to be true if user hasn't folded
        if playersLeft.first(where: { $0.isUser }) != nil {
            aiGameLog?.reachedShowdown = true
        }
        
        processRoundEnd(winners: winnerNames)
        waitingForContinueButton = true
        skipActive = false
        
        saveStreetLog()
    }
    
    @MainActor
    func playBettingRound() async {
        print("=== 🃏 STARTING BETTING ROUND ===")
        

        let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s

        var highestBet = 0.0
        var turn = getFirstPlayerToAct()
        // --- Initialize Betting State ---
        if round == 0 { // if preflop
            highestBet = 1.0   // big blind amount
            
        } else {
            highestBet = 0.0
        }

        // --- Betting Loop ---
        while true {
            let currentPlayer = aiPlayers[turn]
            // Skip folded
            if currentPlayer.lastMove(game: game) == .fold {
                turn = (turn + 1) % Int(tableSize)!
                continue
            }
            
            let activePlayers = aiPlayers.filter { $0.lastMove(game: game) != .fold }
            let bettingComplete = activePlayers.allSatisfy { player in
                let playerBet = player.lastBet(game: game, round: round)
                let playerMove = player.lastMoveForRound(game: game,  round: round)
                
                // 1. Player is all-in → treat as matched
                if player.stack == 0 { return true }
                
                // 2. Player has matched the highest bet → OK
                if highestBet != 0 && playerBet == highestBet { return true }
                
                // 3. Player checked → only OK if highestBet == 0
                if playerMove == .check && highestBet == 0 { return true }
                
                // Otherwise, player still needs to act
                return false
            }
            
            if bettingComplete {
                break
            }
            
            var action: String = ""
            var amount: Double = 0
            
            if currentPlayer.isOutOfMoney(game: game) {
                turn = (turn + 1) % Int(tableSize)!
                continue
            }
            
            if currentPlayer.isUser {
                skipActive = false
                if currentPlayer.stack == 0.0 {
                    turn = (turn + 1) % Int(tableSize)!
                    continue
                }
                (action, amount) = await getUserDecision()
                
                // Give xp for doing a turn
                aiGameLog?.xpEarned += 1
                profile?.addXP(amount: 1)
                
                waitingForUserInput = false
            }
            else {
                if !skipActive {
                    // Simulate thinking delay
                    try? await Task.sleep(nanoseconds: sleepTime)
                }
                (action, amount) = makeAIDecision(ai: currentPlayer)
            }
            

            switch action {
            case "fold":
                if currentPlayer.isUser {
                    aiGameLog?.folds += 1
                }
                currentPlayer.fold(game: game, round: round)
            case "check":
                currentPlayer.check(game: game, round: round)
            case "call":
                call(aiPlayer: currentPlayer)

            case "raise":
                raise(aiPlayer: currentPlayer, amount: amount)
                highestBet = amount
            case "allin":
                let allInAmount = currentPlayer.stack + currentPlayer.lastBet(game: game, round: round)
                raise(aiPlayer: currentPlayer, amount: allInAmount)
                highestBet = max(highestBet, allInAmount)
                if currentPlayer.isUser {
                    aiGameLog?.allIns += 1
                }
            default:
                print("⚠️ Unknown action from AI: \(action)")
            }
            // Advance turn
            turn = (turn + 1) % Int(tableSize)!

            // Check if only one player remains
            let activeCount = aiPlayers.filter { $0.lastMove(game: game) != .fold }.count
            if activeCount == 1 {
                break
            }
        }
        
        if !skipActive {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        round += 1
        lastPlayerBet = 0
    }
    
    func resetGame() {
        board = []
        deck.resetDeck() // Creates new shuffled deck
        round = 0
        pot = 0.0
    }
    
    func dealBoard(cardsToDeal: Int) async {
        for _ in 0..<cardsToDeal {
            board.append(deck.dealCard())
        }
        // wait half a second
        if !skipActive {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    
    
    func setUpBlinds() async {
        let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s
        let sbIndex = getActivePlayerInPosition(position: "SB")
        
        raise(aiPlayer: aiPlayers[sbIndex], amount: 0.5)

        let bbIndex = getActivePlayerInPosition(position: "BB")
        if !skipActive {
            try? await Task.sleep(nanoseconds: sleepTime)
        }
        
        raise(aiPlayer: aiPlayers[bbIndex], amount: 1.0)
    }
    
    func processRoundEnd(winners: [String]) {
        let potSplit = pot / Double(winners.count)
        if aiGameLog?.reachedShowdown == true { aiGameLog?.wonHand = false }
        
        for playerName in winners {
            guard let player = aiPlayers.first(where: { $0.name == playerName }) else { continue }
            player.stack += potSplit
            if player.isUser {
                aiGameLog?.wonHand = true
                let xpEarned = max(Int(potSplit / 10), 5)
                aiGameLog?.xpEarned += xpEarned
                profile?.addXP(amount: xpEarned)
            }
        }
        
        if aiGameLog?.reachedShowdown == true {
            aiGameLog?.showdownPlayers = winners.filter { $0 != "Hero" }
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
    
    // TODO: Implement real ai logic with backend
    func makeAIDecision(ai: AIPlayer) -> (String, Double) {
        var actions = ["call", "raise", "fold"]
        if lastPlayerBet == 0 {
            actions = ["check", "raise"]
        }
        let action = actions.randomElement()!
        var amount = 0.0
        
        if action == "raise" {
            if ai.stack <= lastPlayerBet + ai.lastBet(game: game, round: round) {
                return ("fold", 0.0)
            }
            amount = lastPlayerBet + (Double.random(in: 1.0...10.0) * 2).rounded() / 2
            
        } else if action == "call" {
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
            aiGameLog?.raises += 1
            aiGameLog?.totalRaised += raiseAmount
        }
    }
    
    func call(aiPlayer: AIPlayer) {
        let callAmount = min(lastPlayerBet, aiPlayer.stack + aiPlayer.lastBet(game: game, round: round)) // Can't bet more than you have
        let potIncrease = aiPlayer.call(amount: callAmount, game: game, round: round)
        pot += potIncrease
        
        if aiPlayer.isUser {
            // Need to log this in the data
            aiGameLog?.calls += 1
            aiGameLog?.totalCalled += callAmount
        }
    }
    
    func remainingPlayers() -> Int {
        return aiPlayers.filter { $0.lastMove(game: game) != .fold && !$0.isOutOfMoney(game: game)}.count
    }
    
    func getFirstPlayerToAct() -> Int {
        guard !aiPlayers.isEmpty else { return -1 }

        if round == 0 { // If preflop find BB (Not utg since we iterate in the loop later)
            return getActivePlayerInPosition(position: "UTG")
            // return playerCount == "6" ? aiPlayers.firstIndex(where: { $0.position == "UTG" }) ?? 0 : aiPlayers.firstIndex(where: { $0.position == "UTG1" }) ?? 0
        }
            
        return aiPlayers.firstIndex(where: { $0.position == "SB" }) ?? 0
    }
    
    func getActivePlayerInPosition(position: String) -> Int {
        let referenceIndex = aiPlayers.firstIndex(where: { $0.position == position }) ?? 0

        // Start from the next player clockwise
        for i in 0...aiPlayers.count {
            let nextIndex = (referenceIndex + i) % aiPlayers.count
            let player = aiPlayers[nextIndex]
            if player.lastMove(game: game) != .fold && !player.isOutOfMoney(game: game) && player.lastBet(game: game, round: round) == 0.0 {
                return nextIndex
            }
        }
        
        return -1
    }
    
    // MARK: Needed for saving data locally
    @MainActor
    func setContext(_ context: ModelContext) {
        self.context = context
    }
    
    func setProfile(profile: Profile) {
        self.profile = profile
        print("Profile set to: \(profile.username)")
    }
    
    
    
    // MARK: UI functions determine what buttons to display to the user
    func getUserDefaultBets() -> [Int] {
        guard let user = aiPlayers.first(where: { $0.isUser }) else { return [] }

        let defaultAmounts = [2.0, 5.0, 10.0, 20.0]

        return defaultAmounts.compactMap { base -> Int? in
            let total = base + lastPlayerBet
            let rounded = Int(total.rounded())
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
            allActions = ["All In"]
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
    
    // MARK: Functions to create list of players
    func createRandomPlayers(aiNames: [FetchPlayerResponse]) -> [AIPlayer] {
        let userPosition = RangeHelper.positionsOrderGlobal[tableSize]!.randomElement()!
        
        let aiPlayers = createAndReorderPlayers(playerPosition: userPosition)
        // Loop through aiPlayers and assign names (start at 2nd entry)
        aiPlayers[0].name = "HERO"
        aiPlayers[0].isUser = true
        
        for i in 1..<aiPlayers.count {
            if i - 1 < aiNames.count {
                aiPlayers[i].name = aiNames[i - 1].name
                aiPlayers[i].fullName = aiNames[i - 1].full_name
            }
        }
        
        return aiPlayers
    }
    
    func createAndReorderPlayers(playerPosition: String) -> [AIPlayer] {
        let positionList = RangeHelper.positionsOrderGlobal[tableSize]!
        var playersReordered: [AIPlayer] = []
        var index = positionList.firstIndex(of: playerPosition)!
        let playerCount = Int(tableSize)!
        
        for _ in 1...playerCount {
            let player: AIPlayer = AIPlayer(name: "", fullName: "", position: positionList[index], stack: 100.0)
            playersReordered.append(player)
            index = (index + 1) % playerCount
            
        }
         
        return playersReordered
    }
    
    
    struct FetchPlayerResponse: Codable {
        let name: String
        let full_name: String
    }
    
    // TODO: Move all these to a different file
    func fetchAIPlayers() async -> [FetchPlayerResponse] {
        let apiPrefix = "https://pokerapi-887971801517.us-east4.run.app"
        // let apiPrefix = "http://127.0.0.1:8000"
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(apiPrefix)/api/ai/players?table_size=\(tableSize)") else {
            errorMessage = "Invalid URL"
            showToast = true
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Server error"
                showToast = true
                return []
            }

            let decoded = try JSONDecoder().decode([FetchPlayerResponse].self, from: data)
            return decoded

        } catch {
            errorMessage = "Failed to fetch AI players"
            showToast = true
            return []
        }
    }
    
    struct WinnerRequestPlayerDetails: Codable {
        let name: String
        let hand: [String]
    }

    struct DetermineWinnerRequest: Codable {
        let players: [WinnerRequestPlayerDetails]
        let board: [String]
    }

    struct DetermineWinnerResponse: Codable {
        struct Result: Codable {
            let name: String
            let hand: [String]
            let score: Int
            let hand_name: String
        }

        let winners: [String]
        let results: [Result]
    }
    
    func determineWinners() async -> [String] {
        let apiPrefix = "https://pokerapi-887971801517.us-east4.run.app"
        // let apiPrefix = "http://127.0.0.1:8000"
        guard let url = URL(string: "\(apiPrefix)/api/ai/determine-winner") else {
            errorMessage = "Invalid URL"
            showToast = true
            return []
        }
        
        let playersLeft = aiPlayers.filter({ $0.lastMove(game: game) != .fold && !$0.isOutOfMoney(game: game)})
        let players = playersLeft.map { player in
            WinnerRequestPlayerDetails(name: player.name, hand: player.hand.map { $0.toString() })
        }
        let requestBody = DetermineWinnerRequest(players: players, board: board.map { $0.toString() })

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Server error"
                showToast = true
                return []
            }
            
            let decoded = try JSONDecoder().decode(DetermineWinnerResponse.self, from: data)
            
            // Example usage:
            for result in decoded.results {
                print("\(result.name): \(result.hand_name) (\(result.score))")
            }
            
            // Optionally update your AI player list if desired
            return decoded.winners
            
        } catch {
            errorMessage = "Failed to determine winners: \(error.localizedDescription)"
            showToast = true
            return []
        }
        
    }
}
