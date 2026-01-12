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
    @EnvironmentObject var userProfile: UserProfileState
    
    @State private var navigateToEquityDrill = false
    
    @State private var navigateToAITable = false
    
    @State private var showPremiumPopup = false
    @State private var showCreateAccount = false
    
    @State private var isSubscribed = true
    
    private var recentAIHandsCount: Int {
        userProfile.aiHandsCount()
    }
    
    private var recentEquityHandsCount: Int {
        userProfile.equityHandsCount()
    }
    
    private var hitEquityLimit: Bool {
        userProfile.hitEquityLimit(isSubscribed: isSubscribed)
    }
    
    private var hitAILimit: Bool {
        userProfile.hitAILimit(isSubscribed: isSubscribed)
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
                                gradientColor: [
                                    Color(red: 0.40, green: 0.15, blue: 0.22).opacity(0.70),
                                    Color(red: 0.16, green: 0.05, blue: 0.10).opacity(0.80)
                                ]
                            )
                        }
                        
                        Button {
                            if !hitEquityLimit || isSubscribed {
                                navigateToEquityDrill = true
                            } else {
                                showPremiumPopup = true
                            }
                        } label: {
                            MenuOption(
                                gameName: "Equity Drill",
                                gameDescription: "Learn Poker Equity Quickly",
                                gradientColor: [
                                    Color(red: 0.08, green: 0.17, blue: 0.28).opacity(0.80),
                                    Color(red: 0.04, green: 0.08, blue: 0.18).opacity(0.72)
                                ],
                                locked: hitEquityLimit && !isSubscribed,
                                playedFreeHands: !isSubscribed ? recentEquityHandsCount : 0
                            )
                        }.navigationDestination(isPresented: $navigateToEquityDrill) {
                            EquitySettingsView()
                        }
                        
                        Button {
                            if !hitAILimit || isSubscribed {
                                navigateToAITable = true
                            } else {
                                showPremiumPopup = true
                            }
                        } label: {
                            MenuOption(
                                gameName: "Play AI",
                                gameDescription: "Play against a table of unique AI",
                                gradientColor: [
                                    Color(red: 0.18, green: 0.26, blue: 0.30).opacity(0.80),
                                    Color(red: 0.10, green: 0.15, blue: 0.18).opacity(0.60)
                                ],
                                locked: hitAILimit && !isSubscribed,
                                playedFreeHands: !isSubscribed ? recentAIHandsCount : 0
                            )
                        }.navigationDestination(isPresented: $navigateToAITable) {
                            AITable(tableSize: "6")
                                .toolbar(.hidden, for: .tabBar)
                        }
                        
                        MenuOption(
                            gameName: "Post Flop",
                            gameDescription: "Post Flop training with EV",
                            gradientColor: [
                                Color(red: 0.12, green: 0.25, blue: 0.18).opacity(0.80),
                                Color(red: 0.06, green: 0.18, blue: 0.10).opacity(0.60)
                            ],
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
                                gradientColor: [
                                    Color(red: 0.34, green: 0.18, blue: 0.40).opacity(0.60),
                                    Color(red: 0.16, green: 0.08, blue: 0.20).opacity(0.60)
                                ]
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
                            if customerInfo.entitlements["Premium Subscription"]?.isActive == true {
                                isSubscribed = true
                            }
                        }
                }
            }
        }
        .task {
            isSubscribed = await SubscriptionManager.isSubscribed()
        }.preferredColorScheme(.dark)
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

