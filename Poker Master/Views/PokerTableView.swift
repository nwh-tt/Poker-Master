//
//  PokerTable.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/11/24.
//

import SwiftUI

struct PokerTableView: View {
    let darkGreen = Color(red: 0, green: 0.15, blue: 0)
    let darkBlue = Color(red: 0.3, green: 0.3, blue: 0.3)
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.8)
    let padding = 40.0
    @StateObject var gameManager = GameManager()
    
    
    var body: some View {
            ZStack {
                EllipticalGradient(colors: [darkBlue, Color.black], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.9)
                
                Capsule()
                    .fill(darkGreen)
                    .frame(width: 300, height: 590)
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: 3)
                    )
                EllipticalGradient(colors: [Color.green.opacity(0.25), Color.clear], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.5)
                VStack(alignment: .center)
                {
                    Spacer()
                    PlayerPositionView(player: gameManager.players[3], direction: "right", isUser: false).padding(.top, 14)
                    Spacer()
                    HStack(alignment: .center)
                    {
                        PlayerPositionView(player: gameManager.players[2], direction: "right", isUser: false)
                        Spacer()
                        PlayerPositionView(player: gameManager.players[4], direction: "left", isUser: false)
                    }
                    .padding(.top, padding)
                    .padding(.bottom, padding)
                    Spacer()
                    HStack(alignment: .center)
                    {
                        PlayerPositionView(player: gameManager.players[1], direction: "right", isUser: false)
                        Spacer()
                        PlayerPositionView(player: gameManager.players[5], direction: "left", isUser: false)
                    }
                    .padding(.top, padding)
                    .padding(.bottom, padding)
                    Spacer()
                    PlayerPositionView(player: gameManager.players[0], direction: "right", isUser: true).padding(.bottom, 14)
                    Spacer()
                    
                }.padding(4)
                HStack(spacing: -10) {
                    CardView(card: gameManager.players[0].hand[0])
                    CardView(card: gameManager.players[0].hand[1])
                }.offset(x: 0, y: 220)
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            gameManager.userMadeMove(decision: LastMove.call)
                        }) {
                            Text("Call")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(darkBlue)
                                    .foregroundColor(.white)  // Set the text color to white
                                    .clipShape(Capsule())
                        }
                        Button(action:{
                            gameManager.userMadeMove(decision: LastMove.raise)
                        }) {
                            Text("Raise")
                                .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(darkBlue)
                                    .foregroundColor(.white)  // Set the text color to white
                                    .clipShape(Capsule())
                        }
                        Button(action:{
                            gameManager.userMadeMove(decision: LastMove.fold)
                        }) {
                            Text("Fold")
                                .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(darkBlue)
                                    .foregroundColor(.white)  // Set the text color to white
                                    .clipShape(Capsule())
                        }
                    }.padding()
                }.padding()
                Button(action: {
                    Task {
                        await gameManager.startGame()
                    }
                            }) {
                                Text("Tap Me")
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                Text("Current Pot: \(gameManager.pot)")
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 60)
            }
            .edgesIgnoringSafeArea(.all)
            
    }
}

#Preview {
    PokerTableView()
}
