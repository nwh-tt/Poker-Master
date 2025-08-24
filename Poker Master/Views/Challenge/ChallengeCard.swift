//
//  ChallengeCard.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/22/25.
//

import SwiftUI
import SwiftData

struct ChallengeCard: View {
    @Query<HandLog>(sort: []) var handLogs: [HandLog]
    @Query<Game>(sort: []) var games: [Game]
    
    let challenge: Challenges
    var progress: Int {
           getProgress()
       }
    
    // Get the current tier color
    var currentTier: ChallengeTier {
        for (index, tier) in ChallengeTier.allCases.enumerated().reversed() {
            if progress >= challenge.goals[min(index, challenge.goals.count - 1)] {
                return tier
            }
        }
        return .bronze
    }
    
    var currentGoal: Int {
        let tierIndex = ChallengeTier.allCases.firstIndex(of: currentTier) ?? 0
        // If progress is greater than the last goal, return the next goal
        return challenge.goals[min(tierIndex + 1, challenge.goals.count - 1)]
    }
    
    func getProgress() -> Int {
        if (challenge.title == "Volume Player") {
            print(handLogs.count)
            return handLogs.count
        }
        else if (challenge.title == "Poker IQ") {
            return handLogs.reduce(0) { $0 + ($1.isCorrect ? 1 : 0) }
        }
        else if (challenge.title == "Pocket Rockets") {
            return handLogs.reduce(0) { $0 + ($1.pair ? 1 : 0) }
        } 
        else if (challenge.title == "Hot Hand") {
            return countStreaksOf(atLeast: 3, in: handLogs)
        } 
        else if (challenge.title == "Closer") {
            return games.count
        } 
        else if (challenge.title == "Perfect Game") {
            return games.filter { game in
                !game.hands.isEmpty && game.hands.allSatisfy { $0.isCorrect }
            }.count
        }
            
    
        return 0
    }
        
        func countStreaksOf(atLeast streakLength: Int, in hands: [HandLog]) -> Int {
            var count = 0
            var currentStreak = 0
            
            for hand in hands {
                if hand.isCorrect {
                    currentStreak += 1
                } else {
                    if currentStreak >= streakLength {
                        count += 1
                    }
                    currentStreak = 0
                }
            }
            
            // Check at the end in case the last streak reaches the requirement
            if currentStreak >= streakLength {
                count += 1
            }
            
            return count
        }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.icon)
                    .font(.title2)
                    .foregroundColor(currentTier.color)
                
                Text(challenge.title)
                    .font(.custom("Exo2-Regular", size: 18)) // headline
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(progress)/\(currentGoal)")
                    .font(.custom("Exo2-Regular", size: 14)) // subheadline
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: Double(progress), total: Double(currentGoal))
                .progressViewStyle(LinearProgressViewStyle(tint: currentTier.color))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            HStack(spacing: 2)  {
                Image(systemName: "medal.fill")
                    .font(.caption)
                    .foregroundColor(currentTier.color)
                
                Text(" \(currentTier.rawValue.capitalized)")
                    .font(.custom("Exo2-Regular", size: 12)) // caption bold
                    .bold()
                    .foregroundColor(currentTier.color)
                
                Spacer()
                
                Text(challenge.desc)
                    .font(.custom("Exo2-Regular", size: 11)) // caption2
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.15))
                .shadow(color: currentTier.color.opacity(0.8), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    ChallengeCard(challenge: Challenges(
        title: "Hands Played",
        description: "Play more hands",
        icon: "suit.club.fill",
        goals: [10, 50, 200, 500, 1000, 2000]
    ))
}
