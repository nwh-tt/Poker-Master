//
//  ProfileView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//
import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var userProfileState: UserProfileState
    @Query var games: [Game]
    
    var currentUser: User {
        userProfileState.user
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
        ScrollView {
            VStack(spacing: 32) {
                
                // MARK: - Avatar
                VStack {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text("👤")
                                .font(.largeTitle)
                        )
                    Text(currentUser.username)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                }
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
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal)
                
                // MARK: - Theme Selector Scaffold
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack {
                        Text(selectedTheme)
                            .foregroundColor(.gray)
                        Spacer()
                        Button("Change") {
                            // action to change theme
                        }
                        .foregroundColor(.green)
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
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
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
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
        let container = try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
    
    // Seed with some test data
    let sampleUser = User(username: "Ned Whittleton")
    sampleUser.addXP(amount: 140)
    
    // insert one game from yesterday
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    let sampleGame = Game()
    sampleGame.duration = 1000
    sampleGame.date = yesterday
    context.insert(sampleGame)
    
    // insert one game from today
    let sampleGame2 = Game()
    sampleGame2.duration = 1000
    sampleGame2.date = Date()
    
    context.insert(sampleUser)
    
    return ProfileView()
        .preferredColorScheme(.dark)
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
}
