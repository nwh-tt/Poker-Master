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
    let game: Int
    let round: Int
    let isShowdown: Bool
    let onPlayerTapped: (AIPlayer) -> Void
    
    init(players: [AIPlayer], game: Int, round: Int, isShowdown: Bool, onPlayerTapped: @escaping (AIPlayer) -> Void) {
        self.players = players
        self.size = String(players.count)
        self.game = game
        self.round = round
        self.isShowdown = isShowdown
        self.onPlayerTapped = onPlayerTapped
    }
    
    var body: some View {
        VStack {
            if size == "6" {
                sixMaxLayout
            } else if size == "9" {
                nineMaxLayout
            }
        }
        .padding(4)
        .padding(.vertical, 80)
    }
    
    private var sixMaxLayout: some View {
        VStack(alignment: .center) {
            AIPlayerPositionView(player: players[3], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown).padding(.top, 14)
                .onTapGesture {
                    onPlayerTapped(players[3])
                }
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[2], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[2])
                    }
                Spacer()
                AIPlayerPositionView(player: players[4], direction: "left", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[4])
                    }
            }
            .padding(.top, 40.0)
            .padding(.bottom, 40.0)
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[1], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[1])
                    }
                Spacer()
                AIPlayerPositionView(player: players[5], direction: "left", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[5])
                    }
                
            }
            .padding(.top, 40.0)
            .padding(.bottom, 40.0)
            Spacer()
            AIPlayerPositionView(player: players[0], direction: "right", isUser: true, game: game, round: round, isShowdown: isShowdown).padding(.bottom, 14)
                .onTapGesture {
                    onPlayerTapped(players[0])
                }
            
        }
    }
    
    private var nineMaxLayout: some View {
        VStack {
            HStack(alignment: .center, spacing: 60) {
                AIPlayerPositionView(player: players[4], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown).padding(.top, 14)
                    .onTapGesture {
                        onPlayerTapped(players[4])
                    }
                AIPlayerPositionView(player: players[5], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown).padding(.top, 14)
                    .onTapGesture {
                        onPlayerTapped(players[5])
                    }
            }.padding(.top, 10.0)
            
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[3], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[3])
                    }
                Spacer()
                AIPlayerPositionView(player: players[6], direction: "left", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[6])
                    }
            }
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[2], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[2])
                    }
                Spacer()
                AIPlayerPositionView(player: players[7], direction: "left", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[7])
                    }
            }
            Spacer()
            HStack(alignment: .center)
            {
                AIPlayerPositionView(player: players[1], direction: "right", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[1])
                    }
                Spacer()
                AIPlayerPositionView(player: players[8], direction: "left", isUser: false, game: game, round: round, isShowdown: isShowdown)
                    .onTapGesture {
                        onPlayerTapped(players[8])
                    }
            }
            Spacer()
            AIPlayerPositionView(player: players[0], direction: "right", isUser: true, game: game, round: round, isShowdown: isShowdown)
                .onTapGesture {
                    onPlayerTapped(players[0])
                }
                .padding(.bottom, 14)
        }
    }
}

#Preview("6 Max") {
    let players = [
        AIPlayer(name: "HERO", fullName: "p1", position: "SB", stack: 100.0),
        AIPlayer(name: "LIT", fullName: "p1", position: "BB", stack: 100.0),
        AIPlayer(name: "DWG", fullName: "p1", position: "UTG", stack: 100.0),
        AIPlayer(name: "BRO", fullName: "p1",position: "UTG1", stack: 100.0),
        AIPlayer(name: "ETW", fullName: "p1", position: "UTG2", stack: 100.0),
        AIPlayer(name: "BIG", fullName: "p1", position: "MP2", stack: 100.0)
    ]
    AIPlayerLayoutView(players: players, game: 0, round: 0, isShowdown: false, onPlayerTapped: { _ in print("test")})
}


#Preview("9 Max") {
    let players = [
        AIPlayer(name: "HERO", fullName: "p1", position: "SB", stack: 100.0),
        AIPlayer(name: "LIT", fullName: "p1", position: "BB", stack: 100.0),
        AIPlayer(name: "DWG", fullName: "p1", position: "UTG", stack: 100.0),
        AIPlayer(name: "BRO", fullName: "p1",position: "UTG1", stack: 100.0),
        AIPlayer(name: "ETW", fullName: "p1", position: "UTG2", stack: 100.0),
        AIPlayer(name: "BIG", fullName: "p1", position: "MP2", stack: 100.0),
        AIPlayer(name: "BIG", fullName: "p1", position: "MP2", stack: 100.0),
        AIPlayer(name: "BIG", fullName: "p1", position: "MP2", stack: 100.0),
        AIPlayer(name: "BIG", fullName: "p1", position: "MP2", stack: 100.0)
    ]
    AIPlayerLayoutView(players: players, game: 0, round: 0, isShowdown: false, onPlayerTapped: { _ in print("test")})
}
