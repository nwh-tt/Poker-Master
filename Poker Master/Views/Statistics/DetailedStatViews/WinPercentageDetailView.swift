//
//  WinPercentageDetailView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/26/25.
//

import SwiftUI
import SwiftData
import Charts


struct WinPercentageDetailView: View {
    @Query var handLogs: [HandLog]
    
    
    
    let overallWinPct: Double
    var positionWinPcts: [(position: Position, winPct: Double)] {
        winPercentageByPosition(from: handLogs)
    }
    var actionWinPcts: [(action: Action, winPct: Double)] {
        winPercentageByAction(from: handLogs)
    }
    var raiseTypeWinPcts: [(raiseType: RaiseType, winPct: Double)] {
        winPercentageByRaiseType(from: handLogs)
    }
    
    func winPercentageByPosition(from handLogs: [HandLog]) -> [(position: Position, winPct: Double)] {
        let grouped = Dictionary(grouping: handLogs, by: { $0.position })

        return grouped.map { (position, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let pct = total > 0 ? (Double(wins) / Double(total)) * 100 : 0
            return (position, pct)
        }
        .sorted {
            (Position.allCases.firstIndex(of: $0.position) ?? 99) <
            (Position.allCases.firstIndex(of: $1.position) ?? 99)
        }
    }

    func winPercentageByAction(from handLogs: [HandLog]) -> [(action: Action, winPct: Double)] {
        let grouped = Dictionary(grouping: handLogs, by: { $0.action })

        return grouped.map { (action, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let pct = total > 0 ? (Double(wins) / Double(total)) * 100 : 0
            return (action, pct)
        }
        .sorted {
            (Action.allCases.firstIndex(of: $0.action) ?? 99) <
            (Action.allCases.firstIndex(of: $1.action) ?? 99)
        }
    }

    func winPercentageByRaiseType(from handLogs: [HandLog]) -> [(raiseType: RaiseType, winPct: Double)] {
        let grouped = Dictionary(grouping: handLogs, by: { $0.raiseType })

        return grouped.map { (raiseType, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let pct = total > 0 ? (Double(wins) / Double(total)) * 100 : 0
            return (raiseType, pct)
        }
        .sorted {
            (RaiseType.allCases.firstIndex(of: $0.raiseType) ?? 99) <
            (RaiseType.allCases.firstIndex(of: $1.raiseType) ?? 99)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header metric
                VStack {
                    Text("Overall Win %")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("\(overallWinPct, specifier: "%.1f")%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Divider()
                // Win % by Position
                VStack(alignment: .leading, spacing: 4) {
                    Text("By Position")
                        .font(.headline)
                    Chart(positionWinPcts, id: \.0) { pos, pct in
                        BarMark(
                            x: .value("Position", pos.rawValue),
                            y: .value("Win %", pct)
                        )
                        .foregroundStyle(.purple.gradient)
                    }
                    .frame(height: 150)
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))%")
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("By Action Type")
                        .font(.headline)
                    Chart(actionWinPcts, id: \.0) { action, pct in
                        BarMark(
                            x: .value("Action", action.rawValue),
                            y: .value("Win %", pct)
                        )
                        .foregroundStyle(.purple.gradient)
                        
                    }
                    .frame(height: 150)
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))%")
                                }
                            }
                        }
                    }
                }
                
                // Win % by Preflop Action
                VStack(alignment: .leading) {
                    Text("By Preflop Action")
                        .font(.headline)
                    Chart(raiseTypeWinPcts, id: \.0) { action, pct in
                            BarMark(
                                x: .value("Action", action.rawValue),
                                y: .value("Win %", pct)
                            )
                            .foregroundStyle(.purple.gradient)
                        }
                        .frame(height: 150)
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(position: .trailing) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text("\(Int(v))%")
                                    }
                                }
                            }
                        }
                }
            }
            .padding()
            .padding(.top, 80)
        }
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let schema = Schema([
            Game.self,
            HandLog.self,
            Challenges.self,
            Item.self
        ])
        let container = try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
    
    let handLogs = [
        HandLog(typeOfHand: .preflop, position: .btn, hand: "AK", pair: false, action: .raise, raiseType: .open, betAmount: 10, xpEarned: 5, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -100, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .btn, hand: "AK", pair: false, action: .raise, raiseType: .open, betAmount: 10, xpEarned: 5, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .btn, hand: "QJ", pair: false, action: .call, raiseType: .vsRaise, betAmount: 15, xpEarned: 3, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .mp, hand: "99", pair: true, action: .raise, raiseType: .threeBet, betAmount: 20, xpEarned: 8, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .utg, hand: "22", pair: true, action: .call, raiseType: .vsRaise, betAmount: 5, xpEarned: 2, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, game: Game()),
    
        HandLog(typeOfHand: .preflop, position: .sb, hand: "TT", pair: true, action: .call, raiseType: .open, betAmount: 12, xpEarned: 4, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .sb, hand: "TT", pair: true, action: .call, raiseType: .open, betAmount: 12, xpEarned: 4, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .sb, hand: "TT", pair: true, action: .call, raiseType: .open, betAmount: 12, xpEarned: 4, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, game: Game()),
    
        HandLog(typeOfHand: .preflop, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
    
        HandLog(typeOfHand: .preflop, position: .btn, hand: "KQ", pair: false, action: .raise, raiseType: .fiveBet, betAmount: 10, xpEarned: 5, isCorrect: true, date: Date(), game: Game()),
        HandLog(typeOfHand: .preflop, position: .btn, hand: "KQ", pair: false, action: .raise, raiseType: .fourBet, betAmount: 10, xpEarned: 5, isCorrect: true, date: Date(), game: Game()),
        HandLog(typeOfHand: .preflop, position: .btn, hand: "KQ", pair: false, action: .raise, raiseType: .fourBet, betAmount: 10, xpEarned: 5, isCorrect: false, date: Date(), game: Game())
    ]
    
    // Create 5 games
    for _ in 1...5 {
        let sampleGame = Game()
        sampleGame.duration = 1000
        context.insert(sampleGame)
    }
    
    for handLog in handLogs {
        context.insert(handLog)
    }
    
    
    return WinPercentageDetailView(overallWinPct: 53.2).modelContainer(container)
}
