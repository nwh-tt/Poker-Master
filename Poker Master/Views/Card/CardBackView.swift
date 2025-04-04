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
            RoundedRectangle(cornerRadius: 2)
                .fill(cardColor)
                .frame(width: 18, height: 25.2)
                .overlay(
                    Image(systemName: "suit.diamond.fill")
                        .resizable()
                        .frame(width: 18, height: 25)
                        .foregroundColor(borderColor)
                )
                .overlay(
                    Image(systemName: "suit.diamond.fill")
                        .resizable()
                        .frame(width: 12, height: 6)
                        .foregroundColor(cardColor)
                )
                .overlay(
                    Image(systemName: "suit.diamond.fill")
                        .resizable()
                        .frame(width: 6, height: 15)
                        .foregroundColor(cardColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white, lineWidth: 1)
                )
        }
    }
}

#Preview {
    CardBackView()
}
