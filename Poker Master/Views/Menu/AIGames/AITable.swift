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
                AIPlayerLayoutView(players: aiManager.aiPlayers, round: aiManager.round)
                AIBoardView(board: aiManager.board)
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
                    VStack(spacing: 8) {
                        // Quick Raise Presets
                        HStack(spacing: 10) {
                            ForEach(aiManager.getUserDefaultBets(), id: \.self) { multiplier in
                                Button(action: {
                                    aiManager.handleUserMove(move:("raise", Double(multiplier)))
                                    raiseMenuVisible = false
                                }) {
                                    if #available(iOS 26.0, *) {
                                        Text("\(multiplier)x BB")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(.ultraThinMaterial)
                                            .glassEffect()
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    } else {
                                        // Fallback on earlier versions
                                        Text("\(multiplier)x BB")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(.ultraThinMaterial)
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            Button(action: {
                                aiManager.handleUserMove(move:("allin", 0.0))
                                raiseMenuVisible = false
                            }) {
                                if #available(iOS 26.0, *) {
                                    Text("All In")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(.ultraThinMaterial)
                                        .glassEffect()
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                else {
                                    Text("All In")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(.ultraThinMaterial)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Main Action Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        aiManager.handleUserMove(move:("fold", 0.0))
                    }) {
                    Text("Fold")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(darkBlue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .opacity(aiManager.waitingForUserInput ? 1.0 : 0.5)
                    }.disabled(!aiManager.waitingForUserInput)
                    

                    Button(action: {
                        aiManager.handleUserMove(move: ("call", aiManager.lastPlayerBet))
                    }) {
                    Text("Call")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(darkBlue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .opacity(aiManager.waitingForUserInput ? 1.0 : 0.5)
                    }.disabled(!aiManager.waitingForUserInput)

                    Button(action: {
                        // toggle raise menu
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                raiseMenuVisible.toggle()
                            }
                    }) {
                    Text("Raise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(darkBlue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .opacity(aiManager.waitingForUserInput ? 1.0 : 0.5)
                    }.disabled(!aiManager.waitingForUserInput)
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
    
    private func truncateDouble(_ number: Double) -> String {
        // Only show decimals if needed
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f× BB", number)
        } else {
            return String(format: "%.1f× BB", number)
        }
    }
}

#Preview {
    AITable(tableSize: "6")
}
