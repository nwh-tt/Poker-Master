//
//  MainView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 2
    
    init() {
           let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor(Color.black)
           tabBarAppearance.barTintColor = UIColor(Color.black) // Legacy fallback
           tabBarAppearance.unselectedItemTintColor = UIColor.gray
           tabBarAppearance.tintColor = UIColor.white
       }

       var body: some View {
           TabView(selection: $selectedTab) {
               HomeView()
                   .tabItem {
                       Image(systemName: "house.fill")
                   }
                   .tag(0)
               
               ChallengesView()
                   .tabItem {
                       Image(systemName: "trophy.fill")
                   }
                   .tag(1)
               MenuView()
                   .tabItem {
                       Image(systemName: "play.circle.fill")
                   }
                   .tag(2)
               StatsView()
                   .tabItem {
                       Image(systemName: "chart.bar.fill")
                   }
                   .tag(3)
               ProfileView()
                   .tabItem {
                       Image(systemName: "person.fill")
                   }
                   .tag(4)
           }
           .accentColor(.white)
           .background(Color.black.edgesIgnoringSafeArea(.bottom))
       }
   
}

#Preview {
    MainView()
}
