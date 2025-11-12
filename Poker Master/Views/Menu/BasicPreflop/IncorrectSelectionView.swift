//
//  IncorrectSelectionView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 3/24/25.
//

import SwiftUI

struct IncorrectSelectionView: View {
    @Binding var showPopup: Bool
    var adviceText: String
    let keyUsed: String
    let hand: String
    let playerCount: String
    
    
    var body: some View {
            VStack(spacing: 10) {
                        Text(adviceText)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 0)
                            .padding(.top, 16)
                            .foregroundColor(.white)
                RangesView(key: keyUsed, hand: hand, playerCount: playerCount)
                    
                        Button("Got it") {
                            showPopup = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                .padding()
                .presentationDetents([.fraction(0.75)]) // 3/4 screen height
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
    }
        
}

#Preview {
    IncorrectSelectionView(showPopup: .constant(true), adviceText: "Should have called", keyUsed: "open_BTN", hand: "T6s", playerCount: "9")
}
