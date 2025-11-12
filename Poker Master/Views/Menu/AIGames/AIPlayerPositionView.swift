//
//  PlayerPosition.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/17/24.
//

import SwiftUI

struct AIPlayerPositionView: View {
    @State private var showPlayerPopup = false
    
    let player: AIPlayer
    // set default position to right
    let direction: String
    let isUser: Bool
    let game: Int
    let round: Int
    
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.8)
    
    var body: some View {
        let textOffset = direction == "right" ? 10 : -10
        let rectangleOffset = direction == "right" ? 48 : -48
        let cardOffsets = direction == "right" ? [45, 67] : [-67, -45]
        // let amount = player.folded ? "Fold" : "\(Int(player.stack)) BB"
        let textColor = player.lastMove(game: game) == Action.fold ? Color.gray : Color.white
        if player.isOutOfMoney(game: game) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.clear)
                    .frame(width: 90, height: 25)
                    .overlay(
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 50, height: 50)
                )
            }
        }
        else {
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
                        Text(player.name)
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                    )
                ZStack {
                    if player.lastMoveForRound(game: game, round: round) != .none {
                        HStack(spacing: 4) {
                            if player.lastMoveForRound(game: game, round: round) == .raise {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                Text("\(player.lastBet(game: game, round: round).formattedString()) BB")
                                    .font(.system(size: 12))
                                    .fontWeight(.heavy)
                                    .foregroundColor(.white)
                            } else {
                                Text(
                                    player.lastMoveForRound(game: game, round: round).rawValue.capitalizeFirst
                                )
                                .font(.system(size: 12))
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.6))
                                .shadow(color: Color.white.opacity(0.15), radius: 4, x: 0, y: 0)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .offset(y: 30)
                        .opacity(1)
                    } else {
                        // Invisible placeholder to allow smooth transition
                        Text("")
                            .opacity(0)
                            .offset(y: 30)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: player.lastMoveForRound(game: game, round: round))
                if (!isUser && player.lastMove(game: game) != Action.fold) {
                    CardBackView()
                        .offset(CGSize(width: cardOffsets[0], height: -30))
                    CardBackView()
                        .offset(CGSize(width: cardOffsets[1], height: -30))
                }
                
            }
        }
    }
}

#Preview {
    let player = AIPlayer(name: "ATW", fullName: "test", position: "BB", stack: 100.0)
    //player.raise(amountRaisingTo: 2.5)
    let _ = player.raise(amount: 20, game: 1, round: 0)
    return AIPlayerPositionView(player: player, direction: "right", isUser: true, game: 1, round: 0)
}
