//
//  PreflopSettingsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/30/25.
//

import SwiftUI
struct PreflopSettingsView: View {
    private let rangeHelper = RangeHelper() // instantiate your helper
    
    let tableSizes: [String] = ["6", "9"]
    
    let betDisplayMapping: [String: String] = [
        "Any": "Any",
        "open": "Open",
        "bet2": "2",
        "bet3": "3",
        "bet4": "4",
        "bet5": "5"
    ]
    
    @State private var selectedSpeed: Double = 3
    @State private var selectedTableSize: String = "6"
    @State private var selectedPosition: String = "Any"
    @State private var selectedBet: String = "Any"
    
    var availableBets: [String] {
        // If hero is "Any", show all bets, otherwise use helper
        if selectedPosition == "Any" {
            return ["Any", "open", "bet2", "bet3", "bet4", "bet5"]
        } else {
            return ["Any"] + rangeHelper.getBetOptions(heroPosition: selectedPosition, size: selectedTableSize)
        }
    }
    
    @State private var positions: [String] = []

    init() {
        // Set initial positions to "6"-max table
        _positions = State(initialValue: ["Any"] + (RangeHelper().positionOrders["6"] ?? []))
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
                
                // Table size picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Players")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Picker("Players", selection: $selectedTableSize) {
                        ForEach(tableSizes, id: \.self) { size in
                            Text(size).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.green)
                    .onChange(of: selectedTableSize) {
                        let basePositions = rangeHelper.positionOrders[selectedTableSize] ?? []
                        positions = ["Any"] + basePositions
                        
                    }
                }
                
                // Position Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    if selectedTableSize == "6" {
                        Picker("Position", selection: $selectedPosition) {
                            ForEach(positions, id: \.self) { pos in
                                Text(pos).tag(pos)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.green)
                    } else {
                        Menu {
                                    Picker("Position", selection: $selectedPosition) {
                                        ForEach(positions, id: \.self) { pos in
                                            Text(pos).tag(pos)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedPosition.isEmpty ? "Select Position" : selectedPosition)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(white: 0.15))
                                    .cornerRadius(8)
                                }
                    }
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
                    .onChange(of: selectedPosition) { newValue, oldValue in
                        if !availableBets.contains(selectedBet) {
                            selectedBet = availableBets.first ?? "open"
                        }
                    }
                }
                
                // START BUTTON
                NavigationLink(
                    destination: PokerTableView(speed: selectedSpeed, heroPosition: selectedPosition, action: selectedBet, size: selectedTableSize)
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
