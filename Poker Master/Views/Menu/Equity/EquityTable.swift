//
//  EquityTable.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/9/25.
//

import SwiftUI
import SwiftData
import ActivityIndicatorView

let darkGreen = Color(red: 0, green: 0.15, blue: 0)
let darkBlue = Color(red: 0.3, green: 0.3, blue: 0.3)
let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.2)
let padding = 40.0

struct EquityTable: View {
    @State private var selectedEquity: String? = nil
    @StateObject private var equityDrillManager: EquityDrillManager
    @State private var showResult: Bool = false
    @Environment(\.modelContext) private var context
    
    @State private var cardAnimations: [Bool] = [false, false]
    @State private var villainCardAnimations: [Bool] = [false, false]
    @State private var showGameOver: Bool = false
    
    let street: String
    let villainType: String
    let game: Game
    
    init(street: String, villainType: String, authManager: AuthManager) {
        self.street = street
        self.villainType = villainType
        self.game = Game()
        _equityDrillManager = StateObject(wrappedValue: EquityDrillManager(street: street, villainType: villainType, authManager: authManager))
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
                        
                    }
                    else if let villainHand = equityDrillManager.currentScenario?.villainHand {
                        VStack {
                            Text("Villain Hand")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            HStack(spacing: -10) {
                                ForEach(Array(villainHand.enumerated()), id: \.offset) { index, card in
                                    CardView(card: card)
                                        .opacity(villainCardAnimations[index] ? 1 : 0)
                                        .offset(y: villainCardAnimations[index] ? 0 : 20) // start below and slide up
                                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: villainCardAnimations[index])
                                }
                            }
                        }.frame(height: 207)
                            .padding(.top, 20)
                            .onAppear {
                                for i in villainHand.indices {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                                        villainCardAnimations[i] = true
                                    }
                                }
                            }.onChange(of: equityDrillManager.currentScenario?.villainHand) { oldHand, newHand in
                                guard let newHand = newHand else { return }
                                
                                // Optional: fade out old cards first
                                villainCardAnimations = [false, false]
                                
                                // Delay before dealing new cards
                                for i in newHand.indices {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                                        villainCardAnimations[i] = true
                                    }
                                }
                            }
                    }
                    else {
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
                                    handleSelection(currentScenario.options[0], in: currentScenario)
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
                                    handleSelection(currentScenario.options[1], in: currentScenario)
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
                                    handleSelection(currentScenario.options[2], in: currentScenario)
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
                                    handleSelection(currentScenario.options[3], in: currentScenario)
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
        .onAppear() {
            context.insert(game)
        }
    }
    
    private func handleSelection(_ option: String, in scenario: EquityScenario) {
        guard !showResult else { return }
        selectedEquity = option
        showResult = true

        if option == scenario.correctEquityRange {
            equityDrillManager.score += 1
        }

        equityDrillManager.roundsPlayed += 1
        
        // add a hand log entry
        let handLog = HandLog(typeOfHand: .equity, position: .bb, hand: equityDrillManager.user?.getHand() ?? "", pair: false, action: .none, raiseType: .open, betAmount: 0, pot: 0, xpEarned: 0, isCorrect: option == scenario.correctEquityRange, game: game)
        
        context.insert(handLog)
        
        do {
            try context.save()
        } catch {
            print("Failed to save HandLog: \(error)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            equityDrillManager.stageNextScenario()
            selectedEquity = nil
            showResult = false
        }
    }
    
    private func buttonColor(for option: String) -> Color {
        if !showResult { return darkBlue } // default
        if option == equityDrillManager.currentScenario?.correctEquityRange { return Color.green }
        if option == selectedEquity { return Color.red }
        return darkBlue
    }
}


#Preview {
    @Previewable @StateObject var authManager = AuthManager()
    let schema = Schema([
            Game.self,
            HandLog.self,
            Challenges.self,
            Item.self,
            Profile.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Add some mock data so the preview isn't empty
        let user = Profile(username: "Ned Whittleton")
        context.insert(user)
    
    return EquityTable(street: "Any", villainType: "Ranges", authManager: authManager)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
}

