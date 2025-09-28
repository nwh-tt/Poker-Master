//
//  RangeViewer.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/21/25.
//

import SwiftUI

struct RangeViewer: View {
    let rangeHelper = RangeHelper()
    @EnvironmentObject var storeManager: StoreManager
    
    @State private var tableSize = ["6", "9"]
    @State private var isEditing = false
    @State private var showSubscribeView = false
    
    // 6-max positions by default
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
    
    @State private var selectedSize: String = "6"
    @State private var selectedScenario = "open"
    @State private var heroPosition = "UTG"
    @State private var villainPosition = "BTN"
    
    @State private var callRanges: [String] = RangeHelper().callRanges(for: "open", hero: "UTG", villain: "", size: "6")
    @State private var raiseRanges: [String] = RangeHelper().raiseRanges(for: "open", hero: "UTG", villain: "", size: "6")

    init() {
        rangeHelper.refreshRanges()
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // dark background
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Players")
                            .foregroundColor(.white)
                            .font(.headline)
                        Picker("Players", selection: $selectedSize) {
                            ForEach(tableSize, id: \.self) { size in
                                Text(size)
                                    .foregroundColor(.white)
                                    .tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(isEditing)
                        .onChange(of: selectedSize) {
                            // Need to filter displayed heros
                            heros = rangeHelper.getHeros(scenario: selectedScenario, size: selectedSize)
                            
                            // set scenario to open
                            selectedScenario = "open"
                            
                            if let firstHero = heros.first {
                                heroPosition = firstHero
                                
                                // ✅ Also recompute villains right away
                                let availableVillains = rangeHelper.getVillains(scenario: selectedScenario, heroPosition: firstHero, size: selectedSize)
                                villains = availableVillains
                                villainPosition = availableVillains.first ?? ""
                            } else {
                                heroPosition = ""
                                villains = []
                                villainPosition = ""
                            }
                            
                            let newCallRanges = rangeHelper.callRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
                            let newRaiseRanges = rangeHelper.raiseRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)

                            callRanges = newCallRanges
                            raiseRanges = newRaiseRanges
                        }
                    }
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
                        .disabled(isEditing)
                        .onChange(of: selectedScenario) {
                            // Recompute valid heroes for the selected scenario
                            let availableHeros = rangeHelper.getHeros(scenario: selectedScenario, size: selectedSize)
                            heros = availableHeros
                            
                            // Default heroPosition to the first hero if available
                            if let firstHero = availableHeros.first {
                                heroPosition = firstHero
                                
                                // ✅ Also recompute villains right away
                                let availableVillains = rangeHelper.getVillains(scenario: selectedScenario, heroPosition: firstHero, size: selectedSize)
                                villains = availableVillains
                                villainPosition = availableVillains.first ?? ""
                            } else {
                                heroPosition = ""
                                villains = []
                                villainPosition = ""
                            }
                            
                            let newCallRanges = rangeHelper.callRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
                            let newRaiseRanges = rangeHelper.raiseRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)

                            callRanges = newCallRanges
                            raiseRanges = newRaiseRanges
                        }
                    }
                    
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
                        .disabled(isEditing)
                        .onChange(of: heroPosition) {
                            let availableVillains = rangeHelper.getVillains(scenario: selectedScenario, heroPosition: heroPosition, size: selectedSize)
                            villains = availableVillains
                            
                            // Default villainPosition to the first villain if available
                            if let firstVillain = availableVillains.first {
                                villainPosition = firstVillain
                            } else {
                                // Fallback: if no villains, maybe set to empty or first position in positions array
                                villainPosition = villains.first ?? ""
                            }
                            
                            let newCallRanges = rangeHelper.callRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
                            let newRaiseRanges = rangeHelper.raiseRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)

                            callRanges = newCallRanges
                            raiseRanges = newRaiseRanges
                        }
                    }
                    
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
                            .disabled(isEditing)
                        }.onChange(of: villainPosition) {
                            let newCallRanges = rangeHelper.callRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
                            let newRaiseRanges = rangeHelper.raiseRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
                            
                            callRanges = newCallRanges
                            raiseRanges = newRaiseRanges
                        }
                    }
                    
                    
                    Divider().background(Color.white)
                    
                    // Display the range
                    RangeEditorView(callRanges: $callRanges, raiseRanges: $raiseRanges, isEditing: isEditing)
                        
                    
                    Spacer()
                }
                .padding(.vertical)
                .padding(.horizontal)
            }
            .preferredColorScheme(.dark) // enforce dark mode
        }
        .onAppear {
            rangeHelper.refreshRanges()
            
            // Also update your local states so the UI reflects the latest ranges
            callRanges = rangeHelper.callRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
            raiseRanges = rangeHelper.raiseRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
        }
        .fullScreenCover(isPresented: $showSubscribeView) {
            SubscribeView()
        }
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        // reset raise ranges
                        let newCallRanges = rangeHelper.callRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
                        let newRaiseRanges = rangeHelper.raiseRanges(for: selectedScenario, hero: heroPosition, villain: villainPosition, size: selectedSize)
                        
                        callRanges = newCallRanges
                        raiseRanges = newRaiseRanges
                        isEditing = false
                    }
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Save") {
                        // Extract base key
                        let baseKey = rangeHelper.buildKey(for: selectedScenario, hero: heroPosition, villain: villainPosition)
                        rangeHelper.saveRanges(baseKey: baseKey, size: selectedSize, raiseRanges: raiseRanges, callRanges: callRanges)
                        rangeHelper.refreshRanges()
                        isEditing = false
                    }
                } else {
                    Button("Edit") {
                        if storeManager.isSubscribed() {
                            isEditing = true
                        }
                        else {
                            // show subscribe view
                            showSubscribeView = true
                        }
                    }
                }
            }
            
        }
    }
}

#Preview {
    RangeViewer()
}
