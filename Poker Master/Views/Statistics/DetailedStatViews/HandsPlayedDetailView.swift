//
//  HandsPlayedDetailView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/26/25.
//

import SwiftUI
import SwiftData
import Charts

struct HandsPlayedDetailView: View {
    @Query var handLogs: [HandLog]
    var handsPlayed: Int
    var handsWon: Int
    var handsLost: Int
    
    @State private var selectedBar: String? = nil
    @State private var selectedPct: Double? = nil
    
    var positionStats: [(Position, Int, Int)] {
        getPositionPct(from: handLogs)
    }
    
    func getPositionPct(from handLogs: [HandLog]) -> [(position: Position, wins: Int, losses: Int)] {
        // Group by position
        let grouped = Dictionary(grouping: handLogs, by: { $0.position })
        
        // Calculate win/loss counts per position
        let results = grouped.map { (position, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return (position: position, wins: wins, losses: losses)
        }
        
        // Sort by enum's defined order (using rawValue)
        return results.sorted { a, b in
            a.position.rawValue < b.position.rawValue
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header metric
                VStack(spacing: 16) {
                    // Main header
                    VStack(spacing: 4) {
                        Text("Hands Played")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(handsPlayed, specifier: "%.1d")")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Won / Lost section
                    HStack(spacing: 0) {
                        VStack {
                            Text("Hands Won")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(handsWon, specifier: "%.1d")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 50/255, green: 130/255, blue: 80/255))
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("Hands Lost")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(handsLost, specifier: "%.1d")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 130/255, green: 50/255, blue: 60/255))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                        
                        Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("By Position")
                        .font(.headline)
                    Chart(positionStats, id: \.0) { pos, wins, losses in
                        BarMark(
                            x: .value("Position", pos.rawValue),
                            y: .value("Wins", wins)
                        )
                        .foregroundStyle(Color(red: 50/255, green: 130/255, blue: 80/255))
                        
                        BarMark(
                            x: .value("Position", pos.rawValue),
                            y: .value("Wins", losses)
                        )
                        .foregroundStyle(Color(red: 130/255, green: 50/255, blue: 60/255))
                    }
                    .frame(height: 150)
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
    
    for handLog in handLogs {
        context.insert(handLog)
    }
    
    return HandsPlayedDetailView(handsPlayed: 15, handsWon: 8, handsLost: 7).modelContainer(container)
}
