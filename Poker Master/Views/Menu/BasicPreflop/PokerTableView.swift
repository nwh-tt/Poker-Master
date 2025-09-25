//
//  PokerTable.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/11/24.
//

import SwiftUI
import SwiftData
import ConfettiSwiftUI

struct PokerTableView: View {
    // MARK: - Properties
    let darkGreen = Color(red: 0, green: 0.15, blue: 0)
    let darkBlue = Color(red: 0.3, green: 0.3, blue: 0.3)
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.2)
    let padding = 40.0
    
    // MARK: - Environment objects
    @Environment(\.modelContext) private var context
    @EnvironmentObject var userProfile: UserProfileState
    
    // MARK: - Parameters from Options view
    let speed: Double
    let size: String
    let heroPosition: String
    let action: String
    
    // MARK: - State
    @State private var triggerMoneyConfetti: Int = 0
    @State private var correctMoveMade: Action = .none
    @StateObject private var gameManager: SimplePreFlopManager
    @State private var showGameOver: Bool = false // for animations

    // MARK: - Init
    init(speed: Double, heroPosition: String, action: String, size: String) {
        self.speed = speed
        self.heroPosition = heroPosition
        self.action = action
        self.size = size

        // initialize GameManager with passed-in options
        _gameManager = StateObject(
            wrappedValue: SimplePreFlopManager(
                gameplaySpeed: speed,
                selectedPosition: heroPosition,
                selectedAction: action,
                size: size
            )
        )
    }
    
    // function to trigger confetti and turn buttons green
    private func buttonClicked(buttonClicked: Action) {
        let isCorrect = gameManager.userMadeMove(decision: buttonClicked)
        
        if (isCorrect) {
            triggerMoneyConfetti += 1;
            correctMoveMade = buttonClicked
            giveHapticFeedback(success: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                correctMoveMade = .none // Reset button color
                // check if handsPlayed > handLimit
                if (gameManager.handsPlayed >= 10) {
                    // TODO: Show end of game screen
                    return
                }
                gameManager.resetAndStartNewGame()
            }
        }
    }
    
    private func giveHapticFeedback(success: Bool) {
        let generator = UINotificationFeedbackGenerator()
        success ? generator.notificationOccurred(.success) : generator.notificationOccurred(.error)
    }
    
    var body: some View {
            ZStack {
                if (gameManager.isGameOver) {
                        GameOverView(correctDecisions: gameManager.score, totalHands: gameManager.handsPlayed, startNewGame: {
                            gameManager.completeReset()
                        })
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
                // add a score in the top right corner
                HStack {
                    Spacer()
                    Text("\(gameManager.score) / \(gameManager.handsPlayed)")
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
                
                
                PlayerLayoutView(players: gameManager.players)
                
                // add buttons
                VStack {
                    Spacer()
                    HStack(spacing: -10) {
                        CardView(card: gameManager.players[0].hand[0])
                        CardView(card: gameManager.players[0].hand[1])
                    }
                }.padding(.bottom, 170)
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            buttonClicked(buttonClicked: Action.call)
                        }) {
                            Text("Call")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(correctMoveMade == .call ? Color.green : darkBlue)
                                .foregroundColor(.white)  // Set the text color to white
                                .clipShape(Capsule())
                                .opacity(gameManager.waitingForUserInput ? 1.0 : 0.5) // Dim when disabled
                        }.disabled(!gameManager.waitingForUserInput)
                        Button(action:{
                            buttonClicked(buttonClicked: Action.raise)
                        }) {
                            Text("Raise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(correctMoveMade == .raise ? Color.green :darkBlue)
                                .foregroundColor(.white)  // Set the text color to white
                                .clipShape(Capsule())
                                .opacity(gameManager.waitingForUserInput ? 1.0 : 0.5) // Dim when disabled
                        }.disabled(!gameManager.waitingForUserInput)
                        Button(action:{
                            buttonClicked(buttonClicked: Action.fold)
                        }) {
                            Text("Fold")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(correctMoveMade == .fold ? Color.green : darkBlue)
                                .foregroundColor(.white)  // Set the text color to white
                                .clipShape(Capsule())
                                .opacity(gameManager.waitingForUserInput ? 1.0 : 0.5) // Dim when disabled
                        }.disabled(!gameManager.waitingForUserInput)
                    }.padding()
                        .confettiCannon(trigger: $triggerMoneyConfetti, num: 50, confettis: [.text("💵"), .text("💰")])
                }.padding()
                Text("")
                    .countingText(to: gameManager.pot)
                    .position(x: UIScreen.main.bounds.width / 2,
                              y: UIScreen.main.bounds.height / 2 - 30)
                    .animation(.easeOut(duration: 0.3), value: gameManager.pot)
            }
            .sheet(isPresented: $gameManager.showIncorrectPopup, onDismiss: {
                // This will run when the sheet is dismissed by any means
                gameManager.resetAndStartNewGame()
            }) {
                IncorrectSelectionView(showPopup: $gameManager.showIncorrectPopup, adviceText: gameManager.adviceText, keyUsed: gameManager.rangesUsed, hand: gameManager.user?.getHand() ?? "", playerCount: size)
                    .presentationBackground(.ultraThinMaterial)
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                gameManager.setContext(context)
                gameManager.setProfile(profile: userProfile.user)
                Task {
                    await gameManager.startGame()
                }
            }
    }
}

struct CountingText: AnimatableModifier {
    var value: Double
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        Text("\(String(format: "%.1f", value)) BB")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
            .padding(12)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.25))
            )
            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func countingText(to value: Double) -> some View {
        self.modifier(CountingText(value: value))
    }
}

#Preview("6 Player") {
    let schema = Schema([
            Game.self,
            HandLog.self,
            Challenges.self,
            Item.self,
            User.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Add some mock data so the preview isn't empty
        let user = User(username: "Ned Whittleton")
        context.insert(user)

    return PokerTableView(speed: 4.5, heroPosition: "any", action: "any", size: "6")
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
}

#Preview("9 player") {
    let schema = Schema([
            Game.self,
            HandLog.self,
            Challenges.self,
            Item.self,
            User.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Add some mock data so the preview isn't empty
        let user = User(username: "Ned Whittleton")
        context.insert(user)

    return PokerTableView(speed: 4.5, heroPosition: "any", action: "any", size: "9")
        .modelContainer(container)
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
}
