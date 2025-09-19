//
//  EquityTable.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/9/25.
//

import SwiftUI
import ActivityIndicatorView

let darkGreen = Color(red: 0, green: 0.15, blue: 0)
let darkBlue = Color(red: 0.3, green: 0.3, blue: 0.3)
let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.2)
let padding = 40.0

struct EquityTable: View {
    @State private var selectedEquity: String? = nil
    @StateObject private var equityDrillManager: EquityDrillManager
    @State private var showResult: Bool = false
    
    @State private var cardAnimations: [Bool] = [false, false]
    @State private var showGameOver: Bool = false
    
    let street: String
    
    init(street: String) {
        self.street = street
        _equityDrillManager = StateObject(wrappedValue: EquityDrillManager(street: street))
    }
    
    var body: some View {
        ZStack {
            
            if equityDrillManager.roundsPlayed >= 10 {
                            GameOverView(
                                correctDecisions: equityDrillManager.score,
                                totalHands: equityDrillManager.roundsPlayed,
                                startNewGame: {
                                    equityDrillManager.reset()
                                    showGameOver = false
                                }
                            )
                            .scaleEffect(showGameOver ? 1 : 0.8)
                            .opacity(showGameOver ? 1 : 0)
                            .animation(.easeOut(duration: 0.5), value: showGameOver)
                            .onAppear {
                                // Slight delay before animating in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showGameOver = true
                                }
                            }
                            .ignoresSafeArea()
                            .zIndex(1)
                        }
            
            
            EllipticalGradient(colors: [darkBlue, Color.black], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.9)
            
            EllipticalGradient(colors: [darkBlue, Color.black], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.9)
            VStack {
                Capsule()
                    .fill(darkGreen)
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: 5)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 170)
            .padding(.top, 90)
            
            EllipticalGradient(colors: [Color.green.opacity(0.25), Color.clear], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.5)
            
            // Score top right
            HStack {
                Spacer()
                Text("\(equityDrillManager.score) / \(equityDrillManager.roundsPlayed)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 2)
                            )
                    )
                    .padding(.top, 16)
                    .padding(.trailing, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 40)
            .padding(.trailing, 12)
            
            VStack {
                Spacer()
                VStack {
                    if let villainRange = equityDrillManager.currentScenario?.villainRange {
                        VillainRangeView(villainRange: villainRange)
                            .padding(.top, 20)
                            .id(villainRange.hashValue)
                        
                    } else {
                        Color.clear
                            .padding(.top, 20)
                            .frame(height: 207) // adjust height as needed
                    }
                }
                Spacer()
                
                BoardView(board: equityDrillManager.currentScenario?.board ?? [])
                
                Spacer()
                // Mark the hero's hand
                if let hand = equityDrillManager.currentScenario?.heroHand {
                    HStack(spacing: -10) {
                        ForEach(Array(hand.enumerated()), id: \.offset) { index, card in
                            CardView(card: card)
                                .opacity(cardAnimations[index] ? 1 : 0)
                                .offset(y: cardAnimations[index] ? 0 : 20) // start below and slide up
                                .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: cardAnimations[index])
                        }
                    }
                    .onAppear {
                        for i in hand.indices {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                                cardAnimations[i] = true
                            }
                        }
                    }.onChange(of: equityDrillManager.currentScenario?.heroHand) { oldHand, newHand in
                        guard let newHand = newHand else { return }
                        
                        // Optional: fade out old cards first
                        cardAnimations = [false, false]
                        
                        // Delay before dealing new cards
                            for i in newHand.indices {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                                    cardAnimations[i] = true
                                }
                            }
                        
                    }
                }
                else {
                    Color.clear.frame(height: 70)
                }
                Circle()
                    .fill(Color.black.opacity(1))
                    .frame(width: 50, height: 50)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .overlay(
                        Text("Hero")
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }.padding(.bottom, 148)
            
            VStack {
                Spacer()
                
                if equityDrillManager.equityReady {
                    if let currentScenario = equityDrillManager.currentScenario {
                        VStack {
                            HStack {
                                Button(action: {
                                    guard !showResult else { return } // prevent multiple taps
                                    selectedEquity = currentScenario.options[0]
                                    showResult = true
                                    
                                    // Update score if correct
                                    if currentScenario.options[0] == currentScenario.correctEquityRange {
                                        equityDrillManager.score += 1
                                    }
                                    
                                    // Increment rounds played
                                    equityDrillManager.roundsPlayed += 1
                                    
                                    // Short delay before loading next scenario
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        equityDrillManager.stageNextScenario()
                                        selectedEquity = nil
                                        showResult = false
                                    }
                                }) {
                                    Text(currentScenario.options[0])
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(buttonColor(for: currentScenario.options[0]))
                                        .clipShape(Capsule())
                                }
                                Button(action: {
                                    guard !showResult else { return } // prevent multiple taps
                                    selectedEquity = currentScenario.options[1]
                                    showResult = true
                                    
                                    // Update score if correct
                                    if currentScenario.options[1] == currentScenario.correctEquityRange {
                                        equityDrillManager.score += 1
                                    }
                                    
                                    // Increment rounds played
                                    equityDrillManager.roundsPlayed += 1
                                    
                                    // Short delay before loading next scenario
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        equityDrillManager.stageNextScenario()
                                        selectedEquity = nil
                                        showResult = false
                                    }
                                }) {
                                    Text(currentScenario.options[1])
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(buttonColor(for: currentScenario.options[1]))
                                        .clipShape(Capsule())
                                }
                            }
                            HStack {
                                Button(action: {
                                    guard !showResult else { return } // prevent multiple taps
                                    selectedEquity = currentScenario.options[2]
                                    showResult = true
                                    
                                    // Update score if correct
                                    if currentScenario.options[2] == currentScenario.correctEquityRange {
                                        equityDrillManager.score += 1
                                    }
                                    
                                    // Increment rounds played
                                    equityDrillManager.roundsPlayed += 1
                                    
                                    // Short delay before loading next scenario
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        equityDrillManager.stageNextScenario()
                                        selectedEquity = nil
                                        showResult = false
                                    }
                                }) {
                                    Text(currentScenario.options[2])
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(buttonColor(for: currentScenario.options[2]))
                                        .clipShape(Capsule())
                                }
                                Button(action: {
                                    guard !showResult else { return } // prevent multiple taps
                                    selectedEquity = currentScenario.options[3]
                                    showResult = true
                                    
                                    // Update score if correct
                                    if currentScenario.options[3] == currentScenario.correctEquityRange {
                                        equityDrillManager.score += 1
                                    }
                                    
                                    // Increment rounds played
                                    equityDrillManager.roundsPlayed += 1
                                    
                                    // Short delay before loading next scenario
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        equityDrillManager.stageNextScenario()
                                        selectedEquity = nil
                                        showResult = false
                                    }
                                }) {
                                    Text(currentScenario.options[3])
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .background(buttonColor(for: currentScenario.options[3]))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom)
                    }
                } else {
                    VStack(spacing: 12) {
                            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots(count: 3, inset: 4))
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)

                            Text("Calculating Equity")
                                .foregroundColor(.gray)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding()
                }
            }
            
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func buttonColor(for option: String) -> Color {
        if !showResult { return darkBlue } // default
        if option == equityDrillManager.currentScenario?.correctEquityRange { return Color.green }
        if option == selectedEquity { return Color.red }
        return darkBlue
    }
}


#Preview {
    EquityTable(street: "Any")
}
