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
    @Query var equityLogs: [EquityLog]
    @Query(filter: #Predicate<Game> { game in
        game.equityHands.count > 0
    })
    var equityGames: [Game]
    
    @State private var showPremiumPopup = false
    @State private var isSubscribed = true
    
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
    var equityHandsByType: [EquityHandsByCategory] {
        let grouped = Dictionary(grouping: equityLogs, by: { $0.villainType })
        
        var results = grouped.map { (category, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return EquityHandsByCategory(category: category.rawValue, wins: wins, losses: losses)
        }
        
        let allCategories = VillainType.allCases
        let missingCategories = allCategories.filter { category in
            !results.contains(where: { $0.category == category.rawValue })
        }
        
        for category in missingCategories {
            results.append(EquityHandsByCategory(category: category.rawValue, wins: 0, losses: 0))
        }
        
        return results.sorted { a, b in
            let aIndex = VillainType.allCases.firstIndex { $0.rawValue == a.category } ?? 0
            let bIndex = VillainType.allCases.firstIndex { $0.rawValue == b.category } ?? 0
            return aIndex < bIndex
        }
    }
    
    var equityHandsByStreet: [EquityHandsByCategory] {
        let grouped = Dictionary(grouping: equityLogs, by: { $0.street })
        
        var results = grouped.map { (category, logs) in
            let total = logs.count
            let wins = logs.filter { $0.isCorrect }.count
            let losses = total - wins
            return EquityHandsByCategory(category: category.rawValue, wins: wins, losses: losses)
        }
        
        // Fill in the gaps. Add 0s for missing categories
        let allCategories = Street.allCases
        let missingCategories = allCategories.filter { category in
            !results.contains(where: { $0.category == category.rawValue })
        }
        
        for category in missingCategories {
            results.append(EquityHandsByCategory(category: category.rawValue, wins: 0, losses: 0))
        }
        
        return results.sorted { a, b in
            let aIndex = Street.allCases.firstIndex { $0.rawValue == a.category } ?? 0
            let bIndex = Street.allCases.firstIndex { $0.rawValue == b.category } ?? 0
            return aIndex < bIndex
        }
    }
    
    func showPremium() {
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
                    HandsPlayedStatView(symbolName: "chevron.right", totalHandsPlayed: totalHandsPlayed, totalHandsWon: totalHandsWon, totalHandsLost: totalHandsLost)
                    
                    EquityWinLossBarChartFromCategory(title: "Equity Games Type", equityHandsByType: equityHandsByType, isLocked: !isSubscribed, showPremiumCallback: showPremium)
                        .padding(.bottom)
                    EquityWinLossBarChartFromCategory(title: "Equity Games Street", equityHandsByType: equityHandsByStreet, isLocked: !isSubscribed, showPremiumCallback: showPremium)
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
        .navigationTitle("Equity Stats")
    }
    
    // Structs for chart rendering
    struct EquityHandsByCategory: Identifiable {
        let id = UUID()
        let category: String;
        let wins: Int;
        let losses: Int;
    }
    
    struct EquityWinLossBarChartFromCategory: View {
        let title: String
        let equityHandsByType: [EquityHandsByCategory]
        let isLocked: Bool
        let showPremiumCallback: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .fontWeight(.semibold)
                    .font(.headline)
                    

                ZStack {
                    // --- Your chart ---
                    Chart(equityHandsByType) { stat in
                        BarMark(
                            x: .value("Category", stat.category.capitalizeFirst),
                            y: .value("Wins", stat.wins)
                        )
                        .foregroundStyle(Color(red: 50/255, green: 130/255, blue: 80/255))

                        BarMark(
                            x: .value("Category", stat.category.capitalizeFirst),
                            y: .value("Losses", stat.losses)
                        )
                        .foregroundStyle(Color(red: 130/255, green: 50/255, blue: 60/255))
                    }
                    .frame(height: 164)
                    .blur(radius: isLocked ? 6 : 0)
                    .disabled(isLocked)
                    
                    if isLocked {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.1))
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 26))
                                    Text("Unlock detailed charts with premium")
                                        .font(.footnote)
                                        .opacity(0.8)
                                }
                                .foregroundColor(.white)
                            )
                            .frame(height: 170)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showPremiumCallback()
                            }
                    }
                }
            }
        }
    }


}


struct GenericStatBlock: View {
    let title: String
    let metric: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text(metric)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .padding()
        .cornerRadius(16)
        .shadow(radius: 1)
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
    }
}

struct AccuracyStatView: View {
    let winPercentage: Double
    
    var body: some View {
        VStack {
            Text("Accuracy")
                .font(.headline)
                .foregroundColor(.gray)
            Text("\(winPercentage, specifier: "%.1f")%")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .padding()
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
        game.equityHands.append(equityLog)
    }
    
    do {
        try context.save()
    } catch {
        print(error)
    }
    
    return EquityStatsView()
        .modelContainer(container)
}
