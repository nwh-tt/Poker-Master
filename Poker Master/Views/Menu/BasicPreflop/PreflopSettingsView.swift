//
//  PreflopSettingsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/30/25.
//

import SwiftUI

struct PreflopSettingsView: View {
    let heroBetMapping6player = [
        "BTN": ["Any", "Open", "vsRaise", "3Bet", "4Bet", "5Bet"],
        "SB": ["Any", "Open", "vsRaise", "3Bet", "4Bet", "5Bet"],
        "BB": ["Any", "vsRaise", "4Bet"],
        "UTG": ["Any", "Open", "3Bet", "5Bet"],
        "MP": ["Any", "Open", "vsRaise", "3Bet", "4Bet", "5Bet"],
        "CO": ["Any", "Open", "vsRaise", "3Bet", "4Bet", "5Bet"],
        "Any": ["Any", "Open", "vsRaise", "3Bet", "4Bet", "5Bet"]
    ]
    
    let betDisplayMapping: [String: String] = [
        "Any": "Any",
        "Open": "Open",
        "vsRaise": "2",
        "3Bet": "3",
        "4Bet": "4",
        "5Bet": "5"
    ]
    
    @State private var selectedSpeed: Double = 3
    @State private var selectedPosition: String = "Any"
    @State private var selectedBet: String = "Any"
    
    var availableBets: [String] {
        heroBetMapping6player[selectedPosition] ?? []
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Speed
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gameplay Speed")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Slider(value: $selectedSpeed, in: 1...5, step: 0.1) {
                        Text("Speed")
                    }
                    .tint(.purple)
                }.padding(.bottom)
                
                // Position
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Picker("Position", selection: $selectedPosition) {
                        ForEach(heroBetMapping6player.keys.sorted(), id: \.self) { pos in
                            Text(pos).tag(pos)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.green)
                }
                
                // Bet Number
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bet Number")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Picker("Bet", selection: $selectedBet) {
                        ForEach(availableBets, id: \.self) { bet in
                            Text(betDisplayMapping[bet] ?? bet).tag(bet)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.blue)
                    .onChange(of: selectedPosition) { oldValue, newValue in
                        if !availableBets.contains(selectedBet) {
                            selectedBet = availableBets.first ?? "open"
                        }
                    }
                }
                
                // START BUTTON
                NavigationLink(
                    destination: PokerTableView(speed: selectedSpeed, heroPosition: selectedPosition, action: selectedBet)
                        .toolbar(.hidden, for: .tabBar)
                ) {
                    Text("Start Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Options")
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    PreflopSettingsView()
}
