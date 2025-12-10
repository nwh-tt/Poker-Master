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
    
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.8)
    
    var body: some View {
        let textOffset = direction == "right" ? 10 : -10
        let rectangleOffset = direction == "right" ? 48 : -48
        let cardOffsets = direction == "right" ? [45, 67] : [-67, -45]
        // let amount = player.folded ? "Fold" : "\(Int(player.stack)) BB"
        let textColor = player.lastMove == Action.fold ? Color.gray : Color.white
        
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black)
                .frame(width: 90, height: 25)
                .overlay (
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(textColor, lineWidth: 2)
                )
                .overlay(
                    Text("")
                        .countingPlayerText(to: player.stack, color: textColor, offset: textOffset)
                        .animation(.easeOut(duration: 0.3), value: player.stack)
                )
                .offset(CGSize(width: rectangleOffset, height: 0))
            Circle()
                .fill(Color.black.opacity(1))
                .frame(width: 50, height: 50)
                .overlay(Circle().stroke(textColor, lineWidth: 2)
                ).overlay(
                    Text(player.position)
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                )
            if (player.lastMove != Action.none) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black)
                    .frame(width: 60, height: 20)
                    .overlay(
                        Text(player.isReRaise ? "ReRaise" : player.lastMove.rawValue.capitalizeFirst)
                            .font(.system(size: 12))
                            .fontWeight(.heavy)
                            .foregroundColor(Color.white)
                    )
                    .offset(CGSize(width: 0, height: 30))
            }
            if (!isUser && player.lastMove != Action.fold) {
                CardBackView()
                    .offset(CGSize(width: cardOffsets[0], height: -30))
                CardBackView()
                    .offset(CGSize(width: cardOffsets[1], height: -30))
            }
            
        }
    }
}

struct CountingPlayerText: AnimatableModifier {
    var value: Double
    var textColor: Color
    var textOffset: Int
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        Text("\(value.formattedString()) BB")
            .font(.system(size: 12))
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .offset(CGSize(width: textOffset, height: 0))
    }
}



#Preview {
    let player = Player(position: "BB", stack: 100.0)
    _ = player.raise(amountRaisingTo: 2.5)
    _ = player.raise(amountRaisingTo: 10)
    return PlayerPositionView(player: player , direction: "right", isUser: false)
}
