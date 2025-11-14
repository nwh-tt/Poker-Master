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
    
    var preflopHands: [HandLog] {
        handLogs
    }
    
    
    
    let overallWinPct: Double
    var positionWinPcts: [(position: Position, winPct: Double)] {
        winPercentageByPosition(from: preflopHands)
    }
    var actionWinPcts: [(action: Action, winPct: Double)] {
        winPercentageByAction(from: preflopHands)
    }
    var raiseTypeWinPcts: [(raiseType: RaiseType, winPct: Double)] {
        winPercentageByRaiseType(from: preflopHands)
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
                        .foregroundStyle(Color(red: 50/255, green: 130/255, blue: 80/255))
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
                        .foregroundStyle(Color(red: 50/255, green: 130/255, blue: 80/255))
                        
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
                            .foregroundStyle(Color(red: 50/255, green: 130/255, blue: 80/255))
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
    
    
    return WinPercentageDetailView(overallWinPct: 53.2).modelContainer(container)
}
