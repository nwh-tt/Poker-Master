//
//  EquityDrillManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/9/25.
//
import Foundation

@MainActor
class EquityDrillManager: ObservableObject {
    @Published var user: Player? = nil
    @Published var score: Int = 0
    @Published var roundsPlayed: Int = 0
    @Published var equityReady: Bool = false
    @Published var currentScenario: EquityScenario? = nil
    
    var betNumber: Int = 1
    
    var ranges: [String: [String]]
    
    // Queue of preloaded scenarios
    private var scenarioQueue: [EquityScenario] = []
    private let queueSize = 3
    
    var street: String = "Any"
    
    init(street: String) {
        self.ranges = RangesFileManager.loadRanges()
        self.street = street
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
        let allKeys = Array(ranges.keys)
        guard let randomKey = allKeys.randomElement() else { return nil }
        
        let deck = Deck()
        let heroHand = [deck.dealCard(), deck.dealCard()]
        guard heroHand.count == 2 else { return nil }
        var selectedStreet = street
        print("Selected street: \(street)")
        if street == "Any" {
            selectedStreet = ["Preflop", "Flop", "Turn"].randomElement()!
        }
        var board: [Card] = []
        if selectedStreet == "Flop" {
            for _ in 0..<3 {
                board.append(deck.dealCard())
            }
        } else if selectedStreet == "Turn" {
            for _ in 0..<4 {
                board.append(deck.dealCard())
            }
        }
        
        guard let villainRange = ranges[randomKey] else { return nil }
        
        // Fetch equity asynchronously
        return await withCheckedContinuation { (continuation: CheckedContinuation<EquityScenario?, Never>) in
            fetchEquityRange(heroHole: [heroHand[0].toString(), heroHand[1].toString()], villainRange: villainRange) { response in
                guard let response = response else {
                    continuation.resume(returning: nil as EquityScenario?)
                    return
                }
                let correctEquityRange = "\(response.low_equity)% - \(response.high_equity)%"
                let scenario = EquityScenario(
                    heroHand: heroHand,
                    villainRange: villainRange,
                    board: board,
                    correctEquityRange: correctEquityRange,
                    lowEquity: response.low_equity,
                    highEquity: response.high_equity,
                    options: self.getEquityOptions(correctEquityHigh: response.high_equity, correctEquityLow: response.low_equity, correctEquityRange: correctEquityRange)
                )
                continuation.resume(returning: scenario)
            }
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
    let villainRange: [String]
    let board: [Card]
    let correctEquityRange: String
    let lowEquity: Int
    let highEquity: Int
    let options: [String]   // includes correct + 3 distractors
}
