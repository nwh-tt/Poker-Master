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
    
    var hoursPlayed: String {
        let totalSeconds = aiGames.reduce(0) { $0 + $1.duration }
        let hours = Int(ceil(totalSeconds / 3600.0))
        return "\(hours)h"
    }
    
    var gamesPlayed: String {
        String(aiGames.count)
    }
    
    var totalWins: Int {
        vsAiLogs.filter { $0.wonHand == true }.count
    }
    
    var totalAmountWon: String {
        let total = vsAiLogs.filter { $0.wonHand == true }.reduce(0) { $0 + $1.pot } * 2
        
        return total.shortCurrencyString()
    }
    
    // Sum up the raises field from the AIGameLog
    var totalRaises: Int {
        vsAiLogs.reduce(0) { $0 + $1.raises }
    }
    
    var totalAmountRaised: String {
        let total = vsAiLogs.reduce(0) { $0 + $1.totalRaised } * 2
        
        return total.shortCurrencyString()
    }
    
    var totalCalls: Int {
        vsAiLogs.reduce(0) { $0 + $1.calls }
    }
    
    var totalAmountCalled: String {
        let total = vsAiLogs.reduce(0) { $0 + $1.totalCalled } * 2
        
        return total.shortCurrencyString()
    }
    
    var totalFolds: Int {
        vsAiLogs.reduce(0) { $0 + $1.folds }
    }
    
    var totalAllIns: Int {
        vsAiLogs.reduce(0) { $0 + $1.allIns }
    }
    
    var totalBet: Double {
        vsAiLogs.reduce(0) { $0 + $1.totalBet }
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
                        GenericStatBlock(title:"Games", metric: gamesPlayed)
                    }
                    GenericStatBlock(title:"Amount Won", metric: totalAmountWon)
                    ThreeStatBlock()
                }.padding()
            }
            .fullScreenCover(isPresented: $showPremiumPopup) {
                PaywallView()
            }.task {
                isSubscribed = await SubscriptionManager.isSubscribed()
            }
            .preferredColorScheme(.dark)
            .navigationTitle("AI Stats")
        }
    
    }
}

struct ThreeStatBlock: View {
    
    var body: some View {
        HStack {
            VStack(spacing: 2) {
                Text("Folds")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("22")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }.frame(maxWidth: .infinity)
            
            Divider()
                .background(.gray.opacity(0.5))
            
            VStack(spacing: 2) {
                Text("Calls")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("22")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }.frame(maxWidth: .infinity)
            
            Divider()
                .background(.gray.opacity(0.5))
            
            VStack(spacing: 2) {
                Text("Raises")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("2")
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
        
        let aiLog = AIGameLog(hand: "", street: street, game: game)
        aiLog.wonHand = true
        aiLog.pot = 1000
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
