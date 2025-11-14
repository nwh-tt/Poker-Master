//
//  EquityDrillManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/9/25.
//
import Foundation
import SwiftData

@MainActor
class EquityDrillManager: ObservableObject {
    @Published var user: Player? = nil
    @Published var score: Int = 0
    @Published var roundsPlayed: Int = 0
    @Published var equityReady: Bool = false
    @Published var currentScenario: EquityScenario? = nil
    
    // Error message logic
    @Published var errorMessage: String? = nil
    @Published var showToast = false
    
    let equityAPI: EquityAPI
    var context: ModelContext?
    
    var betNumber: Int = 1
    
    let rangeHelper = RangeHelper()
    
    // Queue of preloaded scenarios
    private var scenarioQueue: [EquityScenario] = []
    private let queueSize = 3
    
    // User selections
    var street: String = "Any"
    var villainType: String = "Any" // Any, Ranges, Cards
    
    init(street: String, villainType: String, authManager: AuthManager) {
        self.street = street
        self.villainType = villainType
        self.equityAPI = EquityAPI(authManager: authManager)
        // Load in the first scenario
        Task { @MainActor in
                // Load the first scenario
                if let scenario = await createScenario() {
                    scenarioQueue.append(scenario)
                }
                

                print("Preloaded scenarios: \(scenarioQueue)")
                stageNextScenario()
            
                // Preload additional scenarios
                preloadScenarios()
            }
    }
    
    private func preloadScenarios() {
        Task {
            for _ in 0..<queueSize {
                if let scenario = await createScenario() {
                    scenarioQueue.append(scenario)
                }
            }
        }
    }
    
    private func createScenario() async -> EquityScenario? {
        // Randomly selects a key
        
        
        // Dealing hands to players
        let deck = Deck()
        let heroHand = [deck.dealCard(), deck.dealCard()]
        guard heroHand.count == 2 else { return nil }
        
        var selectedVillainType = villainType
        if villainType == "Any" {
            selectedVillainType = ["Cards", "Ranges"].randomElement()!
        }
        
        var currentStreet = street
        if street == "Any" {
            currentStreet = ["Preflop", "Flop", "Turn"].randomElement()!
        }
        var board: [Card] = []
        if currentStreet == "Flop" {
            for _ in 0..<3 {
                board.append(deck.dealCard())
            }
        } else if currentStreet == "Turn" {
            for _ in 0..<4 {
                board.append(deck.dealCard())
            }
        }
        
        // Either assign villain hand or range
        var villainHand: [Card]?
        var villainRange: [String]?
        if selectedVillainType == "Cards" {
            villainHand = [deck.dealCard(), deck.dealCard()]
        } else {
            let allKeys = rangeHelper.getKeys()
            guard let randomKey = allKeys.randomElement() else { return nil }
            villainRange = rangeHelper.rangesFromKey(key: randomKey)
            if villainRange?.isEmpty == true {
                fatalError("No range found for \(randomKey)")
            }
        }
        
        print("Fetching equity for: \(selectedVillainType), \(currentStreet)")
        
        // Fetch equity asynchronously
        do {
            var response: EquityResponse?
            // 1. Use try await to call the async function directly
            if selectedVillainType == "Ranges" {
                guard let villainRange else {
                    fatalError("Villain range is nil")
                }
                response = try await equityAPI.fetchEquityRange(
                    heroHole: [heroHand[0].toString(), heroHand[1].toString()],
                    villainRange: villainRange,
                    board: board.map { $0.toString() } // Ensure board is also mapped to strings
                )
            } else {
                guard let villainHand else {
                    fatalError("Villain hand is nil")
                }
                response = try await equityAPI.fetchEquityHand(
                    heroHole: [heroHand[0].toString(), heroHand[1].toString()],
                    villainHole: [villainHand[0].toString(), villainHand[1].toString()],
                    board: board.map { $0.toString() } // Ensure board is also mapped to strings
                )
            }
            guard let response else {
                fatalError("Equity response is nil")
            }
            
            // 2. Process the successful response
            let correctEquityRange = "\(response.low_equity)% - \(response.high_equity)%"
            let scenario = EquityScenario(
                heroHand: heroHand,
                villainHand: villainHand,
                villainRange: villainRange,
                board: board,
                correctEquityRange: correctEquityRange,
                lowEquity: response.low_equity,
                highEquity: response.high_equity,
                options: self.getEquityOptions(
                    correctEquityHigh: response.high_equity,
                    correctEquityLow: response.low_equity,
                    correctEquityRange: correctEquityRange
                )
            )
            
            return scenario
        } catch {
            // 3. Handle any error thrown (401, network failure, decoding failure, etc.)
            print("Error fetching equity in createScenario: \(error.localizedDescription)")
            errorMessage = "Failed to fetch equity"
            showToast = true
            return nil // Return nil on failure
        }
    }
    
