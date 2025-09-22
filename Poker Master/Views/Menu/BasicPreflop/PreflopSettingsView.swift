//
//  PreflopSettingsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/30/25.
//

import SwiftUI
struct PreflopSettingsView: View {
    private let rangeHelper = RangeHelper() // instantiate your helper
    
    let betDisplayMapping: [String: String] = [
        "Any": "Any",
        "open": "Open",
        "bet2": "2",
        "bet3": "3",
        "bet4": "4",
        "bet5": "5"
    ]
    
    @State private var selectedSpeed: Double = 3
    @State private var selectedPosition: String = "Any"
    @State private var selectedBet: String = "Any"
    
    var positions: [String] {
        ["Any"] + rangeHelper.positionOrders["6"]! // keeps your position picker same
    }
    
    var availableBets: [String] {
        // If hero is "Any", show all bets, otherwise use helper
        if selectedPosition == "Any" {
            return ["Any", "open", "bet2", "bet3", "bet4", "bet5"]
        } else {
            return ["Any"] + rangeHelper.getBetOptions(heroPosition: selectedPosition)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Speed
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gameplay Speed")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Slider(value: $selectedSpeed, in: 1...5, step: 0.1)
                        .tint(Color(red: 50/255, green: 130/255, blue: 80/255))
                }.padding(.bottom)
                
                // Position Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Picker("Position", selection: $selectedPosition) {
                        ForEach(positions, id: \.self) { pos in
                            Text(pos).tag(pos)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.green)
                }
                
                // Bet Number Picker
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
                    .onChange(of: selectedPosition) { newValue in
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
                                colors: [Color(red: 19/255, green: 70/255, blue: 50/255),
                                         Color(red: 50/255, green: 130/255, blue: 80/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
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
