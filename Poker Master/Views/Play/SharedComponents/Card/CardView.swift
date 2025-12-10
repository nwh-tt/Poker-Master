//
//  CardView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/11/24.
//

import SwiftUI

struct CardView: View {
    // Takes in a suit and value
    let card: Card
    
    
    var body: some View {
        let color: Color = card.suit == "heart" || card.suit == "diamond" ? .red : .black
        
        
        
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
                .frame(width: 50, height: 70)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
            VStack {
                Text(card.rank)
                    .frame(width: 57, alignment: .leading)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .padding(.bottom, -8)
                    .padding(.leading, 12)
                Image(systemName: "suit.\(card.suit).fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundColor(color)
                    .padding(.bottom, 20)
                    
            }
        }
    }
}

#Preview {
    CardView(card: Card(suit: "heart", rank: "10"))
}
