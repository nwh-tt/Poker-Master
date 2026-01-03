//
//  PlayerInfoSheet.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/10/25.
//

import SwiftUI

struct PlayerInfoSheet: View {
    let player: AIPlayer
    // Mock data for now
    var stackSize: String {
        "\(player.stack.formattedString()) BB"
    }
    var investedThisHand: String {
        determineInvestedField()
    }
    
    let round: Int
    let game: Int
    
    init(player: AIPlayer, game: Int, round: Int) {
        self.player = player
        self.game = game
        self.round = round
    }
    
    func determineInvestedField() -> String {
        let latestBet = player.lastBet(game: game, round: round)
        let amountInvested = "\(latestBet.formattedString()) BB"
        
        var percent = 0.0
        if player.stack > 0 {
            percent = (latestBet / player.stack) * 100
        } else if player.stack == 0 && latestBet > 0 {
            percent = 100.0
        }
        
        return "\(amountInvested) (\(percent.formattedString())%)"
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(player.fullName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(player.position)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Divider().background(Color.gray.opacity(0.5))

            Grid(alignment: .leading, horizontalSpacing: 100, verticalSpacing: 24) {
                GridRow {
                    infoRow(title: "Stack", value: stackSize)
                    infoRow(title: "Invested", value: investedThisHand)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(
            Color.clear
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func infoRow(title: String, value: String, color: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

#Preview {
    let player = AIPlayer(name: "HERO", fullName: "p1", position: "SB", stack: 100.0)
    let _ = player.raise(amount: 9.5, game: 0, round: 1)
    PlayerInfoSheet(player: player, game: 0, round: 1)
        .preferredColorScheme(.dark)
}

