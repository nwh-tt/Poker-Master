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
    let gradientColor: Color
    let adLockedGame: Bool

    init(gameName: String, gameDescription: String, gradientColor: Color, adLockedGame: Bool = false) {
        self.gameName = gameName
        self.gameDescription = gameDescription
        self.gradientColor = gradientColor
        self.adLockedGame = adLockedGame
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
                if adLockedGame {
                    VStack {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Watch ad")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.85))
                    }
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
            LinearGradient(
                gradient: Gradient(stops: [
                        .init(color: gradientColor, location: 0.0),
                        .init(color: Color(red: 50/255, green: 55/255, blue: 60/255).opacity(0.5), location: 0.91)
                ]),
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.0), lineWidth: 3)
        )

    }
}

#Preview {
    MenuOption(gameName: "Preflop", gameDescription: "Basic Preflop", gradientColor: Color(red: 80/255, green: 15/255, blue: 25/255).opacity(0.9))
}

#Preview("Ad Locked") {
    MenuOption(
        gameName: "Equity Drill",
        gameDescription: "Watch an ad to unlock",
        gradientColor: Color(red: 15/255, green: 32/255, blue: 60/255).opacity(0.7),
        adLockedGame: true
    )
}

