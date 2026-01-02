//
//  MenuOption.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/10/25.
//

import SwiftUI

struct MenuOption: View {
    let gameName: String
    let gameDescription: String
    let gradientColor: [Color]
    let locked: Bool
    let comingSoon: Bool

    init(gameName: String, gameDescription: String, gradientColor: [Color], locked: Bool = false, comingSoon: Bool = false) {
        self.gameName = gameName
        self.gameDescription = gameDescription
        self.gradientColor = gradientColor
        self.locked = locked
        self.comingSoon = comingSoon
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
            if locked {
                VStack {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: 15, height: 15)
                        .padding()
                }
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
}

#Preview {
    MenuOption(gameName: "Preflop", gameDescription: "Basic Preflop", gradientColor: [Color(red: 0.18, green: 0.26, blue: 0.30).opacity(0.80), Color(red: 0.10, green: 0.15, blue: 0.18).opacity(0.80)]
    )
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

