import SwiftUI

struct BoardView: View {
    let board: [Card]
    
    @State private var displayedBoard: [Card] = []
    @State private var flipped: [Bool] = Array(repeating: false, count: 5)
    
    var body: some View {
        VStack {
            Text("Board")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    if index < displayedBoard.count {
                        ZStack {
                            CardView(card: displayedBoard[index])
                                .opacity(flipped[index] ? 1 : 0)
                            CardBackViewScaled()
                                .opacity(flipped[index] ? 0 : 1)
                        }
                        .frame(width: 50, height: 70)
                        .rotation3DEffect(
                            .degrees(flipped[index] ? 0 : 180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.2), value: flipped[index])
                    } else {
                        CardBackViewScaled()
                            .frame(width: 50, height: 70)
                    }
                }
            }
            .onChange(of: board) { oldBoard, newBoard in
                // Step 1: flip all back
                for i in 0..<flipped.count {
                    flipped[i] = false
                }
                
                // Step 2: after animation delay, update displayedBoard and flip in
                let resetDelay = 0.9
                DispatchQueue.main.asyncAfter(deadline: .now() + resetDelay) {
                    displayedBoard = newBoard
                    for i in 0..<displayedBoard.count {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                            flipped[i] = true
                        }
                    }
                }
            }
            .onAppear {
                displayedBoard = board
                for i in 0..<board.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                        flipped[i] = true
                    }
                }
            }
        }
    }
}


#Preview {
    BoardView(board: [Card(suit: "heart", rank: "K"), Card(suit: "spade", rank: "A")])
}
