import SwiftUI

struct GameOverView: View {
    @Environment(\.dismiss) var dismiss
    let correctDecisions: Int
    let totalHands: Int
    var startNewGame: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Session Complete")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    Text("Correct Decisions: \(correctDecisions)/\(totalHands)")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                HStack(spacing: 16) {
                    // Play Again button
                    Button(action: {
                        // Restart game action
                        startNewGame()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                            Text("Play Again")
                                .foregroundColor(.white)
                                .bold()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 19/255, green: 70/255, blue: 50/255),
                                         Color(red: 50/255, green: 130/255, blue: 80/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(radius: 4)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                                Image(systemName: "house.fill") // indicates home/exit
                                    .foregroundColor(.white)
                                Text("Home")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 200/255, green: 50/255, blue: 50/255), // darker red
                                        Color(red: 255/255, green: 100/255, blue: 50/255) // orange-red
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(radius: 4)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

#Preview {
    GameOverView(correctDecisions: 9, totalHands: 10, startNewGame: {})
}
