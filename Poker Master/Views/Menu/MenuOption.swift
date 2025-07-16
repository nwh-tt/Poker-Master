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
            VStack {
                Image(systemName: "arrowtriangle.right.fill")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .padding()
        .padding(.leading, 4)
        .frame(maxWidth: .infinity) // <-- This makes the HStack fill available width
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
        .padding(.bottom, 8)

    }
}

#Preview {
    MenuOption(gameName: "Preflop", gameDescription: "Basic Preflop", gradientColor: Color(red: 80/255, green: 15/255, blue: 25/255).opacity(0.9))
}
