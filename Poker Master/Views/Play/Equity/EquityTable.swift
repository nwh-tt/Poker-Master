//
//  EquityTable.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/9/25.
//

import SwiftUI
import SwiftData
import ActivityIndicatorView
import AlertToast
import ConfettiSwiftUI

let darkGreen = Color(red: 0, green: 0.15, blue: 0)
let darkBlue = Color(red: 0.3, green: 0.3, blue: 0.3)
let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.2)
let padding = 40.0

struct EquityTable: View {
    @State private var selectedEquity: String? = nil
    @StateObject private var equityDrillManager: EquityDrillManager
    @State private var showResult: Bool = false
    @State private var isSubscribed = true
    @Environment(\.modelContext) private var context
    @EnvironmentObject var userProfile: UserProfileState
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var cardAnimations: [Bool] = [false, false]
    @State private var villainCardAnimations: [Bool] = [false, false]
    @State private var showGameOver: Bool = false
    @State private var triggerMoneyConfetti: Int = 0
    
    let street: String
    let villainType: String
    @State private var game: Game? = nil
    
    init(street: String, villainType: String, authManager: AuthManager) {
        self.street = street
        self.villainType = villainType
        _equityDrillManager = StateObject(wrappedValue: EquityDrillManager(street: street, villainType: villainType, authManager: authManager))
    }
    
    var body: some View {
        ZStack {
            
            if equityDrillManager.roundsPlayed >= 10 {
                GameOverView(
                    correctDecisions: equityDrillManager.score,
                    totalHands: equityDrillManager.roundsPlayed,
                    canPlayAgain: !userProfile.hitEquityLimit(isSubscribed: isSubscribed),
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
                        .confettiCannon(trigger: $triggerMoneyConfetti, num: 50, confettis: [.text("💵"), .text("💰")])
                    }
                } else {
                    if equityDrillManager.errorMessage == nil {
                        VStack(spacing: 12) {
                            ActivityIndicatorView(isVisible: .constant(true), type: .opacityDots(count: 3, inset: 4))
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                            
                            Text("Calculating Equity")
                                .foregroundColor(.gray)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding()
                    } else {
                        HStack(spacing: 10) {
                            Button(action: {
                                // Go back
                                dismiss()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Exit")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(darkBlue)
                                .clipShape(Capsule())
                                .foregroundColor(.white)
                                .padding(32)
                                .padding(.horizontal, 8)
                            }
                        }

                    }
                }
            }
            
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear() {
            game = nil
            equityDrillManager.startNewGame()
        }
        .onDisappear {
            equityDrillManager.stopPreloading()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(equityDrillManager.score) / \(equityDrillManager.roundsPlayed)")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
        .toast(
            isPresenting: $equityDrillManager.showToast,
            duration: 10,
            tapToDismiss: true,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .error(.red),
                    title: equityDrillManager.errorMessage,
                    subTitle: nil
                )
            },
            completion: {
                DispatchQueue.main.async {
                    equityDrillManager.showToast = false
                }
            }
        )
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .task {
            isSubscribed = await SubscriptionManager.isSubscribed()
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
        
        let isCorrect = option == scenario.correctEquityRange
        let computedEquity = Int((scenario.lowEquity + scenario.highEquity) / 2)
        if isCorrect {
            triggerMoneyConfetti += 1
        }
        let xpEarned = isCorrect ? 10 : 0
        userProfile.addXP(xpEarned)
        
        // add a hand log entry
        if game == nil {
            let newGame = Game(gameType: .equityDrill)
            game = newGame
            context.insert(newGame)
        }
        guard let currentGame = game else {
            Log.data.error("Game not found. No Equity log saved")
            return
        }
        currentGame.totalHands += 1
        currentGame.duration = Date().timeIntervalSince(currentGame.date)
        let equityLog = EquityLog(
            street: scenario.street,
            villainType: scenario.villainType,
            hand: scenario.heroHand.handToString(),
            equity: computedEquity,
            xpEarned: xpEarned,
            isCorrect: isCorrect,
            game: currentGame
        )
        context.insert(equityLog)
        do {
            try context.save()
        } catch {
            Log.data.error("Failed to save EquityLog: \(error, privacy: .private)")
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
            PreflopLog.self,
            EquityLog.self,
            Challenges.self,
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

