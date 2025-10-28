import Observation
import Foundation

@Observable
class AIGameManager {
    // Game state variables
    var aiPlayers: [AIPlayer] = []
    var pot = 0.0
    var round = 0 // Preflop = 0, Flop = 1, Turn = 2, River = 3
    var lastPlayerBet = 0.0
    let deck = Deck() // Create a shared deck
    var board: [Card] = []
    
    // Used to handle user input
    var waitingForUserInput: Bool = false
    var pendingUserMoveContinuation: CheckedContinuation<(String, Double), Never>?
    
    var isLoading = true
    var errorMessage: String?

    // User configs
    let gameplaySpeed: Double
    let testingMode: Bool
    let tableSize: String = "6"

    init(gameplaySpeed: Double = 3, testingMode: Bool = false) {
        self.gameplaySpeed = gameplaySpeed
        self.testingMode = testingMode
    }

    func startGame() async {
        isLoading = true
        let aiNames = await fetchAIPlayers()
        aiPlayers = createRandomPlayers(aiNames: aiNames)
        
        // Create deck and deal cards
        for player in aiPlayers {
            player.hand.append(deck.dealCard())
            player.hand.append(deck.dealCard())
        }
        isLoading = false
        
        // Start the game loop here
        await gameLoop()
    }
    
    func gameLoop() async {
        await setUpBlinds()
        await playBettingRound()
        if remainingPlayers() > 1 {
            await dealBoard(cardsToDeal: 3)
            await playBettingRound()
        }
        
        if remainingPlayers() > 1 {
            await dealBoard(cardsToDeal: 1)
            await playBettingRound()
        }
        
        if remainingPlayers() > 1 {
            await dealBoard(cardsToDeal: 1)
            await playBettingRound()
        }
        
        // Wait half a second
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        var winnerNames: [String] = []
        if remainingPlayers() > 1 {
            let winnersList = await determineWinners()
            winnerNames = winnersList
        } else {
            let singularWinner = aiPlayers.first(where: { $0.lastMove() != .fold })
            winnerNames = [singularWinner!.name]
        }
        
        processRoundEnd(winners: winnerNames)
    }
    
    func playBettingRound() async {
        print("=== 🃏 STARTING BETTING ROUND ===")

        let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s

        var highestBet = 0.0
        var lastAggressorIndex = 0
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
            print("\n---> Player \(currentPlayer.name) (\(currentPlayer.position))'s turn")

            // Skip folded
            if currentPlayer.lastMove() == .fold {
                print("Skipping \(currentPlayer.name): already folded.")
                turn = (turn + 1) % Int(tableSize)!
                continue
            }

            // Check if everyone has matched the highest bet
            if currentPlayer.lastBet(round: round) == highestBet && turn == lastAggressorIndex {
                print("✅ Betting complete: everyone has matched the highest bet.")
                break
            }
            
            var action: String = ""
            var amount: Double = 0
            
            if currentPlayer.isUser {
                print("Waiting for user input...")
                if currentPlayer.stack == 0.0 {
                    print("🟨 \(currentPlayer.name) is all-in. Skipping turn.")
                    turn = (turn + 1) % Int(tableSize)!
                    continue
                }
                (action, amount) = await getUserDecision()
                waitingForUserInput = false
            }
            else {
                // Simulate thinking delay
                try? await Task.sleep(nanoseconds: sleepTime)

                print("Making AI decision for \(currentPlayer.name)...")
                (action, amount) = makeAIDecision(ai: currentPlayer)
            }
            

            switch action {
            case "fold":
                print("🟥 \(currentPlayer.name) folds.")
                currentPlayer.fold(round: round)

            case "call":
                print("🟨 \(currentPlayer.name) calls")
                call(aiPlayer: currentPlayer)

            case "raise":
                print("🟩 \(currentPlayer.name) raises to \(amount)!")
                raise(aiPlayer: currentPlayer, amount: amount)
                highestBet = amount
                lastAggressorIndex = turn
                print("New highest bet = \(highestBet). Last aggressor = \(currentPlayer.name)")
            case "allin":
                let allInAmount = currentPlayer.stack + currentPlayer.lastBet(round: round)
                print("🟨 \(currentPlayer.name) goes all-in for \(allInAmount)!")
                raise(aiPlayer: currentPlayer, amount: allInAmount)
                highestBet = max(highestBet, allInAmount)
                lastAggressorIndex = turn
            default:
                print("⚠️ Unknown action from AI: \(action)")
            }
            // Advance turn
            turn = (turn + 1) % Int(tableSize)!

            // Check if only one player remains
            let activeCount = aiPlayers.filter { $0.lastMove() != .fold }.count
            if activeCount == 1 {
                print("🏁 Only one player remains. Game ends.")
                break
            }
        }

