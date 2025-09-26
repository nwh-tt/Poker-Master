//
//  RangeEditorView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/21/25.
//

import SwiftUI
import SwiftUI

struct RangeEditorView: View {
    @Binding var callRanges: [String]
    @Binding var raiseRanges: [String]
    let isEditing: Bool
    
    private let ranks = ["A","K","Q","J","T","9","8","7","6","5","4","3","2"]
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<13, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<13, id: \.self) { col in
                        let hand = handFor(row: row, col: col)
                        
                        let handAction: String = {
                            if raiseRanges.contains(hand) {
                                return "raise"
                            } else if callRanges.contains(hand) {
                                return "call"
                            } else {
                                return "fold"
                            }
                        }()
                        
                        Text(hand)
                            .font(.system(size: 7, weight: .bold))
                            .frame(width: 20, height: 20)
                            .background(colorFor(action: handAction))
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                guard isEditing else { return }
                                handleTap(on: hand, currentAction: handAction)
                            }
                    }
                }
            }
        }
        .padding()
        
        HStack(spacing: 16) {
            LabelView(color: colorFor(action: "raise"), text: "Raise")
            LabelView(color: colorFor(action: "call"), text: "Call")
            LabelView(color: colorFor(action: "fold"), text: "Fold")
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Logic
    private func handleTap(on hand: String, currentAction: String) {
        switch currentAction {
        case "fold":
            raiseRanges.append(hand)
        case "raise":
            raiseRanges.removeAll { $0 == hand }
            callRanges.append(hand)
        case "call":
            callRanges.removeAll { $0 == hand }
        default:
            break
        }
    }
    
    // MARK: - Helpers
    struct LabelView: View {
        let color: Color
        let text: String
        
        var body: some View {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func handFor(row: Int, col: Int) -> String {
        let rankRow = ranks[row]
        let rankCol = ranks[col]
        
        if row == col {
            return "\(rankRow)\(rankCol)" // pocket pair
        } else if row < col {
            return "\(rankRow)\(rankCol)s" // suited
        } else {
            return "\(rankCol)\(rankRow)o" // offsuit
        }
    }
    
    private func colorFor(action: String) -> Color {
        switch action {
        case "raise": return .green
        case "call": return Color(red: 0.4, green: 0.7, blue: 1.0)
        default: return .gray.opacity(0.8)
        }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State var callRanges: [String] = []
        @State var raiseRanges: [String] = []
        
        var body: some View {
            RangeEditorView(callRanges: $callRanges, raiseRanges: $raiseRanges, isEditing: true)
        }
    }
    
    return PreviewWrapper()
}
