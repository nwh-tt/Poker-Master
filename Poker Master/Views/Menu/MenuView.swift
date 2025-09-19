//
//  MenuView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 3/26/25.
//

import SwiftUI
import GoogleMobileAds

struct MenuView: View {
    @State private var showLogin = false
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @State private var navigateToEquityDrill = false
    
    @State private var rewardedAd: RewardedAd?

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
                
                VStack(spacing: 20) {
                    NavigationLink {
                        PreflopSettingsView()
                    } label: {
                        MenuOption(
                            gameName: "Basic Preflop",
                            gameDescription: "Heads-up preflop decision training",
                            gradientColor: Color(red: 80/255, green: 15/255, blue: 25/255).opacity(0.7)
                        )
                    }
                    
                    // Equity Drill
                    Button {
//                        if isSignedIn {
//                            navigateToEquityDrill = true
//                        } else {
//                            showLogin = true
//                        }
                        print("test")
                        guard let ad = rewardedAd else { return }
                        

                        if let root = UIApplication.shared.connectedScenes
                                .compactMap({ $0 as? UIWindowScene })
                                .first?.windows
                                .first?.rootViewController {
                            ad.present(from: root) {
                                let reward = ad.adReward
                                print("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
                                // TODO: Reward the user
                                navigateToEquityDrill = true
                            }
                        }
                    } label: {
                        MenuOption(
                            gameName: "Equity Drill",
                            gameDescription: "Learn Poker Equity Quickly",
                            gradientColor: Color(red: 15/255, green: 32/255, blue: 60/255).opacity(0.7)
                        )
                    }
                    
                    MenuOption(
                        gameName: "Advanced Preflop (WIP)",
                        gameDescription: "Multiway preflop with EV",
                        gradientColor: Color(red: 0.0, green: 40/255, blue: 0.0).opacity(0.9)
                    )
                }
                
                // Hidden NavigationLink for programmatic navigation
                .navigationDestination(isPresented: $navigateToEquityDrill) {
                    EquitySettingsView()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.black)
            .fullScreenCover(isPresented: $showLogin) {
                LoginViewWrapper(isSignedIn: $isSignedIn, showLogin: $showLogin, navigate: $navigateToEquityDrill)
            }
        }
        .task {
            await loadRewardedAd()
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
    MenuView()
}
