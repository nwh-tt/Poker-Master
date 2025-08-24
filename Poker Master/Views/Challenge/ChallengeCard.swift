//
//  ChallengeCard.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/22/25.
//

import SwiftUI

struct ChallengeCard: View {
    let challenge: Challenges
    let progress: Int = 0
    
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
