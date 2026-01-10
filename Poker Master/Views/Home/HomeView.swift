import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Environment
    @EnvironmentObject var userProfileState: UserProfileState
    
    var userProfile: Profile {
        userProfileState.profile
    }    // MARK: - Sample Data
    // Sample articles
    // Sample categorized articles
    let categoryOrder = ["Preflop", "Postflop", "Bankroll", "Tournaments"]
        let categorizedArticles: [String: [(title: String, subtitle: String, url: String)]] = [
            "Preflop": [
                ("Opening Ranges", "Optimal preflop hand selection", "https://www.pokernews.com/poker-range-charts"),
                ("Preflop Betting Strategy", "How to bet effectively", "https://www.thepokerbank.com/strategy/hand-guide/preflop/")
            ],
            "Postflop": [
                ("Flop Analysis", "How to analyze the flop", "https://www.pokerprofessor.com/university/how-to-win-at-poker/post-flop-strategy"),
                ("Bluffing Spots", "Strategy for bluffing opportunities", "https://www.888poker.com/magazine/strategy/poker-bluff")
            ],
            "Bankroll": [
                ("Bankroll Management", "Keep your poker finances in check", "https://www.pokernews.com/strategy/an-introduction-to-bankroll-management-19610.htm"),
                ("Variance Understanding", "Manage swings and variance", "https://blog.gtowizard.com/variance-and-bankroll-management/")
            ],
            "Tournaments": [
                ("Early Stage Strategy", "How to play early in tournaments", "https://www.pokerstrategy.com/strategy/early-stage"),
                ("ICM Concepts", "Independent Chip Model explained", "https://blog.gtowizard.com/icm-basics/")
            ]
        ]
    @State private var expandedCategories: Set<String>

    init() {
        // Open all categories by default
        _expandedCategories = State(initialValue: Set(categorizedArticles.keys))
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
                ScrollView {
                        LazyVStack(spacing: 24) {
                            
                            // MARK: - Level & XP Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Level \(userProfile.level)")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                ProgressView(value: Double(userProfile.xp), total: Double(userProfile.xpNeededForNextLevel))
                                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 50/255, green: 130/255, blue: 80/255)))
                                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Text("\(userProfile.xp)/\(userProfile.xpNeededForNextLevel) XP")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 1)
                            
                            // MARK: - Quick Actions
                            HStack(spacing: 16) {
                                NavigationLink(destination: PreflopSettingsView()) {
                                    ActionButton(title: "Quick Start", icon: "play.fill")
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
                                                .foregroundColor(Color(red: 50/255, green: 130/255, blue: 80/255))
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
                                                                .foregroundColor(Color(red: 50/255, green: 130/255, blue: 80/255))
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
                .navigationTitle("Home")
            }
            
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
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
            LinearGradient(colors: [Color(red: 19/255, green: 70/255, blue: 50/255),
                                    Color(red: 50/255, green: 130/255, blue: 80/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

#Preview {
    let schema = Schema([
            Game.self,
            PreflopLog.self,
            Challenges.self,
            Profile.self
        ])
        let container = try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
    
    // Seed with some test data
    let sampleUser = Profile(username: "Ned Whittleton")
    sampleUser.addXP(amount: 140)
    
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
    
    return HomeView()
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
        
}
