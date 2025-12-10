//
//  VillainRangeView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/9/25.
//
import SwiftUI

struct VillainRangeView: View {
    let villainRange: [String]

    private let ranks = ["A","K","Q","J","T","9","8","7","6","5","4","3","2"]

    @State private var rowVisible: [Bool] = []

    var body: some View {
        VStack {
            Text("Villain Range")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 0) {
                ForEach(ranks.indices, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(ranks.indices, id: \.self) { colIndex in
                            let hand = handLabel(row: ranks[rowIndex], col: ranks[colIndex])
                            Text(" ")
                                .font(.system(size: 6, weight: .semibold))
                                .frame(width: 12, height: 12)
                                .background(
                                    villainRange.contains(hand) ?
                                    Color.green.opacity(0.8) : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(villainRange.contains(hand) ? .white : .black)
                        }
                    }
                    .opacity(rowVisible.count > rowIndex && rowVisible[rowIndex] ? 1 : 0)
                    .scaleEffect(rowVisible.count > rowIndex && rowVisible[rowIndex] ? 1 : 0.8)
                    .offset(y: rowVisible.count > rowIndex && rowVisible[rowIndex] ? 0 : 10)
                    .animation(.easeOut(duration: 0.2).delay(Double(rowIndex) * 0.05), value: rowVisible)
                }
            }
        }
        .padding()
        // Animate on appear and when villainRange changes
        .onChange(of: villainRange) {
            rowVisible = Array(repeating: false, count: ranks.count)
            // Step 2: animate in after a tiny delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animateRows()
                }
        }
        .onAppear {
            animateRows()
        }
    }

    private func animateRows() {
        // Reset visibility
        rowVisible = Array(repeating: false, count: ranks.count)

        // Animate each row sequentially
        for i in ranks.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation {
                    rowVisible[i] = true
                }
            }
        }
    }

    private func handLabel(row: String, col: String) -> String {
        if row == col {
            return row + row
        } else if ranks.firstIndex(of: row)! < ranks.firstIndex(of: col)! {
            return row + col + "s"
        } else {
            return col + row + "o"
        }
    }
}


#Preview {
    VillainRangeView(villainRange: ["AA", "AKs", "AKo", "QQ", "JJ", "AJs", "KQs"])
}
