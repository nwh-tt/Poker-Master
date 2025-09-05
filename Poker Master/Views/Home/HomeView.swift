import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Environment
    @EnvironmentObject var userProfileState: UserProfileState
    
    var userProfile: User {
        userProfileState.user
    }    // MARK: - Sample Data
    // Sample articles
    // Sample categorized articles
    let categoryOrder = ["Preflop", "Postflop", "Bankroll", "Tournaments"]
        let categorizedArticles: [String: [(title: String, subtitle: String, url: String)]] = [
            "Preflop": [
                ("Opening Ranges", "Optimal preflop hand selection", "https://www.pokernews.com/strategy/preflop.htm"),
                ("3-Bet Strategy", "How to 3-bet effectively", "https://www.pokerstrategy.com/strategy/3bet")
            ],
            "Postflop": [
                ("Continuation Bets", "When to c-bet on the flop", "https://www.pokernews.com/strategy/c-bet.htm"),
                ("Bluffing Spots", "Identifying profitable bluffs", "https://www.pokerstrategy.com/strategy/bluff")
            ],
            "Bankroll": [
                ("Bankroll Management", "Keep your poker finances in check", "https://www.pokerstrategy.com/bankroll"),
                ("Variance Understanding", "Manage swings and variance", "https://www.pokernews.com/strategy/variance.htm")
            ],
            "Tournaments": [
                ("Early Stage Strategy", "How to play early in tournaments", "https://www.pokerstrategy.com/strategy/early-stage"),
                ("ICM Concepts", "Independent Chip Model explained", "https://www.pokernews.com/strategy/icm.htm")
            ]
        ]
    @State private var expandedCategories: Set<String>

    init() {
        // Open all categories by default
        _expandedCategories = State(initialValue: Set(categorizedArticles.keys))
    }
    
    var body: some View {
        NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Level & XP Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Level \(userProfile.level)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            ProgressView(value: Double(userProfile.xp), total: Double(userProfile.xpNeededForNextLevel))
                                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text("\(userProfile.xp)/\(userProfile.xpNeededForNextLevel) XP")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                        
                        // MARK: - Quick Actions
                        HStack(spacing: 16) {
                            NavigationLink(destination: PreflopSettingsView()) {
                                ActionButton(title: "Play Game", color1: .blue, color2: .purple, icon: "play.fill")
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Collapsible Learning Resources
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(categoryOrder, id: \.self) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Category header
                                    HStack {
                                        Text(category)
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                                            .foregroundColor(.purple)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if expandedCategories.contains(category) {
                                            expandedCategories.remove(category)
                                        } else {
                                            expandedCategories.insert(category)
                                        }
                                    }
                                    
                                    // Article cards
                                    if expandedCategories.contains(category) {
                                        VStack(spacing: 12) {
                                            ForEach(categorizedArticles[category]!, id: \.url) { article in
                                                Link(destination: URL(string: article.url)!) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(article.title)
                                                                .font(.headline)
                                                                .foregroundColor(.white)
                                                            Text(article.subtitle)
                                                                .font(.subheadline)
                                                                .foregroundColor(.gray)
                                                        }
                                                        Spacer()
                                                        Image(systemName: "arrow.up.right.square")
                                                            .foregroundColor(.purple)
                                                    }
                                                    .padding()
                                                    .background(Color.gray.opacity(0.15))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                            }
                                        }
                                        .transition(.opacity.combined(with: .slide))
                                    }
                                }
                                .animation(.easeInOut, value: expandedCategories)
                            }
                        }
                    }
                    
                    .padding()
                }
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .navigationTitle("Home")
            
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let color1: Color
    let color2: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
            Text(title)
                .foregroundColor(.white)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [color1, color2], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(radius: 4)
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
    
    return HomeView()
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
        
}
