//
//  ChallengesView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//

import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Query(sort: [SortDescriptor(\Challenges.title, order: .forward)])
        var challenges: [Challenges]
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Challenges")
                        .font(.custom("Exo2-Regular", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .purple.opacity(0.6), radius: 4, x: 0, y: 2)
                        
                    
                    ForEach(challenges) { challenge in
                        ChallengeCard(challenge: challenge)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .padding(.bottom, 8)
            .background(Color.black.ignoresSafeArea())
            
        }
}

#Preview {
    let schema = Schema([Challenges.self])
        let container = try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
    
    // Seed with some test data
    let sampleChallenges = [
        Challenges(title: "Hands Played", description: "Play 50 hands", icon: "🃏", goals: [10, 50, 200]),
        Challenges(title: "Big Wins", description: "Win 10 pots over 100 chips", icon: "💰", goals: [10, 20, 50])
    ]
    sampleChallenges.forEach { context.insert($0) }
    
    return ChallengesView()
        .modelContainer(container)
}
