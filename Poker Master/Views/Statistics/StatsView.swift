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
    
    @Query var handLogs: [HandLog]
    @Query var games: [Game]
    
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
                        
                        
                        Spacer()
                }.ignoresSafeArea()
                
                EllipticalGradient(colors: [Color.teal.opacity(0.2), Color.mint.opacity(0.1), Color.clear], center: .center)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack {
                        HStack {
                            VStack {
                                Text("Total Time")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text("\(hoursPlayed, specifier: "%.1d")h")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                
                            }
                            .padding()
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity)
                            .applyGlass { view in
                                if #available(iOS 26.0, *) {
                                    view
                                        .glassEffect(in: .rect(cornerRadius: 16))
                                } else {
                                    view
                                        .background(.ultraThinMaterial)
                                }
                            }
                            .cornerRadius(16)
                            .shadow(radius: 1)
                            if isSubscribed {
                                NavigationLink {
                                    WinPercentageDetailView(overallWinPct: winPercentage)
                                } label: {
                                    WinPercentageStatView(symbolName: "chevron.right", winPercentage: winPercentage)
                                }
                            } else {
                                Button {
                                    showPremiumPopup = true
                                } label: {
                                    WinPercentageStatView(symbolName: "lock.fill", winPercentage: winPercentage)
                                }
                            }
                            
                        }
                        if isSubscribed {
                            NavigationLink {
                                HandsPlayedDetailView()
                            } label: {
                                HandsPlayedStatView(symbolName: "chevron.right", totalHandsPlayed: totalHandsPlayed, totalHandsWon: totalHandsWon, totalHandsLost: totalHandsLost)
                            }
                        } else {
                            Button {
                                showPremiumPopup = true
                            }
                            label: {
                                HandsPlayedStatView(symbolName: "lock.fill", totalHandsPlayed: totalHandsPlayed, totalHandsWon: totalHandsWon, totalHandsLost: totalHandsLost)
                            }
                        }

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
        }
        .fullScreenCover(isPresented: $showPremiumPopup) {
            PaywallView()
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
        // let context = container.mainContext
    
    return StatsView()
        .modelContainer(container)
}
