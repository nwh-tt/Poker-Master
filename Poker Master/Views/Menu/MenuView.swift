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
    @State private var rewardedAd: RewardedAd?
    @Query var handLogs: [HandLog]
    
    var needsAd: Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
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
                    
                    // Equity Drill
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
    
    let handLogs = [
        HandLog(typeOfHand: .equity, position: .btn, hand: "AK", pair: false, action: .raise, raiseType: .open, betAmount: 10, xpEarned: 5, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -100, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .btn, hand: "AK", pair: false, action: .raise, raiseType: .open, betAmount: 10, xpEarned: 5, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .btn, hand: "QJ", pair: false, action: .call, raiseType: .vsRaise, betAmount: 15, xpEarned: 3, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .mp, hand: "99", pair: true, action: .raise, raiseType: .threeBet, betAmount: 20, xpEarned: 8, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .utg, hand: "22", pair: true, action: .call, raiseType: .vsRaise, betAmount: 5, xpEarned: 2, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, game: Game()),
    
        HandLog(typeOfHand: .equity, position: .sb, hand: "TT", pair: true, action: .call, raiseType: .open, betAmount: 12, xpEarned: 4, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .sb, hand: "TT", pair: true, action: .call, raiseType: .open, betAmount: 12, xpEarned: 4, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .sb, hand: "TT", pair: true, action: .call, raiseType: .open, betAmount: 12, xpEarned: 4, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, game: Game()),
    
        HandLog(typeOfHand: .equity, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: true, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
        HandLog(typeOfHand: .equity, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
        HandLog(typeOfHand: .preflop, position: .bb, hand: "AQ", pair: false, action: .raise, raiseType: .threeBet, betAmount: 18, xpEarned: 6, isCorrect: false, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, game: Game()),
    
        HandLog(typeOfHand: .preflop, position: .btn, hand: "KQ", pair: false, action: .raise, raiseType: .fiveBet, betAmount: 10, xpEarned: 5, isCorrect: true, date: Date(), game: Game()),
        HandLog(typeOfHand: .preflop, position: .btn, hand: "KQ", pair: false, action: .raise, raiseType: .fourBet, betAmount: 10, xpEarned: 5, isCorrect: true, date: Date(), game: Game()),
        HandLog(typeOfHand: .preflop, position: .btn, hand: "KQ", pair: false, action: .raise, raiseType: .fourBet, betAmount: 10, xpEarned: 5, isCorrect: false, date: Date(), game: Game())
    ]
    
    for handLog in handLogs {
        context.insert(handLog)
    }
    context.insert(user)
    
    return MenuView()
        .modelContainer(container)
    
}
