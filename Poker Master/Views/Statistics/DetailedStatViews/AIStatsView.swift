//
//  AIStatsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/18/25.
//

import SwiftUI
import SwiftData
import Charts
import RevenueCatUI

struct AIStatsView: View {
    @State private var showPremiumPopup = false
    @State private var isSubscribed = true
    
    @Query var vsAiLogs: [AIGameLog]
    @Query(filter: #Predicate<Game> { game in
        game.aiGameHands.count > 0
    })
    var aiGames: [Game]
    
    // All metrics
    @State private var hoursPlayed: String = "0h"
    @State private var gamesPlayed: String = "0"
    @State private var totalWins: Int = 0
    @State private var totalAmountWon: String = "$0"
    @State private var totalRaises: Int = 0
    @State private var totalAmountRaised: String = "$0"
    @State private var totalCalls: Int = 0
    @State private var totalAmountCalled: String = "$0"
    @State private var totalFolds: Int = 0
    @State private var totalAllIns: Int = 0
    @State private var totalBet: Double = 0.0

    // MARK: - Function to Calculate All Stats
    private func calculateStats() {
        // Hours played
        let totalSeconds = aiGames.reduce(0) { $0 + $1.duration }
        let hours = Int(ceil(totalSeconds / 3600.0))
        hoursPlayed = "\(hours)h"
        
        // Games played
        gamesPlayed = String(aiGames.count)
        
        // Wins
        totalWins = vsAiLogs.filter { $0.wonHand == true }.count
        
        vsAiLogs.filter { $0.wonHand == true }.forEach { print($0.pot) }
        
        // Amount won
        let totalWon = vsAiLogs.filter { $0.wonHand == true }.reduce(0) { $0 + $1.pot } * 2
        totalAmountWon = totalWon.shortCurrencyString()
        
        // Raises
        totalRaises = vsAiLogs.reduce(0) { $0 + $1.raises }
        let totalRaised = vsAiLogs.reduce(0) { $0 + $1.totalRaised } * 2
        totalAmountRaised = totalRaised.shortCurrencyString()
        
        // Calls
        totalCalls = vsAiLogs.reduce(0) { $0 + $1.calls }
        let totalCalled = vsAiLogs.reduce(0) { $0 + $1.totalCalled } * 2
        totalAmountCalled = totalCalled.shortCurrencyString()
        
        // Folds
        totalFolds = vsAiLogs.reduce(0) { $0 + $1.folds }
        
        // All-ins
        totalAllIns = vsAiLogs.reduce(0) { $0 + $1.allIns }
        
        // Total bet
        totalBet = vsAiLogs.reduce(0) { $0 + $1.totalBet }
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
                        GenericStatBlock(title:"Games", metric: gamesPlayed)
                    }
                    GenericStatBlock(title:"Total Winnings", metric: totalAmountWon)
                    ThreeStatBlock(folds: totalFolds, calls: totalCalls, raises: totalRaises)
                    PieChart(values: [
                            PieChartSlice(label: "Folds", value: totalFolds),
                            PieChartSlice(label: "Calls", value: totalCalls),
                            PieChartSlice(label: "Raises", value: totalRaises),
                            PieChartSlice(label: "All-Ins", value: totalAllIns),
                        ],
                                   isLocked: !isSubscribed,
                                showPremiumCallback: showPremium
                    )
                        .padding(.vertical)
                }.padding()
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
            .navigationTitle("AI Stats")
        }
        .onAppear {
            calculateStats()
        }
    
    }
}

struct ThreeStatBlock: View {
    let folds: Int
    let calls: Int
    let raises: Int
    
    
    var body: some View {
        HStack {
            VStack(spacing: 2) {
                Text("Folds")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("\(folds)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }.frame(maxWidth: .infinity)
            
            Divider()
                .background(.gray.opacity(0.5))
            
            VStack(spacing: 2) {
                Text("Calls")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("\(calls)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }.frame(maxWidth: .infinity)
            
            Divider()
                .background(.gray.opacity(0.5))
            
            VStack(spacing: 2) {
                Text("Raises")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("\(raises)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }.frame(maxWidth: .infinity)
            
        }
        .padding()
        .frame(maxWidth: .infinity)
        .applyGlass { view in
            if #available(iOS 26.0, *) {
                view
                    .glassEffect(in: .rect(cornerRadius: 16))
            }
            else {
                view
                    .background(.ultraThinMaterial)
            }
        }
        .shadow(radius: 4)
        .cornerRadius(16)
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
        
        let aiLog = AIGameLog(hand: "", street: street, game: game)
        aiLog.wonHand = true
        aiLog.pot = 1000
        aiLog.raises = Int.random(in: 0...5)
        aiLog.calls = Int.random(in: 0...8)
        aiLog.folds = Int.random(in: 0...10)
        aiLog.allIns = Int.random(in: 0...1)
        game.aiGameHands.append(aiLog)
        context.insert(aiLog)
    }
    
    do {
        try context.save()
    } catch {
        print(error)
    }
    
    return AIStatsView()
        .modelContainer(container)
}
