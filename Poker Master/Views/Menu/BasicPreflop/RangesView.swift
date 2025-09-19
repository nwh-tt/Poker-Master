import SwiftUI

struct RangesView: View {
    let key: String
    var ranges: [String: [String]]
    var hand: String
    
    init(key: String, hand: String) {
        self.key = key
        self.hand = hand.replacingOccurrences(of: "10", with: "T")
        self.ranges = RangesFileManager.loadRanges()
        
    }
    
    private let ranks = ["A","K","Q","J","T","9","8","7","6","5","4","3","2"]
    
    var body: some View {
        let raiseKey = "\(key)_raise"
        let callKey = "\(key)_call"
        
        let raiseHands = Set(ranges[raiseKey] ?? [])
        let callHands = Set(ranges[callKey] ?? [])
        
        VStack(spacing: 2) {
            ForEach(Array(0..<13), id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(Array(0..<13), id: \.self) { col in
                        let hand = handFor(row: row, col: col)
                        
                        let handAction: String = {
                            if raiseHands.contains(hand) {
                                return "raise"
                            } else if callHands.contains(hand) {
                                return "call"
                            } else {
                                return "fold"
                            }
                        }()
                        
                        Text(hand)
                            .font(.system(size: 8))
                            .frame(width: 24, height: 24)
                            .background(colorFor(action: handAction))
                            .foregroundColor(.white)
                            .cornerRadius(3)
                            .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(hand == self.hand ? Color.yellow : Color.clear, lineWidth: 2)
                                )
                    }
                }
            }
        }
        .padding()
        
        HStack(spacing: 16) {
                LabelView(color: colorFor(action: "raise"), text: "Raise")
                LabelView(color: colorFor(action: "call"), text: "Call")
                LabelView(color: colorFor(action: "fold"), text: "Fold")
        }.padding(.bottom, 24)
    }
    
    // Small helper view for legend items
    struct LabelView: View {
        let color: Color
        let text: String
        
        var body: some View {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(color)
                    .frame(width: 20, height: 20)
                    .cornerRadius(4)
                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }
    
    // Create hand labels in standard 13x13 layout
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
    
    // Color scheme: black = fold, red = raise, blue = call
    private func colorFor(action: String) -> Color {
        switch action {
        case "raise":
            return Color(red: 40/255, green: 130/255, blue: 90/255) // brighter green
        case "call":
            return Color(red: 160/255, green: 60/255, blue: 160/255) // brighter magenta/purple
        default: return .gray.opacity(0.8)
        }
    }
}

#Preview {
    RangesView(key: "open_MP", hand: "102s")
}
