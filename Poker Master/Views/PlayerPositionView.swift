//
//  PlayerPosition.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/17/24.
//

import SwiftUI

struct PlayerPositionView: View {
    let player: Player
    // set default position to right
    let direction: String
    let isUser: Bool
    
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.5)
    
    var body: some View {
        let textOffset = direction == "right" ? 10 : -10
        let rectangleOffset = direction == "right" ? 48 : -48
        let cardOffsets = direction == "right" ? [45, 67] : [-67, -45]
        // let amount = player.folded ? "Fold" : "\(Int(player.stack)) BB"
        let textColor = player.lastMove == LastMove.fold ? Color.gray : Color.white
        
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black)
                .frame(width: 90, height: 25)
                .overlay (
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(borderColor, lineWidth: 2)
                )
                .overlay(
                    Text("\(String(format: "%.1f", player.stack)) BB")
                        .font(.system(size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .offset(CGSize(width: textOffset, height: 0))
                )
                .offset(CGSize(width: rectangleOffset, height: 0))
            Circle()
                .fill(Color.black.opacity(1))
                .frame(width: 50, height: 50)
                .overlay(Circle().stroke(borderColor, lineWidth: 2)
                ).overlay(
                    Text(player.position)
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                )
            if (player.lastMove != LastMove.none) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: 60, height: 20)
                    .overlay(
                        Text(player.isReRaise ? "ReRaise" : player.lastMove.rawValue)
                            .font(.system(size: 12))
                            .fontWeight(.heavy)
                            .foregroundColor(Color.white)
                    )
                    .offset(CGSize(width: 0, height: 30))
            }
            if (!isUser && player.lastMove != LastMove.fold) {
                CardBackView()
                    .offset(CGSize(width: cardOffsets[0], height: -30))
                CardBackView()
                    .offset(CGSize(width: cardOffsets[1], height: -30))
            }
            
        }
    }
}


#Preview {
    let player = Player(position: "BB", stack: 100.0)
    player.raise(amountRaisingTo: 2.5)
    player.raise(amountRaisingTo: 10)
    return PlayerPositionView(player: player , direction: "right", isUser: false)
}
