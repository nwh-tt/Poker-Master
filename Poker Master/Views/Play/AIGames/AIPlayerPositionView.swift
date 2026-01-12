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
    var isShowdown: Bool
    let isWinner: Bool
    
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.8)
    
    var body: some View {
        let textOffset = direction == "right" ? 10 : -10
        let rectangleOffset = direction == "right" ? 48 : -48
        let cardOffsets = direction == "right" ? [45, 67] : [-67, -45]
        // let amount = player.folded ? "Fold" : "\(Int(player.stack)) BB"
        let textColor = player.lastMove(game: game) == Action.fold ? Color.gray : Color.white
        let nameColor = isShowdown && isWinner ? Color.yellow.opacity(0.9) : textColor
        if player.isOutOfMoney(game: game) && player.hand.isEmpty {
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
                ZStack {
                    if isShowdown && isWinner {
                        Circle()
                            .fill(Color.yellow.opacity(0.25))
                            .frame(width: 64, height: 64)
                            .blur(radius: 6)
                            .transition(.opacity)
                    }

                    Circle()
                        .fill(Color.black.opacity(1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.yellow.opacity(0.6), lineWidth: 5)
                                .opacity(isShowdown && isWinner ? 1 : 0)
                                .animation(.easeInOut(duration: 0.25), value: isWinner)
                        )
                        .overlay(Circle().stroke(textColor, lineWidth: 2))
                        .overlay(
                            Text(player.name)
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(nameColor)
                        )
                        .overlay {
                            if isShowdown && isWinner {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.yellow.opacity(0.7))
                                    .offset(x: 0.0, y: -16.0)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: isWinner)
                }
                .animation(.easeInOut(duration: 0.25), value: isWinner)
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
                if (!isUser  && player.hand.count == 2 && player.lastMove(game: game) != Action.fold) {
                    FlippingCardView(
                        front: CardView(card: player.hand[0]),
                        back: CardBackView(),
                        isFaceUp: isShowdown,
                        offset: CGSize(width: cardOffsets[0], height: isShowdown ? -34 : -30)
                    )

                    FlippingCardView(
                        front: CardView(card: player.hand[1]),
                        back: CardBackView(),
                        isFaceUp: isShowdown,
                        offset: CGSize(width: cardOffsets[1], height: isShowdown ? -34 : -30)
                    )
                } else {
                    ZStack {
                        // Hacky way to hold space (minimizes layouts moving around)
                        CardView(card: Card(suit: "heart", rank: "K"))
                            .scaleEffect(0.5)
                            .offset(y: -34)
                    }.opacity(0)
                }
                
            }.preferredColorScheme(.dark)
        }
    }
}

struct FlippingCardView<Front: View, Back: View>: View {
    let front: Front
    let back: Back
    let isFaceUp: Bool
    let offset: CGSize

    var body: some View {
        ZStack {
            // FRONT
            front
                .scaleEffect(0.5)
                .opacity(isFaceUp ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFaceUp ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )

            // BACK
            back
                //.scaleEffect(size * 0.8)        // back is slightly smaller
                .opacity(isFaceUp ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFaceUp ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .offset(offset)
        .animation(.easeInOut(duration: 0.6), value: isFaceUp)
    }
}

#Preview {
    let player = AIPlayer(name: "YOU", fullName: "test", position: "BB", stack: 100.0)
    player.hand = [Card(suit: "heart", rank: "2"), Card(suit: "heart", rank: "2")]
    
    //player.raise(amountRaisingTo: 2.5)
    //let _ = player.fold(game: 0, round: 0)
    return AIPlayerPositionView(player: player, direction: "left", isUser: false, game: 1, round: 0, isShowdown: true, isWinner: true)
}
