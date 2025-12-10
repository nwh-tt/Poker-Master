//
//  MenuView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 3/26/25.
//

import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI

struct MenuView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var navigateToEquityDrill = false
    
    @State private var showPremiumPopup = false
    @State private var showCreateAccount = false
    
    @State private var isSubscribed = true
    
    @Query var handLogs: [PreflopLog]
    
    
    var needsAd: Bool {
        false
//        let cutoff = Calendar.current.date(byAdding: .hour, value: -12, to: Date())!
//        let recentEquityHands = handLogs.filter {
//            $0.typeOfHand == .equity && $0.date >= cutoff
//        }
//        print("Printing recent equity count: \(recentEquityHands.count)")
//        return recentEquityHands.count >= 200
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
                VStack {
                    // Header
                    HStack {
                        Image(systemName: "suit.spade.fill")
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text("Poker Master")
                            .font(.custom("Audiowide-Regular", size: 32))
                        Image(systemName: "suit.spade.fill")
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 60)
                    
                    VStack(spacing: 10) {
                        NavigationLink {
                            PreflopSettingsView()
                        } label: {
                            MenuOption(
                                gameName: "Basic Preflop",
                                gameDescription: "Heads-up preflop decision training",
                                gradientColor: Color(red: 80/255, green: 15/255, blue: 25/255).opacity(0.7)
                            )
                        }
                        
                        if (navigateToEquityDrill) {
                            NavigationLink {
                                EquitySettingsView()
                                    .onDisappear {
                                        navigateToEquityDrill = !needsAd
                                    }
                            } label: {
                                MenuOption(
                                    gameName: "Equity Drill",
                                    gameDescription: "Learn Poker Equity Quickly",
                                    gradientColor: Color(red: 15/255, green: 32/255, blue: 60/255).opacity(0.7)
                                )
                            }
                        } else {
                            Button {
                                presentEquityDrillFlow()
                            } label: {
                                MenuOption(
                                    gameName: "Equity Drill",
                                    gameDescription: "Learn Poker Equity Quickly",
                                    gradientColor: Color(red: 15/255, green: 32/255, blue: 60/255).opacity(0.7),
                                    adLockedGame: needsAd
                                )
                            }
                        }
                        
                        NavigationLink {
                            AITable(tableSize: "6")
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            MenuOption(
                                gameName: "Play AI",
                                gameDescription: "Play against a table of unique AI",
                                gradientColor: Color(red: 15/255, green: 32/255, blue: 60/255).opacity(0.7)
                            )
                        }
                        
                        MenuOption(
                            gameName: "Post Flop",
                            gameDescription: "Post Flop training with EV",
                            gradientColor: Color(red: 0.0, green: 40/255, blue: 0.0).opacity(0.9),
                            comingSoon: true
                        )
                        
                        Text("Tools")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        
                        NavigationLink {
                            RangeViewer()
                        } label: {
                            MenuOption(
                                gameName: "Ranges",
                                gameDescription: "View and edit ranges",
                                gradientColor: Color(red: 0.0, green: 40/255, blue: 0.0).opacity(0.9)
                            )
                        }
                        if !isSubscribed {
                            Button {
                                // Show premium paywall
                                showPremiumPopup = true
                            } label: {
                                Text("Go Premium for Full Access")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 20)
                        }
                        
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .fullScreenCover(isPresented: $showPremiumPopup) {
                    PaywallView()
                        .onPurchaseCompleted { customerInfo in
                            // ✅ Your logic for a successful purchase goes here.
                            print("Purchase completed successfully! Customer Info: \(customerInfo.entitlements.active)")
                            // TODO: Navigate to where the user was trying to go
                        }
                }
            }
        }
        .task {
            // await loadRewardedAd()
            isSubscribed = await SubscriptionManager.isSubscribed()
        }.preferredColorScheme(.dark)
    }
    
    
    private func presentEquityDrillFlow() {
        if !authManager.isAuthenticated {
            navigateToEquityDrill = true
            // present the create account flow
            // showCreateAccount = true
            return
        }
        
        
        navigateToEquityDrill = true
        
    }
}


#Preview {
    @Previewable @StateObject var authManager = AuthManager()
    let schema = Schema([
            Game.self,
            PreflopLog.self,
            Challenges.self,
            Profile.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Add some mock data so the preview isn't empty
        let user = Profile(username: "Ned Whittleton")
    
    
    context.insert(user)
    
    return MenuView()
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
        .environmentObject(authManager)
    
}

