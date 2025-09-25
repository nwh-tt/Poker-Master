//
//  MenuView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 3/26/25.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

struct MenuView: View {
    @State private var showLogin = false
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @State private var navigateToEquityDrill = false
    @State private var showPremiumPopup = false
    @State private var rewardedAd: RewardedAd?
    @Query var handLogs: [HandLog]
    
    var needsAd: Bool {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -12, to: Date())!
        let recentEquityHands = handLogs.filter {
            $0.typeOfHand == .equity && $0.date >= cutoff
        }
        print("Printing recent equity count: \(recentEquityHands.count)")
        return recentEquityHands.count >= 20
    }

    var body: some View {
        NavigationStack {
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
                .padding(.bottom, 120)
                
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
                    
                    Button {
                           // Show premium paywall
                           showPremiumPopup = true
                       } label: {
                           Text("Go Premium for no Ads")
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
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.black)
            .fullScreenCover(isPresented: $showLogin) {
                LoginViewWrapper(isSignedIn: $isSignedIn, showLogin: $showLogin, navigate: $navigateToEquityDrill)
            }
            .fullScreenCover(isPresented: $showPremiumPopup) {
                SubscribeView()
            }
        }
        .task {
            // await loadRewardedAd()
        }
    }
    
    // MARK: - Rewarded Ad Functions
        func loadRewardedAd() async {
            do {
                rewardedAd = try await RewardedAd.load(
                    with: "ca-app-pub-3940256099942544/1712485313", // test ad unit
                    request: Request()
                )
            } catch {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
            }
        }
    
    private func presentEquityDrillFlow() {
        // If you want to gate by sign-in, uncomment this block
        // if isSignedIn {
        //     navigateToEquityDrill = true
        //     return
        // } else {
        //     showLogin = true
        //     return
        // }
        if needsAd {
            guard let ad = rewardedAd else {
                print("Rewarded ad not ready")
                return
            }
            
            if let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .first(where: { $0.isKeyWindow })?
                .rootViewController {
                ad.present(from: root) {
                    let reward = ad.adReward
                    print("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
                    // TODO: Reward the user
                    navigateToEquityDrill = true
                }
            } else {
                print("Unable to find root view controller to present from")
            }
        } else {
            navigateToEquityDrill = true
        }
    }
}

// Wrapper to connect LoginView completion with MenuView navigation
struct LoginViewWrapper: View {
    @Binding var isSignedIn: Bool
    @Binding var showLogin: Bool
    @Binding var navigate: Bool

    var body: some View {
        LoginView()
            .onChange(of: isSignedIn) { newValue, oldValue in
                if newValue {
                    // Dismiss login and navigate
                    showLogin = false
                    navigate = true
                }
            }
    }
}



#Preview {
    let schema = Schema([
            Game.self,
            HandLog.self,
            Challenges.self,
            Item.self,
            User.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Add some mock data so the preview isn't empty
        let user = User(username: "Ned Whittleton")
    
    
    context.insert(user)
    
    return MenuView()
        .modelContainer(container)
    
}
