//
//  PlayerLayoutView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/23/25.
//
import SwiftUI

struct AIPlayerLayoutView: View {
    let players: [AIPlayer]   // from gameManager
    let size: String        // "6" or "9"
    
    init(players: [AIPlayer]) {
        self.players = players
        self.size = String(players.count)
        
        print("Players count: \(players.count)")
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
            AIPlayerPositionView(player: players[3], direction: "right", isUser: false).padding(.top, 14)
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[2], direction: "right", isUser: false)
                Spacer()
                AIPlayerPositionView(player: players[4], direction: "left", isUser: false)
            }
            .padding(.top, 40.0)
            .padding(.bottom, 40.0)
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[1], direction: "right", isUser: false)
                Spacer()
                AIPlayerPositionView(player: players[5], direction: "left", isUser: false)
            }
            .padding(.top, 40.0)
            .padding(.bottom, 40.0)
            Spacer()
            AIPlayerPositionView(player: players[0], direction: "right", isUser: true).padding(.bottom, 14)
            
        }
    }
    
    private var nineMaxLayout: some View {
        VStack {
            HStack(alignment: .center, spacing: 60) {
                AIPlayerPositionView(player: players[4], direction: "right", isUser: false).padding(.top, 14)
                AIPlayerPositionView(player: players[5], direction: "right", isUser: false).padding(.top, 14)
            }.padding(.top, 10.0)
            
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[3], direction: "right", isUser: false)
                Spacer()
                AIPlayerPositionView(player: players[6], direction: "left", isUser: false)
            }
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[2], direction: "right", isUser: false)
                Spacer()
                AIPlayerPositionView(player: players[7], direction: "left", isUser: false)
            }
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[1], direction: "right", isUser: false)
                Spacer()
                AIPlayerPositionView(player: players[8], direction: "left", isUser: false)
            }
            Spacer()
            AIPlayerPositionView(player: players[0], direction: "right", isUser: true)
                .padding(.bottom, 14)
        }
    }
}

#Preview {
    let players = [
        AIPlayer(name: "HERO", position: "SB", stack: 100.0),
        AIPlayer(name: "LIT", position: "BB", stack: 100.0),
        AIPlayer(name: "DWG", position: "UTG", stack: 100.0),
        AIPlayer(name: "BRO", position: "UTG1", stack: 100.0),
        AIPlayer(name: "ETW", position: "UTG2", stack: 100.0),
        AIPlayer(name: "BIG", position: "MP2", stack: 100.0),
        AIPlayer(name: "BIG", position: "MP2", stack: 100.0),
        AIPlayer(name: "BIG", position: "MP2", stack: 100.0),
        AIPlayer(name: "BIG", position: "MP2", stack: 100.0)
    ]
    AIPlayerLayoutView(players: players)
}
