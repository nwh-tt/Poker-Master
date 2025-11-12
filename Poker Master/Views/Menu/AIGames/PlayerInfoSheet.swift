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
    var stackSize = ""
    var investedThisHand: String = "12 BB (18%)"
    let winRate = "+7.3 bb/100"
    let biggestWin = "142 BB Pot"
    let round = 1
    
    init(player: AIPlayer) {
        self.player = player
        self.stackSize = "\(String(format: "%.1f", player.stack)) BB"
        self.investedThisHand = determineInvestedField()
    }
    
    func determineInvestedField() -> String {
        let latestBet = player.lastBet(round: round)
        let amountInvested = "\(formatDouble(latestBet)) BB"
        
        var percent = 0.0
        if player.stack > 0 {
            percent = (latestBet / player.stack) * 100
        } else if player.stack == 0 && latestBet > 0 {
            percent = 100.0
        }
        
        return "\(amountInvested) (\(formatDouble(percent))%)"
    }
    
    func formatDouble(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            // Whole number
            return String(format: "%.0f", value)
        } else {
            // Has a decimal
            return String(format: "%.1f", value)
        }
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

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    infoRow(title: "Stack", value: stackSize)
                    Spacer()
                    infoRow(title: "Invested", value: investedThisHand)
                }

                HStack {
                    infoRow(title: "Win Rate", value: winRate, color: .green)
                    Spacer()
                    infoRow(title: "Biggest Win", value: biggestWin, color: .yellow)
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
    let _ = player.raise(amount: 9.5, round: 1)
    PlayerInfoSheet(player: player)
        .preferredColorScheme(.dark)
}

