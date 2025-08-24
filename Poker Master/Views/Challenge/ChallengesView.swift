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
    let schema = Schema([
            Game.self,
            HandLog.self,
            Challenges.self,
            Item.self
        ])
        let container = try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
    
    // Seed with some test data
    let sampleChallenges = [
        Challenges(title: "Volume Player", description: "Play 50 hands", icon: "suit.club.fill", goals: [10, 50, 200]),
        Challenges(title: "Poker IQ", description: "Win 10 pots over 100 chips", icon: "brain.fill", goals: [10, 20, 50]),
        Challenges(title: "Pocket Rockets", description: "Hit pocket pairs", icon: "die.face.2.fill", goals: [5, 20, 100, 300, 800, 1500]),
        Challenges(title: "Hot Hand", description: "Correct 3 times in a row", icon: "flame.fill", goals: [5, 20, 100, 300, 800, 1500]),
        Challenges(title: "Closer", description: "Finish full matches", icon: "target", goals: [5, 20, 100, 300, 800, 1500]),
        Challenges(title: "Perfect Game", description: "Games without errors", icon: "target", goals: [5, 20, 100, 300, 800, 1500])
    ]
    sampleChallenges.forEach { context.insert($0) }
    
    // Add in sample game and sample hands
    let sampleGame = Game(date: Date(), totalHands: 0, duration: 0.0)
    context.insert(sampleGame)
    let sampleHandLog = HandLog(typeOfHand: "Preflop", position: "SB", hand: "AsAs", pair: true, action: "Call", raiseType: "", betAmount: 0, pot: 0, xpEarned: 0, isCorrect: false, game: sampleGame)
    context.insert(sampleHandLog)
    
    return ChallengesView()
        .modelContainer(container)
}
