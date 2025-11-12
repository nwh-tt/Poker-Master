//
//  Utils.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/12/25.
//
import SwiftUI

extension Double {
    func formattedString() -> String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }
}

extension String {
    var capitalizeFirst: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}



// View extensions
extension View {
    func countingPlayerText(to value: Double, color: Color, offset: Int) -> some View {
        self.modifier(CountingPlayerText(value: value, textColor: color, textOffset: offset))
    }
}

extension View {
    func countingText(to value: Double) -> some View {
        self.modifier(CountingText(value: value))
    }
}
