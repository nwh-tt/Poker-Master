//
//  MenuOption.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/10/25.
//

import SwiftUI

enum QuotaSeverity {
    case normal   // lots remaining
    case warning  // getting close
    case danger   // very close / locked soon
}

struct MenuOption: View {
    let gameName: String
    let gameDescription: String
    let gradientColor: [Color]
    let locked: Bool
    let comingSoon: Bool
    
    let playedFreeHands: Int
    
    let quotaText: String

    @State private var showQuotaInfo = false

    init(
            gameName: String,
            gameDescription: String,
            gradientColor: [Color],
            locked: Bool = false,
            comingSoon: Bool = false,
            playedFreeHands: Int = 0,
            freeHandLimit: Int = 20
    ) {
        self.gameName = gameName
        self.gameDescription = gameDescription
        self.gradientColor = gradientColor
        self.locked = locked
        self.comingSoon = comingSoon
        
        self.playedFreeHands = playedFreeHands
        
        // calculate quota clamped on 0
        self.quotaText = "\(max(freeHandLimit - playedFreeHands, 0)) left"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gameName)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                Text(gameDescription)
                    .font(.custom("Exo2-Italic", size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            HStack {
                if playedFreeHands > 0 {
                    quotaBadge(quotaText)
                }
                
                if locked {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: 15, height: 15)
                        .padding()
                    
                }
                else if comingSoon {
                    Text("Coming\nsoon")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.85))
                } else {
                    Image(systemName: "arrowtriangle.right.fill")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.white)
                        .padding()
                    
                }
            }
        }
        .padding()
        .padding(.leading, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            LinearGradient(colors: gradientColor, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.0), lineWidth: 3)
        )

    }
    
    @ViewBuilder
        private func quotaBadge(_ text: String) -> some View {
            // If you want the badge itself tappable for info, keep this Button.
            // If you don't want interactivity, replace Button with a plain view.
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
}

#Preview {
    MenuOption(gameName: "Preflop", gameDescription: "Basic Preflop", gradientColor: [Color(red: 0.18, green: 0.26, blue: 0.30).opacity(0.80), Color(red: 0.10, green: 0.15, blue: 0.18).opacity(0.80)], playedFreeHands: 19)
}

#Preview("Locked - limit hit") {
    MenuOption(
        gameName: "Equity Drill",
        gameDescription: "Watch an ad to unlock",
        gradientColor: [Color(red: 0.18, green: 0.26, blue: 0.30).opacity(0.80), Color(red: 0.10, green: 0.15, blue: 0.18).opacity(0.80)],
        locked: true

    )
}

#Preview("Coming soon") {
    MenuOption(
        gameName: "Equity Drill",
        gameDescription: "Watch an ad to unlock",
        gradientColor: [Color(red: 0.18, green: 0.26, blue: 0.30).opacity(0.80), Color(red: 0.10, green: 0.15, blue: 0.18).opacity(0.80)],
        comingSoon: true
    )
}

