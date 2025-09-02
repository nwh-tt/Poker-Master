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
    let darkGreen = Color(red: 0, green: 0.15, blue: 0)
    let darkBlue = Color(red: 0.3, green: 0.3, blue: 0.3)
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.8)
    let padding = 40.0
    @StateObject private var gameManager = SimplePreFlopManager()
    @Environment(\.modelContext) private var context
    @EnvironmentObject var userProfile: UserProfileState
    
    @State private var triggerMoneyConfetti: Int = 0
    // @State private var pulseAnimation: Bool = false
    @State private var correctMoveMade: Action = .none
    
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
                
                EllipticalGradient(colors: [darkBlue, Color.black], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.9)
                
                Capsule()
                    .fill(darkGreen)
                    .frame(width: 300, height: 590)
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: 3)
                    )
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
                        .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 32)
                .padding(.trailing, 12)
                
                
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
                Text("\(String(format: "%.1f", gameManager.pot)) BB")
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 60)
                    .colorInvert()
            }
            .sheet(isPresented: $gameManager.showIncorrectPopup) {
                IncorrectSelectionView(showPopup: $gameManager.showIncorrectPopup, adviceText: gameManager.adviceText, resetGame: { gameManager.resetAndStartNewGame() })
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

#Preview {
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

        return PokerTableView()
            .modelContainer(container)
            .environment(\.modelContext, context)
            .environmentObject(UserProfileState(context: context))
}