    func stageNextScenario() {
        // Pop first scenario from queue
        guard !scenarioQueue.isEmpty else {
            equityReady = false
            return
        }
        
        self.currentScenario = scenarioQueue.removeFirst()
        self.equityReady = true
        // check if there are more scenarios to load (limit is 10 hands played so no need to load anymore)
        if roundsPlayed + scenarioQueue.count < 10 {
            // Preload a new scenario in the background to keep queue full
            Task {
                if let newScenario = await createScenario() {
                    scenarioQueue.append(newScenario)
                }
            }
        } else {
            print("No more scenarios to load")
        }
    }
    
    func reset() {
        self.score = 0
        self.roundsPlayed = 0
        
        Task { @MainActor in
                // Load the first scenario
                if let scenario = await createScenario() {
                    scenarioQueue.append(scenario)
                }
                

                print("Preloaded scenarios: \(scenarioQueue)")
                stageNextScenario()
            
                // Preload additional scenarios
                preloadScenarios()
            }
    }
    
    func getEquityOptions(correctEquityHigh: Int, correctEquityLow: Int, correctEquityRange: String) -> [String] {
        var options: [String] = []

        // Generate 3 options around high equity
        for i in 1...3 {
            let start = correctEquityHigh + (i * 11)
            let end = start + 10
            if end >= 100 { break }
            options.append("\(start)% - \(end)%")
        }

        // Generate 3 options around low equity
        for i in 1...3 {
            let start = correctEquityLow - (i * 11)
            if start < 0 { break }
            let end = min(start + 10, 100)
            options.append("\(start)% - \(end)%")
        }

        // Shuffle and pick 4 options including correct
        options.shuffle()
        var fourOptions = Array(options.prefix(3))
        fourOptions.append(correctEquityRange)
        
        return fourOptions.sorted { lhs, rhs in
            let lhsValue = Int(lhs.split(separator: "%")[0]) ?? 0
            let rhsValue = Int(rhs.split(separator: "%")[0]) ?? 0
            return lhsValue < rhsValue
        }
    }
}

// MARK: - Equity Scenario Struct
struct EquityScenario {
    let heroHand: [Card]
    let villainHand: [Card]?
    let villainRange: [String]?
    let board: [Card]
    let correctEquityRange: String
    let lowEquity: Int
    let highEquity: Int
    let options: [String]
    
    // Data for logging
    var street: Street {
        switch board.count {
        case 0: return .preflop
        case 3: return .flop
        case 4: return .turn
        case 5: return .river
        default: return .preflop
        }
    }
    var villainType: VillainType {
        villainHand != nil ? .hand : .range
    }
    
    init(
        heroHand: [Card],
        villainHand: [Card]? = nil,
        villainRange: [String]? = nil,
        board: [Card] = [],
        correctEquityRange: String,
        lowEquity: Int,
        highEquity: Int,
        options: [String]
    ) {
        self.heroHand = heroHand
        self.villainHand = villainHand
        self.villainRange = villainRange
        self.board = board
        self.correctEquityRange = correctEquityRange
        self.lowEquity = lowEquity
        self.highEquity = highEquity
        self.options = options
    }
}
