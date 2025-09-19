//
//  StatsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query var handLogs: [HandLog]   // automatically pulls from SwiftData
    @Query var games: [Game]
        
    var lastMonthLogs: [HandLog] {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return handLogs.filter { $0.date >= oneMonthAgo }
    }
    
    var totalHandsPlayed: Int {
        handLogs.count
    }
    
    var totalHandsWon: Int {
        handLogs.filter { $0.isCorrect }.count
    }
    
    var totalHandsLost: Int {
        handLogs.filter { !$0.isCorrect }.count
    }
    
    var winPercentage: Double {
        let correct = handLogs.filter { $0.isCorrect }.count
        let total = handLogs.count
        return total > 0 ? (Double(correct) / Double(total)) * 100 : 0
    }
    
    var hoursPlayed: Int {
        let totalSeconds = games.reduce(0) { $0 + $1.duration }
        return Int(ceil(totalSeconds / 3600.0))
    }

    
        
    var dailyWinPercentages: [(date: Date, winPct: Double)] {
           let grouped = Dictionary(grouping: lastMonthLogs) { log in
               Calendar.current.startOfDay(for: log.date)
           }
           
           return grouped.map { (day, logsForDay) in
               let correct = logsForDay.filter { $0.isCorrect }.count
               let total = logsForDay.count
               let pct = total > 0 ? (Double(correct) / Double(total)) * 100 : 0
               return (day, pct)
           }
           .sorted { $0.date < $1.date }
       }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                        // Top gradient bar
                    LinearGradient(
                        colors: [
                            Color.teal.opacity(0.2),
                            Color.mint.opacity(0.2)
                        ],
                        startPoint: .leading,   // left side
                        endPoint: .trailing     // right side
                    )
                    .frame(height: 400)
                        .overlay {
                            LinearGradient(
                                colors: [Color.clear, Color.black],
                                startPoint: .top,
                                endPoint: .bottom
                                )
                        }
                        
                        
                        Spacer() // pushes the rest of the content below
                }.ignoresSafeArea()
                
                ScrollView {
                    VStack {
                        HStack {
                            VStack {
                                Text("Total Time")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text("\(hoursPlayed, specifier: "%.1d")h")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                                
                                
                            }
                            .padding()
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .shadow(radius: 1)
                            
                            NavigationLink {
                                WinPercentageDetailView(overallWinPct: winPercentage)
                            } label: {
                                VStack {
                                    Text("Win %")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text("\(winPercentage, specifier: "%.1f")%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                    HStack {
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 12))
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .shadow(radius: 1)
                            }
                            
                        }
                        NavigationLink {
                            HandsPlayedDetailView(handsPlayed: totalHandsPlayed, handsWon: totalHandsWon, handsLost: totalHandsLost)
                        } label: {
                            VStack(spacing: 16) {
                                // Main header
                                VStack(spacing: 4) {
                                    Text("Hands Played")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text("\(totalHandsPlayed, specifier: "%.1d")")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                                
                                // Won / Lost section
                                HStack(spacing: 0) {
                                    VStack {
                                        Text("Hands Won")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("\(totalHandsWon, specifier: "%.1d")")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(red: 50/255, green: 130/255, blue: 80/255))
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    VStack {
                                        Text("Hands Lost")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("\(totalHandsLost, specifier: "%.1d")")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(red: 130/255, green: 50/255, blue: 60/255))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                HStack {
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                        .padding(.bottom, 12)
                        Spacer()
                        // Put total time played, total pots seen
                        VStack(alignment: .leading) {
                            Text("Win % Over Time")
                                .font(.headline)
                            
                            Chart(dailyWinPercentages, id: \.date) { stat in
                                LineMark(
                                    x: .value("Date", stat.date),
                                    y: .value("Win %", stat.winPct)
                                )
                                .foregroundStyle(.white.gradient)
                                
                            }
                            .frame(height: 220)
                            .chartYScale(domain: 0...100)
                        }
                        Spacer()
                    }
                    .padding()
                    .preferredColorScheme(.dark)
                .navigationTitle("Stats")
                }
            }
        }
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
    
    return StatsView()
        .modelContainer(container)
}
