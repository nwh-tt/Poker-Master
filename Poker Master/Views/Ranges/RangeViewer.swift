//
//  RangeViewer.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/21/25.
//

import SwiftUI

struct RangeViewer: View {
    let rangeHelper = RangeHelper()
    
    // 6-max positions
    @State private var heros = ["UTG", "MP", "CO", "BTN", "SB"]
    @State private var villains: [String] = []
    
    // Example scenarios with display names
    let scenarios: [String: String] = [
        "open": "Open",
        "bet2": "Raise",
        "bet3": "3 Bet",
        "bet4": "4 Bet",
        "bet5": "5 Bet"
    ]
    
    // Ordered list of scenarios
    let scenarioOrder = ["open", "bet2", "bet3", "bet4", "bet5"]
    
    @State private var selectedScenario = "open"
    @State private var heroPosition = "UTG"
    @State private var villainPosition = "BTN"
    
    var body: some View {
        ScrollView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // dark background
                
                VStack(spacing: 16) {
                    // Scenario Picker with label
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scenario")
                            .foregroundColor(.white)
                            .font(.headline)
                        Picker("Scenario", selection: $selectedScenario) {
                            ForEach(scenarioOrder, id: \.self) { key in
                                Text(scenarios[key] ?? key)
                                    .foregroundColor(.white)
                                    .tag(key)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedScenario) {
                            // Recompute valid heroes for the selected scenario
                            let availableHeros = rangeHelper.getHeros(scenario: selectedScenario)
                            heros = availableHeros
                            
                            // Default heroPosition to the first hero if available
                            if let firstHero = availableHeros.first {
                                heroPosition = firstHero
                                
                                // ✅ Also recompute villains right away
                                let availableVillains = rangeHelper.getVillains(scenario: selectedScenario, heroPosition: firstHero)
                                villains = availableVillains
                                villainPosition = availableVillains.first ?? ""
                            } else {
                                heroPosition = ""
                                villains = []
                                villainPosition = ""
                            }
                        }
                    }.padding(.bottom)
                    
                    // Hero Position Picker with label
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hero")
                            .foregroundColor(.white)
                            .font(.headline)
                        Picker("Hero Position", selection: $heroPosition) {
                            ForEach(heros, id: \.self) { pos in
                                Text(pos).foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: heroPosition) {
                            let availableVillains = rangeHelper.getVillains(scenario: selectedScenario, heroPosition: heroPosition)
                            villains = availableVillains
                            
                            // Default villainPosition to the first villain if available
                            if let firstVillain = availableVillains.first {
                                villainPosition = firstVillain
                            } else {
                                // Fallback: if no villains, maybe set to empty or first position in positions array
                                villainPosition = villains.first ?? ""
                            }
                            
                        }
                    }.padding(.bottom)
                    
                    if (selectedScenario != "open") {
                        // Villain Position Picker with label
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Villain")
                                .foregroundColor(.white)
                                .font(.headline)
                            Picker("Villain Position", selection: $villainPosition) {
                                ForEach(villains.filter { $0 != heroPosition }, id: \.self) { pos in
                                    Text(pos).foregroundColor(.white)
                                }
                            }
                            .pickerStyle(.segmented)
                        }.padding(.bottom)
                    }
                    
                    
                    Divider().background(Color.white)
                    
                    // Display the range
                    RangeEditorView(callRanges: rangeHelper.callRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition), raiseRanges: rangeHelper.raiseRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition))
                    
                    Spacer()
                }
                .padding()
            }
            .preferredColorScheme(.dark) // enforce dark mode
        }
    }
}

#Preview {
    RangeViewer()
}
