//
//  SwiftUIView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/14/25.
//

import SwiftUI
import SwiftData
import Charts
import RevenueCatUI

struct EquityStatsView: View {
    @State private var showPremiumPopup = false
    @State private var isSubscribed = true
    
    
    @Query var equityLogs: [EquityLog]
    @Query(filter: #Predicate<Game> { game in
        game.equityHands.count > 0
    })
    var equityGames: [Game]
    
    @State private var hoursPlayed: String = "0h"
    @State private var totalHandsPlayed: Int = 0
    @State private var totalHandsWon: Int = 0
    @State private var totalHandsLost: Int = 0
    @State private var accuracyPercent: String = "0%"
    @State private var equityHandsByType: [WinLossByCategory] = []
    @State private var equityHandsByStreet: [WinLossByCategory] = []

    // Call this once in .onAppear
    private func calculateEquityStats() {
        // Basic totals
        let totalSeconds = equityGames.reduce(0) { $0 + $1.duration }
        let hours = Int(ceil(totalSeconds / 3600.0))
        hoursPlayed = "\(hours)h"
        
        totalHandsPlayed = equityLogs.count
        totalHandsWon = equityLogs.filter { $0.isCorrect }.count
        totalHandsLost = equityLogs.filter { !$0.isCorrect }.count
        
        let percent = totalHandsPlayed > 0 ? (Double(totalHandsWon) / Double(totalHandsPlayed)) * 100 : 0
        accuracyPercent = "\(percent.formattedString())%"
        
        // Aggregate helper
        func aggregateBy<T: RawRepresentable & CaseIterable & Hashable>(_ allCases: [T], keyPath: KeyPath<EquityLog, T>) -> [WinLossByCategory] where T.RawValue == String {
            let grouped = Dictionary(grouping: equityLogs, by: { $0[keyPath: keyPath] })
            var results = grouped.map { (category, logs) in
                let wins = logs.filter { $0.isCorrect }.count
                let losses = logs.count - wins
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
        
        equityHandsByType = aggregateBy(VillainType.allCases, keyPath: \.villainType)
        equityHandsByStreet = aggregateBy(Street.allCases, keyPath: \.street)
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
                    HandsPlayedStatView(symbolName: "chevron.right", totalHandsPlayed: totalHandsPlayed, totalHandsWon: totalHandsWon, totalHandsLost: totalHandsLost)
                        .padding(.bottom)
                    
                    WinLossBarChartFromCategory(title: "Win Loss by Type", equityHandsByType: equityHandsByType, isLocked: !isSubscribed, showPremiumCallback: showPremium)
                        .padding(.bottom)
                    WinLossBarChartFromCategory(title: "Win Loss by Street", equityHandsByType: equityHandsByStreet, isLocked: !isSubscribed, showPremiumCallback: showPremium)
                    Spacer()
                    
                }
                .padding()
            }
        }
        .onAppear {
            calculateEquityStats()
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
        .navigationTitle("Equity Stats")
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
    // Add dummy EquityLogs and 2 Equity Games
    let game = Game(gameType: .equityDrill)
    game.duration = 20000
    game.totalHands = 10
    context.insert(game)
    
    for _ in 0..<10 {
        let street = Street.allCases.randomElement()!
        let villainType = VillainType.allCases.randomElement()!
        let equityLog = EquityLog(street: street, villainType: villainType, hand: "", equity: 0, xpEarned: 0, isCorrect: Bool.random(), game: game)
        game.equityHands.append(equityLog)
        context.insert(equityLog)
    }
    
    try? context.save()
    
    return EquityStatsView()
        .modelContainer(container)
}
