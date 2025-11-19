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
    
    var hoursPlayed: String {
        let totalSeconds = equityGames.reduce(0) { $0 + $1.duration }
        let hours = Int(ceil(totalSeconds / 3600.0))
        return "\(hours)h"
    }
    
    var totalHandsPlayed: Int {
        equityLogs.count
    }
    
    var totalHandsWon: Int {
        equityLogs.filter { $0.isCorrect }.count
    }
    
    var totalHandsLost: Int {
        equityLogs.filter { !$0.isCorrect }.count
    }
    
    var accuracyPercent: String {
        let correct = equityLogs.filter { $0.isCorrect }.count
        let total = equityLogs.count
        let percent = total > 0 ? (Double(correct) / Double(total)) * 100 : 0
        return "\(percent.formattedString())%"
    }
    
    var equityHandsByType: [WinLossByCategory] {
        let grouped = Dictionary(grouping: equityLogs, by: { $0.villainType })
        
        var results = grouped.map { (category, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return WinLossByCategory(category: category.rawValue, wins: wins, losses: losses)
        }
        
        let allCategories = VillainType.allCases
        let missingCategories = allCategories.filter { category in
            !results.contains(where: { $0.category == category.rawValue })
        }
        
        for category in missingCategories {
            results.append(WinLossByCategory(category: category.rawValue, wins: 0, losses: 0))
        }
        
        return results.sorted { a, b in
            let aIndex = VillainType.allCases.firstIndex { $0.rawValue == a.category } ?? 0
            let bIndex = VillainType.allCases.firstIndex { $0.rawValue == b.category } ?? 0
            return aIndex < bIndex
        }
    }
    
    var equityHandsByStreet: [WinLossByCategory] {
        let grouped = Dictionary(grouping: equityLogs, by: { $0.street })
        
        var results = grouped.map { (category, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return WinLossByCategory(category: category.rawValue, wins: wins, losses: losses)
        }
        
        // Fill in the gaps. Add 0s for missing categories
        let allCategories = Street.allCases
        let missingCategories = allCategories.filter { category in
            !results.contains(where: { $0.category == category.rawValue })
        }
        
        for category in missingCategories {
            results.append(WinLossByCategory(category: category.rawValue, wins: 0, losses: 0))
        }
        
        return results.sorted { a, b in
            let aIndex = Street.allCases.firstIndex { $0.rawValue == a.category } ?? 0
            let bIndex = Street.allCases.firstIndex { $0.rawValue == b.category } ?? 0
            return aIndex < bIndex
        }
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
        .fullScreenCover(isPresented: $showPremiumPopup) {
            PaywallView()
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
            HandLog.self,
            EquityLog.self,
            AIGameLog.self,
            Challenges.self,
            Item.self
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
        var street = Street.allCases.randomElement()!
        var villainType = VillainType.allCases.randomElement()!
        let equityLog = EquityLog(street: street, villainType: villainType, hand: "", equity: 0, xpEarned: 0, isCorrect: Bool.random(), game: game)
        game.equityHands.append(equityLog)
        context.insert(equityLog)
    }
    
    do {
        try context.save()
    } catch {
        print(error)
    }
    
    return EquityStatsView()
        .modelContainer(container)
}
