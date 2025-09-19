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
    
    var sortedChallenges: [Challenges] {
            challenges.sorted { c1, c2 in
                let tier1 = c1.claimed.lastIndex(of: true) ?? -1
                let tier2 = c2.claimed.lastIndex(of: true) ?? -1
                return tier1 > tier2
            }
        }
    
    
        
    var body: some View {
            NavigationStack {
                        // Scrollable challenge cards
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(sortedChallenges) { challenge in
                                    ChallengeCard(challenge: challenge)
                                }
                                Spacer(minLength: 16)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40) // leave room for tab bar
                        }.padding(.top)
                    
                .navigationTitle("Challenges")
            }
            .preferredColorScheme(.dark)
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
    let sampleChallenges = [
        Challenges(title: "Volume Player", description: "Play 50 hands", icon: "suit.club.fill", goals: [10, 50, 200]),
        Challenges(title: "Poker IQ", description: "Win 10 pots over 100 chips", icon: "brain.fill", goals: [10, 20, 50]),
        Challenges(title: "Pocket Rockets", description: "Hit pocket pairs", icon: "die.face.2.fill", goals: [5, 20, 100, 300, 800, 1500]),
        Challenges(title: "Hot Hand", description: "Correct 3 times in a row", icon: "flame.fill", goals: [5, 20, 100, 300, 800, 1500]),
        Challenges(title: "Closer", description: "Finish full matches", icon: "target", goals: [5, 20, 100, 300, 800, 1500]),
        Challenges(title: "Perfect Game", description: "Games without errors", icon: "crown.fill", goals: [5, 20, 100, 300, 800, 1500])
    ]
    sampleChallenges[0].claimed = [true, true, false]
    sampleChallenges.forEach { context.insert($0) }
    
    // Add in sample game and sample hands
    let sampleGame = Game(date: Date(), totalHands: 0, duration: 0.0)
    context.insert(sampleGame)
    // Loop through and add 21 hands to the handlog
    for _ in 1...250 {
        let sampleHandLog = HandLog(typeOfHand: .preflop, position: .sb, hand: "AsAs", pair: true, action: .call, raiseType: .open, betAmount: 0, pot: 0, xpEarned: 0, isCorrect: false, game: sampleGame)
        context.insert(sampleHandLog)
    }
    
    return ChallengesView()
        .modelContainer(container)
}
