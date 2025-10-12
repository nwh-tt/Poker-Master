//
//  AITable.swift
// Uses a lot of the same as basic preflop
//  Poker Master
//
//  Created by Ned Whittleton on 10/8/25.
//

import SwiftUI

struct AITable: View {
    @State var aiManager: AIGameManager
    @State private var raiseMenuVisible = false
    
    let tableSize: String
    
    init(tableSize: String) {
        self.tableSize = tableSize
        self.aiManager = AIGameManager()
    }
    
    var body: some View {
        ZStack {
            EllipticalGradient(colors: [darkBlue, Color.black], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.9)
            VStack {
                Capsule()
                    .fill(darkGreen)
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: 5)
                    )
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 128)
            EllipticalGradient(colors: [Color.green.opacity(0.25), Color.clear], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.5)
            if aiManager.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(2)
            } else {
                AIPlayerLayoutView(players: aiManager.aiPlayers)
                BoardView(board: [])
                VStack {
                    Spacer()
                    HStack(spacing: -10) {
                        CardView(card: aiManager.aiPlayers[0].hand[0])
                        CardView(card: aiManager.aiPlayers[0].hand[1])
                    }
                }.padding(.bottom, 170)
            }
            Text("")
                .countingText(to: aiManager.pot)
                .position(x: UIScreen.main.bounds.width / 2,
                          y: UIScreen.main.bounds.height / 2 - 200)
                .animation(.easeOut(duration: 0.3), value: aiManager.pot)
            VStack {
                Spacer()
                if raiseMenuVisible {
                    VStack(spacing: 10) {
                        // Quick Raise Presets
                        HStack(spacing: 10) {
                            ForEach([1, 2, 3, 4], id: \.self) { multiplier in
                                Text("\(multiplier)x BB")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(darkBlue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        Text("All In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        
                        // Confirm Button
                        Text("Confirm Raise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Main Action Buttons
                HStack(spacing: 10) {
                    Text("Fold")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(darkBlue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .opacity(1.0)

                    Text("Call")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(darkBlue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .opacity(1.0)

                    Text("Raise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(darkBlue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation {
                                raiseMenuVisible.toggle()
                            }
                        }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }

        }
        .edgesIgnoringSafeArea(.all)
        .task {
            await aiManager.startGame()
        }
    }
}

#Preview {
    AITable(tableSize: "6")
}
