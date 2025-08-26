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
    
    @State private var showGlow = false
    @State private var confettiCounter = 0
    
    @State private var currentTier: ChallengeTier = .bronze
    
    var challenge: Challenges
    var progress: Int {
           getProgress()
    }
    
    // Get the current tier color
    init(challenge: Challenges) {
        self.challenge = challenge
        self.currentTier = getCurrentTier()
    }
    
    var currentGoal: Int {
        let tierIndex = ChallengeTier.allCases.firstIndex(of: currentTier) ?? 0
        // If progress is greater than the last goal, return the next goal
        return challenge.goals[min(tierIndex + 1, challenge.goals.count - 1)]
    }
    
    /// Whether the challenge is ready to be claimed
    var isClaimable: Bool {
        // need to check if we are at the last goal
        if (challenge.claimed.lastIndex(of: false) == nil) {
            return false
        }
        return progress >= currentGoal
    }
    
    func getProgress() -> Int {
        if (challenge.title == "Volume Player") {
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
    
    func getCurrentTier() -> ChallengeTier {
        for (index, claimed) in challenge.claimed.enumerated() {
            if !claimed {
                return ChallengeTier.allCases[index]
            }
        }
        // If all tiers claimed, return challenge.claimed.count
        if challenge.claimed.firstIndex(of: false) == nil {
            return ChallengeTier.allCases[challenge.claimed.count - 1]
        }
        // If no tiers claimed, return bronze
        return .bronze
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
    
    
    func handleClaim() {
        withAnimation(.easeInOut(duration: 0.6)) {
            // Mark as claimed
            challenge.markTierClaimed(currentTier)
            currentTier = getCurrentTier()
            // Trigger glow
            showGlow = true
        }
        confettiCounter += 1

        // Turn glow off after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.1)) {
                showGlow = false
            }
        }
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
                    .font(.custom("Exo2-Regular", size: 12))
                    .bold()
                    .foregroundColor(currentTier.color)
                Spacer()
                if isClaimable {
                    Spacer()
                    Button(action: handleClaim) {
                        Text("Claim")
                            .font(.custom("Exo2-Bold", size: 12))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(currentTier.color)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }.confettiCannon(trigger: $confettiCounter, confettiSize: 3, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)
                }
                else {
                    Text(challenge.desc)
                        .font(.custom("Exo2-Regular", size: 11))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.15))
                .shadow(color: currentTier.color.opacity(0.8), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(currentTier.color, lineWidth: showGlow ? 6 : 0)
                        .shadow(color: currentTier.color.opacity(0.8), radius: showGlow ? 12 : 0)
                        .animation(.easeInOut(duration: 0.6), value: showGlow)
                )
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
