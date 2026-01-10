//
//  StatsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//

import SwiftUI
import SwiftData
import Charts
import RevenueCatUI

struct StatsView: View {
    @State private var showPremiumPopup = false
    @State private var isSubscribed = true
    
    @Query var handLogs: [PreflopLog]
    @Query var games: [Game]
    
    @State private var hoursPlayed: String = "0h"
    @State private var totalGames: Int = 0
    @State private var preflopGames: Int = 0
    @State private var equityGames: Int = 0
    @State private var vsAIGames: Int = 0
    
    // Call this once in .onAppear
    private func calculateStats() {
        let validGames = games.filter {
            !$0.preflopHands.isEmpty || !$0.equityHands.isEmpty || !$0.aiGameHands.isEmpty
        }
        let totalSeconds = validGames.reduce(0) { $0 + $1.duration }
        hoursPlayed = "\(Int(ceil(totalSeconds / 3600.0)))h"
        
        preflopGames = validGames.filter { $0.gameType == .preFlop }.count
        equityGames = validGames.filter { $0.gameType == .equityDrill }.count
        vsAIGames = validGames.filter { $0.gameType == .aiVsHuman }.count
        
        totalGames = validGames.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()
                ScrollView {
                    VStack {
                        HStack {
                            GenericStatBlock(title:"Time Played", metric: hoursPlayed)
                            GenericStatBlock(title: "Total Games", metric: String(totalGames))
                        }
                        
                        PieChart(values: [
                            PieChartSlice(label: "Preflop", value: preflopGames),
                            PieChartSlice(label: "Equity", value: equityGames),
                            PieChartSlice(label: "AI", value: vsAIGames)
                        ], isLocked: false, showPremiumCallback: {})
                            .padding(.top)
                        
                        Divider()
                            .background(Color.gray.opacity(0.2))
                            .padding(.top)

                        
                        HStack {
                            NavigationLink {
                                PreflopStatsView()
                            } label: {
                                DetailedStatOption(gameType: "Preflop", tintColor: .blue)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            NavigationLink {
                                EquityStatsView()
                            } label: {
                                DetailedStatOption(gameType: "Equity", tintColor: .green)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            NavigationLink {
                                AIStatsView()
                            } label: {
                                DetailedStatOption(gameType: "VS AI", tintColor: .red)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top)
                        Spacer()
                    }
                    .padding()
                    .preferredColorScheme(.dark)
                .navigationTitle("Stats")
                }
            }
            .onAppear {
                calculateStats()
            }
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
        }.preferredColorScheme(.dark)
    }
}

struct DetailedStatOption: View {
    let gameType: String
    let tintColor: Color
    var sfIcon: String {
        switch gameType {
        case "Preflop":
            return "suit.club.fill"
        case "Equity":
            return "scale.3d"
        case "VS AI":
            return "brain.head.profile.fill"
        default:
            return "chevron.right"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: sfIcon)
                .foregroundColor(.white)
                .font(.system(size: 24))
            HStack {
                Text(gameType)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            HStack(spacing: 2) {
                
                Text("View More")
                    .foregroundColor(.gray)
                    .font(.system(size: 10))
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 8))
            }
            .padding(.top, 1)
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, minHeight: 110, maxHeight: 110)
        .applyGlass { view in
            if #available(iOS 26.0, *) {
                view
                    .glassEffect(.regular.tint(tintColor.opacity(0.05)), in: .rect(cornerRadius: 16))
            } else {
                view
                    .background(.ultraThinMaterial)
            }
        }
        .cornerRadius(16)
        .shadow(radius: 1)
    }
}

struct WinPercentageStatView: View {
    let symbolName: String // Pass in "chevron.right" or "lock.fill"
    let winPercentage: Double
    
    var body: some View {
        VStack {
            Text("Accuracy")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("\(winPercentage, specifier: "%.1f")%")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            HStack {
                Spacer()
                Image(systemName: symbolName)
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .shadow(radius: 1)
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
    let sampleUser = Profile(username: "Test")
    sampleUser.level = 10
    context.insert(sampleUser)
    
    let game = Game(gameType: .equityDrill)
    game.duration = 20000
    game.totalHands = 10
    context.insert(game)
    
    for _ in 0..<10 {
        let hand = Position.allCases.randomElement()!
        let raiseType = RaiseType.allCases.randomElement()!
        let action = Action.allCases.randomElement()!
        let betAmount = Double.random(in: 0...70)
        let pot = Double.random(in: 0...200)
        
        let handLog = PreflopLog(position: hand, hand: "", pair: false, action: action, raiseType: raiseType, betAmount: betAmount, pot: pot, xpEarned: 0, isCorrect: Bool.random(), game: game)
        game.preflopHands.append(handLog)
        context.insert(handLog)
    }
    
    let eqGame = Game(gameType: .aiVsHuman)
    eqGame.duration = 20000
    eqGame.totalHands = 10
    context.insert(eqGame)
    
    for _ in 0..<10 {
        let street = Street.allCases.randomElement()!
        let villainType = VillainType.allCases.randomElement()!
        let equityLog = EquityLog(street: street, villainType: villainType, hand: "", equity: 0, xpEarned: 0, isCorrect: Bool.random(), game: eqGame)
        eqGame.equityHands.append(equityLog)
        context.insert(equityLog)
    }
    
    
    try? context.save()
    
    return StatsView()
        .modelContainer(container)
}
