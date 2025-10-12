//
//  CardBackView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/22/24.
//

import SwiftUI
// import the PlayingCardBack image


struct CardBackView: View {
    let cardColor: Color = .blue.opacity(0.8)
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.8)
    
    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.05, blue: 0.15),
                                 Color(red: 0.15, green: 0.15, blue: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18, height: 25.2)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
            
            
            // Central emblem
            Image(systemName: "suit.diamond.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 8)
                .foregroundColor(Color.white.opacity(0.8))
            
            // Border
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        }.frame(width: 18, height: 25.2)
    }
}

#Preview {
    CardBackView()
}
