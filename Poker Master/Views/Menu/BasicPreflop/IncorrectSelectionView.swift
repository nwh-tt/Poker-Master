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
    var resetGame: () -> Void  // Closure to reset game
    let keyUsed: String
    let hand: String
    
    var body: some View {
            VStack(spacing: 10) {
                        Text(adviceText)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 0)
                            .padding(.top, 16)
                            .foregroundColor(.white)
                        RangesView(key: extractKeyUsed(), hand: hand)
                    
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
    }
    
    
    func extractKeyUsed() -> String {
        // split on underscore
        let parts = keyUsed.split(separator: "_")
        // drop off last part
        return String(parts.dropLast().joined(separator: "_"))
    }
}

#Preview {
    IncorrectSelectionView(showPopup: .constant(true), adviceText: "Should have called", resetGame: {}, keyUsed: "open_BTN_raise", hand: "T6s")
}
