//
//  AITable.swift
// Uses a lot of the same as basic preflop
//  Poker Master
//
//  Created by Ned Whittleton on 10/8/25.
//

import SwiftUI
import AlertToast
import ActivityIndicatorView
import SwiftData

struct AITable: View {
    @State var aiManager: AIGameManager = AIGameManager()
    @State private var raiseMenuVisible = false
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var userProfile: UserProfileState
    @EnvironmentObject var authManager: AuthManager
    
    // Used for player info view
    @State private var selectedPlayer: AIPlayer? = nil
    
    let tableSize: String
    
    init(tableSize: String) {
        self.tableSize = tableSize
    }
    
    var body: some View {
        ZStack {
            PokerTableComponent()
            
            if aiManager.isLoading {
                ActivityIndicatorView(isVisible: .constant(true), type: .arcs(count: 3, lineWidth: 2))
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(red: 1,green: 1,blue: 0.95).opacity(0.2))
            } else {
                AIPlayerLayoutView(players: aiManager.aiPlayers, game: aiManager.game, round: aiManager.round, isShowdown: aiManager.isShowdown) { tappedPlayer in
                    selectedPlayer = tappedPlayer
                }
                AIBoardView(board: aiManager.board)
                VStack {
                    Spacer()
                    if aiManager.aiPlayers.count > 0 && aiManager.aiPlayers[0].hand.count != 0 {
                        HStack(spacing: -10) {
                            CardView(card: aiManager.aiPlayers[0].hand[0])
                            CardView(card: aiManager.aiPlayers[0].hand[1])
                        }
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
                                    // Trigger haptics
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
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
                                // Trigger haptics
                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                generator.impactOccurred()
                                
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
                ZStack {
                    if aiManager.waitingForStartorRetryButton {
                        if aiManager.errorMessage != nil {
                            HStack(spacing: 10) {
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                                    generator.impactOccurred()
                                    // Keep playing action
                                    Task {
                                        await aiManager.populateAINames()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.trianglehead.clockwise")
                                        Text("Retry")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(darkBlue)
                                    .clipShape(Capsule())
                                    .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                            }
                            
                        }
                        else {
                            HStack(spacing: 10) {
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    aiManager.waitingForStartorRetryButton = false
                                    Task {
                                        await aiManager.startGame()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                        Text("Start Game")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(darkBlue)
                                    .clipShape(Capsule())
                                    .foregroundColor(.white)
                                    .opacity(aiManager.isLoading ? 0.5 : 1.0)
                                }
                                .disabled(aiManager.isLoading)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    else if aiManager.waitingForContinueButton {
                        HStack(spacing: 10) {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .rigid)
                                generator.impactOccurred()
                                dismiss()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Leave Table")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.15))
                                .clipShape(Capsule())
                                .foregroundColor(.white)
                            }
                            if aiManager.canStartNewGame() {
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                                    generator.impactOccurred()
                                    // Keep playing action
                                    aiManager.waitingForContinueButton = false
                                    Task {
                                        await aiManager.startNextGame()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.circle")
                                        Text("Keep Playing")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(darkBlue)
                                    .clipShape(Capsule())
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                    else if !aiManager.isLoading {
                        HStack(spacing: 10) {
                            ForEach(Array(aiManager.getPossibleActions().enumerated()), id: \.offset) { index, action in
                                Button(action: {
                                    // Trigger haptics
                                    let generator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                                    
                                    
                                    if action == "Raise" {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            raiseMenuVisible.toggle()
                                        }
                                    }
                                    else {
                                        generator.impactOccurred()
                                        aiManager.handleUserMove(move:(action.lowercased(), 0.0))
                                        
                                        raiseMenuVisible = false
                                    }
                                }) {
                                    Text("\(action)")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(darkBlue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                        .opacity(aiManager.waitingForUserInput ? 1.0 : 0.5)
                                }.disabled(!aiManager.waitingForUserInput)
                            }
                        }.id(aiManager.waitingForUserInput)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }.padding(4)
            }.padding(.horizontal)
            .padding(.bottom, 16)

        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if aiManager.canSkip {
                    // A button with the word skip and forward.fill icon
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        aiManager.skipActive = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                        }
                    }
                }
                
            }
        }
        .onAppear {
            aiManager.context = context
            aiManager.profile = userProfile.profile
            aiManager.setAPIManager(authManager: authManager)
        }
        .toast(
            isPresenting: $aiManager.showToast,
            duration: 10,
            tapToDismiss: true,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .error(.red),
                    title: aiManager.errorMessage,
                    subTitle: nil
                )
            },
            completion: {
                aiManager.showToast = false
            }
        )
        .sheet(item: $selectedPlayer) { player in
            PlayerInfoSheet(player: player, game: aiManager.game, round: aiManager.round)
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
        }
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.dark)
        .task {
            aiManager.resetGame()
            await aiManager.populateAINames()
        }
    }
}

#Preview {
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
    
    return AITable(tableSize: "6")
        .environment(\.modelContext, context)
        .environmentObject(UserProfileState(context: context))
        .environmentObject(AuthManager())
}