        print("=== ROUND COMPLETE ===")
        round += 1
        lastPlayerBet = 0
    }
    
    func dealBoard(cardsToDeal: Int) async {
        print("=== 🃏 DEALING ===")
        for _ in 0..<cardsToDeal {
            board.append(deck.dealCard())
        }
        // wait half a second
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    func getFirstPlayerToAct() -> Int {
        guard !aiPlayers.isEmpty else { return -1 }

        // Find reference index
        let referenceIndex: Int
        if round == 0 { // If preflop return utg
            return aiPlayers.firstIndex(where: { $0.position == "UTG" }) ?? 0
            // return playerCount == "6" ? aiPlayers.firstIndex(where: { $0.position == "UTG" }) ?? 0 : aiPlayers.firstIndex(where: { $0.position == "UTG1" }) ?? 0
        } else {
            referenceIndex = aiPlayers.firstIndex(where: { $0.position == "BTN" }) ?? 0
        }

        // Start from the next player clockwise
        for i in 1...aiPlayers.count {
            let nextIndex = (referenceIndex + i) % aiPlayers.count
            if aiPlayers[nextIndex].lastMove() != .fold {
                return nextIndex
            }
        }

        return -1 // fallback if everyone folded
    }
    
    func setUpBlinds() async {
        let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s
        var turn = aiPlayers.firstIndex(where: { $0.position == "SB" })!

        print("Small Blind is position: \(aiPlayers[turn].name)")

        // --- Handle blinds ---
        try? await Task.sleep(nanoseconds: sleepTime)
        print("Posting Small Blind...")
        raise(aiPlayer: aiPlayers[turn], amount: 0.5)
        turn = (turn + 1) % Int(tableSize)!

        try? await Task.sleep(nanoseconds: sleepTime)
        print("Posting Big Blind...")
        raise(aiPlayer: aiPlayers[turn], amount: 1.0)
        turn = (turn + 1) % Int(tableSize)!
    }
    
    func remainingPlayers() -> Int {
        return aiPlayers.filter { $0.lastMove() != .fold }.count
    }
    
    func processRoundEnd(winners: [String]) {
        let potSplit = pot / Double(winners.count)
        for playerName in winners {
            guard let player = aiPlayers.first(where: { $0.name == playerName }) else { continue }
            player.stack += potSplit
            pot -= potSplit
        }
        
        print("=== ROUND END ===")
        print("Winners: \(winners)")
        print("Pot: \(pot)")
        print("Player stacks:")
        for player in aiPlayers {
            print("🟨 \(player.name): \(player.stack)")
        }
    }
    
    func getUserDefaultBets() -> [Int] {
        guard let user = aiPlayers.first(where: { $0.isUser }) else { return [] }

        let defaultAmounts = [2.0, 5.0, 10.0, 20.0]

        return defaultAmounts.compactMap { base -> Int? in
            let total = base + lastPlayerBet
            let rounded = Int(total.rounded())
            return rounded <= Int(user.stack) ? rounded : nil
        }
    }
    
    func handleUserMove(move: (String, Double)) {
        guard let continuation = pendingUserMoveContinuation else { fatalError("No continuation to resume") }
        continuation.resume(returning: move)
        pendingUserMoveContinuation = nil
    }

    
    // For now just randomly return a move and bet amount
    func makeAIDecision(ai: AIPlayer) -> (String, Double) {
        var actions = ["call", "raise", "fold"]
        if lastPlayerBet == 0 {
            actions = ["fold", "raise"]
        }
        let action = actions.randomElement()!
        var amount = 0.0
        
        if action == "raise" {
            if ai.stack <= lastPlayerBet + ai.lastBet(round: round) {
                return ("fold", 0.0)
            }
            amount = lastPlayerBet + (Double.random(in: 1.0...10.0) * 2).rounded() / 2
            
        } else if action == "call" {
            amount = lastPlayerBet
        }
        
        return (action, amount)
    }
    
    func getUserDecision() async -> (String, Double) {
        waitingForUserInput = true
        return await withCheckedContinuation { continuation in
            pendingUserMoveContinuation = continuation
        }
        
    }
    
    func raise(aiPlayer: AIPlayer, amount: Double) {
        let raiseAmount = min(amount, aiPlayer.stack + aiPlayer.lastBet(round: round)) // Restrict user to never go over their stack
        let potIncrease = aiPlayer.raise(amount: raiseAmount, round: round)
        pot += potIncrease
        lastPlayerBet = max(lastPlayerBet, raiseAmount) // should never go down
    }
    
    func call(aiPlayer: AIPlayer) {
        let callAmount = min(lastPlayerBet, aiPlayer.stack + aiPlayer.lastBet(round: round)) // Can't bet more than you have
        let potIncrease = aiPlayer.call(amount: callAmount, round: round)
        pot += potIncrease
    }

    func fetchAIPlayers() async -> [String] {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "http://127.0.0.1:8000/api/ai/players?table_size=\(tableSize)") else {
            errorMessage = "Invalid URL"
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Server error"
                return []
            }

            let decoded = try JSONDecoder().decode([String].self, from: data)
            return decoded

        } catch {
            errorMessage = "Failed to fetch AI players: \(error.localizedDescription)"
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
        guard let url = URL(string: "http://127.0.0.1:8000/api/ai/determine-winner") else {
            errorMessage = "Invalid URL"
            return []
        }
        
        let players = aiPlayers.map { player in
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
                return []
            }
            
            let decoded = try JSONDecoder().decode(DetermineWinnerResponse.self, from: data)
            
            // Example usage:
            print("🏆 Winners:", decoded.winners)
            var winners: [String] = []
            for result in decoded.results {
                print("\(result.name): \(result.hand_name) (\(result.score))")
                winners.append(result.name)
            }
            
            // Optionally update your AI player list if desired
            return winners
            
        } catch {
            errorMessage = "Failed to determine winners: \(error.localizedDescription)"
            return []
        }
        
    }

    func createRandomPlayers(aiNames: [String]) -> [AIPlayer] {
        let userPosition = RangeHelper.positionsOrderGlobal[tableSize]!.randomElement()!
        
        let aiPlayers = createAndReorderPlayers(playerPosition: userPosition)
        // Loop through aiPlayers and assign names (start at 2nd entry)
        aiPlayers[0].name = "HERO"
        aiPlayers[0].isUser = true
        
        for i in 1..<aiPlayers.count {
            if i - 1 < aiNames.count {
                aiPlayers[i].name = aiNames[i - 1]
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
            let player: AIPlayer = AIPlayer(name: "", position: positionList[index], stack: 100.0)
            playersReordered.append(player)
            index = (index + 1) % playerCount
            
        }
         
        return playersReordered
    }
}
