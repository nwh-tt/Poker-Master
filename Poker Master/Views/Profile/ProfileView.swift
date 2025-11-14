//
//  ProfileView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//
import SwiftUI
import SwiftData
import RevenueCatUI

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var userProfileState: UserProfileState
    @EnvironmentObject var authManager: AuthManager

    @State private var tempUsername: String = ""
    @State private var isEditing: Bool = false
    @State private var showPremiumPopup: Bool = false
    @State private var showCreateAccount: Bool = false
    
    @State private var isSubscribed: Bool = true
    
    @Query var games: [Game]
    
    var currentUser: Profile {
        userProfileState.profile
    }
    // MARK: - Mock Data
    @State private var nextLevelXP: Double = 500
    var streak: Int {
        currentStreak()
    }
    @State private var selectedTheme: String = "Default"
    @State private var didLevelUp: Bool = false
    
    
    func currentStreak() -> Int {
            // Sort games by most recent date first
            let sortedGames = games.sorted { $0.date > $1.date }
            guard let mostRecent = sortedGames.first else { return 0 }
            
            var streak = 1
            var lastDate = Calendar.current.startOfDay(for: mostRecent.date)
            
            for game in sortedGames.dropFirst() {
                let gameDay = Calendar.current.startOfDay(for: game.date)
                
                // Check if gameDay is exactly 1 day before lastDate
                if let diff = Calendar.current.dateComponents([.day], from: gameDay, to: lastDate).day {
                    if diff == 1 {
                        streak += 1
                        lastDate = gameDay
                    } else if diff > 1 {
                        // Streak broken
                        break
                    }
                }
            }
            
            return streak
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
            ScrollView {
                VStack(spacing: 32) {
                    // MARK: - Avatar
                    VStack(spacing: 12) {
                        Circle()
                            .strokeBorder(.white, lineWidth: 4)
                            .background(
                                Circle().fill(Color.gray.opacity(0.2))
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "suit.spade.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                        
                        HStack(spacing: 8) {
                            if isEditing {
                                TextField("Enter username", text: $tempUsername)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .submitLabel(.done)
                                
                                Button(action: {
                                    tempUsername = userProfileState.profile.username
                                    isEditing = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                                
                                Button(action: {
                                    userProfileState.profile.username = tempUsername
                                    isEditing = false
                                    try? context.save()
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                                
                            } else {
                                Text(userProfileState.profile.username)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    tempUsername = userProfileState.profile.username
                                    isEditing = true
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.title3)
                                }
                            }
                        }

                    }
                    .padding()
                    .padding(.top, 40)



                    
                    // MARK: - Level + XP
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Level \(currentUser.level)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(currentUser.xp))/\(Int(currentUser.xpNeededForNextLevel)) XP")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                        ProgressView(
                            value: Double(currentUser.xp),
                            total: Double(currentUser.xpNeededForNextLevel)
                        )
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 50/255, green: 130/255, blue: 80/255)))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Streak Tracker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                            Text("\(streak) days in a row")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    VStack {
                        if !isSubscribed {
                            Button(action: {
                                showPremiumPopup = true
                            }) {
                                Text("Go Premium")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 19/255, green: 70/255, blue: 50/255),
                                                Color(red: 50/255, green: 130/255, blue: 80/255)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }.padding(.horizontal)
                        }
                        if !authManager.isAuthenticated {
                            Button(action: {
                                showCreateAccount = true
                            }) {
                                Text("Create Account")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white) // Text stays white
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 19/255, green: 70/255, blue: 50/255),
                                                        Color(red: 50/255, green: 130/255, blue: 80/255)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 4
                                            )
                                    )
                            }
                            .padding(.horizontal)
                        }
                    }
                    Spacer()
                    if authManager.isAuthenticated {
                        Button(action: {
                            authManager.signOut()
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                }
                
            }
            .fullScreenCover(isPresented: $showPremiumPopup) {
                PaywallView()
            }
            .fullScreenCover(isPresented: $showCreateAccount) {
                CreateAccountView()
            }.task {
                // await loadRewardedAd()
                isSubscribed = await SubscriptionManager.isSubscribed()
            }.preferredColorScheme(.dark)
            if currentUser.leveledUP {
                    LevelUpOverlay(level: currentUser.level)
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1)
                        .onAppear {
                            // auto-dismiss after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    currentUser.leveledUP = false
                                }
                            }
                        }
                }
        }
    }
    
    struct LevelUpOverlay: View {
        let level: Int
        
        var body: some View {
            VStack {
                Text("Level Up!")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.yellow)
                    .shadow(radius: 10)
                Text("You reached Level \(level)")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.6))
            .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    @Previewable @StateObject var authManager = AuthManager()
    let schema = Schema([
            Game.self,
            HandLog.self,
            Challenges.self,
            Item.self,
            Profile.self
        ])
        let container = try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
    
    // Seed with some test data
    let sampleUser = Profile(username: "Ned Whittleton")
    
    // insert one game from yesterday
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    let sampleGame = Game(gameType: .preFlop)
    sampleGame.duration = 1000
    sampleGame.date = yesterday
    context.insert(sampleGame)
    
    // insert one game from today
    let sampleGame2 = Game(gameType: .preFlop)
    sampleGame2.duration = 1000
    sampleGame2.date = Date()
    
    context.insert(sampleUser)
    
    return ProfileView()
        .preferredColorScheme(.dark)
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
        .environmentObject(authManager)
}
