//
//  PreflopStatsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/18/25.
//

import SwiftUI
import SwiftData
import Charts
import RevenueCatUI


struct PreflopStatsView: View {
    @State private var showPremiumPopup = false
    @State private var isSubscribed = true
    
    @Query var preflopLogs: [PreflopLog]
    @Query(filter: #Predicate<Game> { game in
        game.preflopHands.count > 0
    })
    var preflopGames: [Game]
    
    @State private var hoursPlayed: String = "0h"
    @State private var accuracyPercent: String = "0%"
    @State private var totalBet: String = "$0"
    @State private var totalHandsPlayed: Int = 0
    @State private var totalHandsWon: Int = 0
    @State private var totalHandsLost: Int = 0
    @State private var preflopHandsByPosition: [WinLossByCategory] = []
    @State private var preflopHandsByAction: [WinLossByCategory] = []
    @State private var preflopHandsByRaiseType: [WinLossByCategory] = []

    // MARK: - Function to Calculate All Stats
    private func calculatePreflopStats() {
        // Hours played
        let totalSeconds = preflopGames.reduce(0) { $0 + $1.duration }
        let hours = Int(ceil(totalSeconds / 3600.0))
        hoursPlayed = "\(hours)h"
        
        // Accuracy
        let correct = preflopLogs.filter { $0.isCorrect }.count
        let total = preflopLogs.count
        let percent = total > 0 ? (Double(correct) / Double(total)) * 100 : 0
        accuracyPercent = "\(percent.formattedString())%"
        
        // Total bet
        let totalBetted = preflopLogs.reduce(0) { $0 + $1.betAmount } * 2
        totalBet = totalBetted.shortCurrencyString()
        
        // Hands played/won/lost
        totalHandsPlayed = preflopLogs.count
        totalHandsWon = correct
        totalHandsLost = totalHandsPlayed - correct
        
        // Helper to generate WinLossByCategory
        func aggregateBy<T: RawRepresentable & CaseIterable & Hashable>(_ allCases: [T], groupBy: (PreflopLog) -> T) -> [WinLossByCategory] where T.RawValue == String {
            let grouped = Dictionary(grouping: preflopLogs, by: groupBy)
            var results = grouped.map { (category, logs) in
                let total = logs.count
                let wins = logs.filter { $0.isCorrect }.count
                let losses = total - wins
                return WinLossByCategory(category: category.rawValue, wins: wins, losses: losses)
            }
            let missing = allCases.filter { category in
                !results.contains(where: { $0.category == category.rawValue })
            }
            for category in missing {
                results.append(WinLossByCategory(category: category.rawValue, wins: 0, losses: 0))
            }
            return results.sorted { a, b in
                let aIndex = allCases.firstIndex { $0.rawValue == a.category } ?? 0
                let bIndex = allCases.firstIndex { $0.rawValue == b.category } ?? 0
                return aIndex < bIndex
            }
        }
        
        preflopHandsByPosition = aggregateBy(Position.allCases, groupBy: { $0.position })
        preflopHandsByAction = aggregateBy(Action.allCases, groupBy: { $0.action })
        preflopHandsByRaiseType = aggregateBy(RaiseType.allCases, groupBy: { $0.raiseType })
    }
    
    
    private func showPremium() {
        showPremiumPopup = true
    }
    
    var body: some View {
        ZStack {
            GradientBackgroundView()
            ScrollView {
                VStack {
                    HStack {
                        GenericStatBlock(title:"Time Played", metric: hoursPlayed)
                        GenericStatBlock(title:"Accuracy", metric: accuracyPercent)
                    }
                    GenericStatBlock(title:"Total Bet", metric: totalBet)
                    HandsPlayedStatView(symbolName: "chevron.right", totalHandsPlayed: totalHandsPlayed, totalHandsWon: totalHandsWon, totalHandsLost: totalHandsLost)
                        .padding(.bottom)
                    
                    WinLossBarChartFromCategory(title: "Win Loss by Position", equityHandsByType: preflopHandsByPosition, isLocked: !isSubscribed, showPremiumCallback: showPremium)
                    WinLossBarChartFromCategory(title: "Win Loss by Action", equityHandsByType: preflopHandsByAction, isLocked: !isSubscribed, showPremiumCallback: showPremium)
                    WinLossBarChartFromCategory(title: "Win Loss by Bet Number", equityHandsByType: preflopHandsByRaiseType, isLocked: !isSubscribed, showPremiumCallback: showPremium)
                    Spacer()
                }
                .padding()
                .preferredColorScheme(.dark)
            }
        }
        .onAppear {
            calculatePreflopStats()
        }
        .fullScreenCover(isPresented: $showPremiumPopup) {
            PaywallView()
                .onPurchaseCompleted { customerInfo in
                    if customerInfo.entitlements["Premium Subscription"]?.isActive == true {
                        isSubscribed = true
                    }
                }
        }.task {
            isSubscribed = await SubscriptionManager.isSubscribed()
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Preflop Stats")
    }
}

#Preview {
    let schema = Schema([
            Game.self,
            PreflopLog.self,
            EquityLog.self,
            AIGameLog.self,
            Challenges.self
        ])
    let container = try! ModelContainer(
        for: schema,
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    let context = container.mainContext
    // Add dummy data
    let game = Game(gameType: .equityDrill)
    game.duration = 20000
    game.totalHands = 10
    context.insert(game)
    
    for _ in 0..<10 {
        var hand = Position.allCases.randomElement()!
        var raiseType = RaiseType.allCases.randomElement()!
        var action = Action.allCases.randomElement()!
        var betAmount = Double.random(in: 0...70)
        var pot = Double.random(in: 0...200)
        
        let handLog = PreflopLog(position: hand, hand: "", pair: false, action: action, raiseType: raiseType, betAmount: betAmount, pot: pot, xpEarned: 0, isCorrect: Bool.random(), game: game)
        game.preflopHands.append(handLog)
        context.insert(handLog)
    }
    
    do {
        try context.save()
    } catch {
        print(error)
    }
    
    return PreflopStatsView()
        .modelContainer(container)
}
