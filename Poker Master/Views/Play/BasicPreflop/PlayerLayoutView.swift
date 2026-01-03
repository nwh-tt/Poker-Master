//
//  PlayerLayoutView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/23/25.
//
import SwiftUI

struct PlayerLayoutView: View {
    let players: [Player]   // from gameManager
    let size: String        // "6" or "9"
    
    init(players: [Player]) {
        self.players = players
        self.size = String(players.count)
    }
    
    var body: some View {
        VStack {
            if size == "6" {
                sixMaxLayout
            } else if size == "9" {
                nineMaxLayout
            } else {
                Text("Unsupported table size")
            }
        }
        .padding(4)
        .padding(.vertical, 90)
    }
    
    private var sixMaxLayout: some View {
        VStack(alignment: .center) {
            PlayerPositionView(player: players[3], direction: "right", isUser: false).padding(.top, 14)
            Spacer()
            HStack(alignment: .center)
            {
                PlayerPositionView(player: players[2], direction: "right", isUser: false)
                Spacer()
                PlayerPositionView(player: players[4], direction: "left", isUser: false)
            }
            .padding(.top, 40.0)
            .padding(.bottom, 40.0)
            Spacer()
            HStack(alignment: .center)
            {
                PlayerPositionView(player: players[1], direction: "right", isUser: false)
                Spacer()
                PlayerPositionView(player: players[5], direction: "left", isUser: false)
            }
            .padding(.top, 40.0)
            .padding(.bottom, 40.0)
            Spacer()
            PlayerPositionView(player: players[0], direction: "right", isUser: true).padding(.bottom, 14)
            
        }
    }
    
    private var nineMaxLayout: some View {
        VStack {
            HStack(alignment: .center, spacing: 60) {
                PlayerPositionView(player: players[4], direction: "right", isUser: false).padding(.top, 14)
                PlayerPositionView(player: players[5], direction: "right", isUser: false).padding(.top, 14)
            }.padding(.top, 10.0)
            
            Spacer()
            HStack(alignment: .center)
            {
                PlayerPositionView(player: players[3], direction: "right", isUser: false)
                Spacer()
                PlayerPositionView(player: players[6], direction: "left", isUser: false)
            }
            Spacer()
            HStack(alignment: .center)
            {
                PlayerPositionView(player: players[2], direction: "right", isUser: false)
                Spacer()
                PlayerPositionView(player: players[7], direction: "left", isUser: false)
            }
            Spacer()
            HStack(alignment: .center)
            {
                PlayerPositionView(player: players[1], direction: "right", isUser: false)
                Spacer()
                PlayerPositionView(player: players[8], direction: "left", isUser: false)
            }
            Spacer()
            PlayerPositionView(player: players[0], direction: "right", isUser: true)
                .padding(.bottom, 14)
        }
    }
}

#Preview {
    // var gameManger = SimplePreFlopManager(gameplaySpeed: 1,selectedPosition: "any", selectedAction: "any", size: "9")
    let players = [
        Player(position: "SB", stack: 100.0),
        Player(position: "BB", stack: 100.0),
        Player(position: "UTG", stack: 100.0),
        Player(position: "UTG1", stack: 100.0),
        Player(position: "UTG2", stack: 100.0),
        Player(position: "MP1", stack: 100.0),
        Player(position: "MP2", stack: 100.0),
        Player(position: "CO", stack: 100.0),
        Player(position: "BTN", stack: 100.0)
    ]
    PlayerLayoutView(players: players)
}
