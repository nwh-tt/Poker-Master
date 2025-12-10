//
//  TableComponent.swift
//  Poker Master
//
//  Created by Ned Whittleton on 12/9/25.
//
import SwiftUI

struct PokerTableComponent: View {
    
    var body: some View {
        ZStack {
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
        }
        
    }
}
