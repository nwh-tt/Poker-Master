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
        
    var body: some View {
            VStack(spacing: 20) {
                        Text("Better Move:")
                            .font(.title)
                            .bold()
                        
                        Text(adviceText)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Got it") {
                            showPopup = false
                            resetGame()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                .padding()
                .presentationDetents([.fraction(0.67)]) // 2/3 screen height
                .presentationDragIndicator(.visible)
        }
}

#Preview {
    IncorrectSelectionView(showPopup: .constant(true), adviceText: "should have called", resetGame: {})
}
