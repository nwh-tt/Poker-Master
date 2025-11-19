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
    
    @Query var preflopLogs: [HandLog]
    @Query(filter: #Predicate<Game> { game in
        game.preflopHands.count > 0
    })
    var preflopGames: [Game]
    
    var hoursPlayed: String {
        let totalSeconds = preflopGames.reduce(0) { $0 + $1.duration }
        let hours = Int(ceil(totalSeconds / 3600.0))
        return "\(hours)h"
    }
    
    var accuracyPercent: String {
        let correct = preflopLogs.filter { $0.isCorrect }.count
        let total = preflopLogs.count
        let percent = total > 0 ? (Double(correct) / Double(total)) * 100 : 0
        return "\(percent.formattedString())%"
    }
    
    var totalBet: String {
        let total = (preflopLogs.reduce(0) { $0 + $1.betAmount }) * 2
        // Format total as currency
        return total.shortCurrencyString()
    }
    
    var totalHandsPlayed: Int {
        preflopLogs.count
    }
    
    var totalHandsWon: Int {
        preflopLogs.filter { $0.isCorrect }.count
    }
    
    var totalHandsLost: Int {
        preflopLogs.filter { !$0.isCorrect }.count
    }
    
    var preflopHandsByPosition: [WinLossByCategory] {
        let grouped = Dictionary(grouping: preflopLogs, by: { $0.position })
        
        var results = grouped.map { (category, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return WinLossByCategory(category: category.rawValue, wins: wins, losses: losses)
        }
        
        let allCategories = Position.allCases
        let missingCategories = allCategories.filter { category in
            !results.contains(where: { $0.category == category.rawValue })
        }
        
        for category in missingCategories {
            results.append(WinLossByCategory(category: category.rawValue, wins: 0, losses: 0))
        }
        
        return results.sorted { a, b in
            let aIndex = Position.allCases.firstIndex { $0.rawValue == a.category } ?? 0
            let bIndex = Position.allCases.firstIndex { $0.rawValue == b.category } ?? 0
            return aIndex < bIndex
        }
    }
    
    var preflopHandsByAction: [WinLossByCategory] {
        let grouped = Dictionary(grouping: preflopLogs, by: { $0.action })
        
        var results = grouped.map { (category, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return WinLossByCategory(category: category.rawValue, wins: wins, losses: losses)
        }
        
        let allCategories = Action.allCases
        let missingCategories = allCategories.filter { category in
            !results.contains(where: { $0.category == category.rawValue })
        }
        
        for category in missingCategories {
            results.append(WinLossByCategory(category: category.rawValue, wins: 0, losses: 0))
        }
        
        return results.sorted { a, b in
            let aIndex = Action.allCases.firstIndex { $0.rawValue == a.category } ?? 0
            let bIndex = Action.allCases.firstIndex { $0.rawValue == b.category } ?? 0
            return aIndex < bIndex
        }
    }
    
    var preflopHandsByRaiseType: [WinLossByCategory] {
        let grouped = Dictionary(grouping: preflopLogs, by: { $0.raiseType })
        
        var results = grouped.map { (category, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return WinLossByCategory(category: category.rawValue, wins: wins, losses: losses)
        }
        
        let allCategories = RaiseType.allCases
        let missingCategories = allCategories.filter { category in
            !results.contains(where: { $0.category == category.rawValue })
        }
        
        for category in missingCategories {
            results.append(WinLossByCategory(category: category.rawValue, wins: 0, losses: 0))
        }
        
        return results.sorted { a, b in
            let aIndex = RaiseType.allCases.firstIndex { $0.rawValue == a.category } ?? 0
            let bIndex = RaiseType.allCases.firstIndex { $0.rawValue == b.category } ?? 0
            return aIndex < bIndex
        }
    }
    
    
    private func showPremium() {
        showPremiumPopup = true
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top gradient bar
                LinearGradient(
                    colors: [
                        Color.teal.opacity(0.2),
                        Color.mint.opacity(0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
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
            
            EllipticalGradient(colors: [Color.teal.opacity(0.2), Color.mint.opacity(0.1), Color.clear], center: .center)
                .ignoresSafeArea()
            
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
        .fullScreenCover(isPresented: $showPremiumPopup) {
            PaywallView()
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
        var hand = Position.allCases.randomElement()!
        var raiseType = RaiseType.allCases.randomElement()!
        var action = Action.allCases.randomElement()!
        var betAmount = Double.random(in: 0...70)
        var pot = Double.random(in: 0...200)
        
        let handLog = HandLog(position: hand, hand: "", pair: false, action: action, raiseType: raiseType, betAmount: betAmount, pot: pot, xpEarned: 0, isCorrect: Bool.random(), game: game)
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
