//
//  MainView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedTab = 2
    
    init() {
           let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor(Color.black)
           tabBarAppearance.barTintColor = UIColor(Color.black) // Legacy fallback
           tabBarAppearance.unselectedItemTintColor = UIColor.gray
           tabBarAppearance.tintColor = UIColor.gray
       }

       var body: some View {
           ZStack(alignment: .bottom) {
                   TabView(selection: $selectedTab) {
                       HomeView()
                           .tabItem {
                               Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                                   .environment(\.symbolVariants, .none)
                           }
                           .tag(0)
                       
                       ChallengesView()
                           .tabItem {
                               Image(systemName: selectedTab == 1 ? "trophy.fill" : "trophy")
                                   .environment(\.symbolVariants, .none)
                           }
                           .tag(1)
                       
                       MenuView()
                           .tabItem {
                               Image(systemName: selectedTab == 2 ? "play.circle.fill" : "play.circle")
                                   .environment(\.symbolVariants, .none)
                               
                           }
                           .tag(2)
                       
                       StatsView()
                           .tabItem {
                               Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                                   .environment(\.symbolVariants, .none)
                           }
                           .tag(3)
                       
                       ProfileView()
                           .tabItem {
                               Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                                   .environment(\.symbolVariants, .none)
                           }
                           .tag(4)
                   }
                   .accentColor(.white)
                   .background(Color.black.edgesIgnoringSafeArea(.bottom))
               
               
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

        return
    
    MainView()
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
}
