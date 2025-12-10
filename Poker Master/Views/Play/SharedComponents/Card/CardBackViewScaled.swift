//
//  CardBackViewScaled.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/11/25.
//

import SwiftUI

struct CardBackViewScaled: View {
    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.05, blue: 0.15),
                                 Color(red: 0.15, green: 0.15, blue: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 70)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
            
            
            // Central emblem
            Image(systemName: "suit.diamond.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 30)
                .foregroundColor(Color.white.opacity(0.8))
            
            // Border
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        }
        .frame(width: 50, height: 70)
    }
}

#Preview {
    CardBackViewScaled()
}
