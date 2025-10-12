import Observation
import Foundation

@Observable
class AIGameManager {
    // Game state variables
    var aiPlayers: [AIPlayer] = []
    var pot = 0.0
    var round = 0 // Preflop = 0, Flop = 1, Turn = 2, River = 3
    var lastBet = 0.0
    
    let deck = Deck() // Create a shared deck
    
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
        
        
        await preflopRound()
    }
    
    func preflopRound() async {
        print("=== 🃏 STARTING PREFLOP ROUND ===")

        let sleepTime = UInt64((5 - gameplaySpeed) * 600_000_000) // Scale from 0s to ~3s
        var turn = aiPlayers.firstIndex(where: { $0.position == "SB" })!

        print("Small Blind is at position: \(aiPlayers[turn].position)")

        // --- Handle blinds ---
        try? await Task.sleep(nanoseconds: sleepTime)
        print("Posting Small Blind...")
        raise(aiPlayer: aiPlayers[turn], amount: 0.5)
        turn = (turn + 1) % Int(tableSize)!

        try? await Task.sleep(nanoseconds: sleepTime)
        print("Posting Big Blind...")
        raise(aiPlayer: aiPlayers[turn], amount: 1.0)
        turn = (turn + 1) % Int(tableSize)!

        // --- Initialize Betting State ---
        var highestBet = 1.0   // big blind amount
        var lastAggressorIndex = 1

        print("Blinds posted. Highest bet = \(highestBet). Starting main betting loop...")

        // --- Betting Loop ---
        while true {
            var currentPlayer = aiPlayers[turn]
            print("\n---> Player \(currentPlayer.name) (\(currentPlayer.position))'s turn")

            // Skip folded or broke players
            if currentPlayer.isOutOfMoney() {
                print("Skipping \(currentPlayer.name): out of money.")
                turn = (turn + 1) % Int(tableSize)!
                continue
            }
            if currentPlayer.lastMove() == .fold {
                print("Skipping \(currentPlayer.name): already folded.")
                turn = (turn + 1) % Int(tableSize)!
                continue
            }

            // Check if everyone has matched the highest bet
            if currentPlayer.lastBet() == highestBet && turn == lastAggressorIndex {
                print("✅ Betting complete: everyone has matched the highest bet.")
                break
            }

            // Simulate thinking delay
            try? await Task.sleep(nanoseconds: sleepTime)

            print("Making AI decision for \(currentPlayer.name)...")
            let (action, amount) = makeAIDecision()

            switch action {
            case "fold":
                print("🟥 \(currentPlayer.name) folds.")
                currentPlayer.fold(round: round)

            case "call":
                print("🟨 \(currentPlayer.name) calls for \(amount).")
                call(aiPlayer: currentPlayer, amount: amount)

            case "raise":
                print("🟩 \(currentPlayer.name) raises to \(amount + highestBet)!")
                raise(aiPlayer: currentPlayer, amount: amount + highestBet)
                highestBet += amount
                lastAggressorIndex = turn
                print("New highest bet = \(highestBet). Last aggressor = \(currentPlayer.name)")

            default:
                print("⚠️ Unknown action from AI: \(action)")
            }
            print("Pot now: \(pot)")
            // Advance turn
            turn = (turn + 1) % Int(tableSize)!
            print("Next player index: \(turn)")

            // Check if only one player remains
            let activeCount = aiPlayers.filter { !$0.isOutOfMoney() && $0.lastMove() != .fold }.count
            if activeCount == 1 {
                print("🏁 Only one player remains. Preflop round ends.")
                break
            }
        }

        print("=== ✅ PREFLOP ROUND COMPLETE ===")
    }

    
    // For now just randomly return a move and bet amount
    func makeAIDecision() -> (String, Double) {
        let actions = ["call", "raise", "fold"]
        let action = actions.randomElement()!
        var amount = 0.0
        if action == "raise" {
            amount = (Double.random(in: 1.0...10.0) * 2).rounded() / 2
            
        } else if action == "call" {
            amount = lastBet
        }
        
        return (action, amount)
    }
    
    func raise(aiPlayer: AIPlayer, amount: Double) {
        let potIncrease = aiPlayer.raise(amount: amount, round: round)
        pot += potIncrease
        lastBet = amount
    }
    
    func call(aiPlayer: AIPlayer, amount: Double) {
        let potIncrease = aiPlayer.call(amount: amount, round: round)
        pot += potIncrease
    }

    func fetchAIPlayers() async -> [String] {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "http://localhost:8000/api/ai/players?table_size=\(tableSize)") else {
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

    func createRandomPlayers(aiNames: [String]) -> [AIPlayer] {
        let userPosition = RangeHelper.positionsOrderGlobal[tableSize]!.randomElement()!
        
        let aiPlayers = createAndReorderPlayers(playerPosition: userPosition)
        // Loop through aiPlayers and assign names (start at 2nd entry)
        aiPlayers[0].name = "HERO"
        
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
