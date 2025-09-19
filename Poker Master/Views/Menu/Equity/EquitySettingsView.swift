//
//  EquitySettingsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/11/25.
//

import SwiftUI

struct EquitySettingsView: View {
    let streetOptions = ["Any", "Preflop", "Flop", "Turn"]
        
        // EQUITY TYPE
        let equityOptions = ["Any", "Ranges", "Cards"] // "Villain" = cards type
        
        @State private var selectedStreet: String = "Any"
        @State private var selectedEquityType: String = "Any"
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 24) {
                    
                    // Street Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Street")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        Picker("Street", selection: $selectedStreet) {
                            ForEach(streetOptions, id: \.self) { street in
                                Text(street).tag(street)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color(red: 50/255, green: 130/255, blue: 80/255))
                    }
                    
                    // Equity Type Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Villain")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        Picker("Equity Type", selection: $selectedEquityType) {
                            ForEach(equityOptions, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.blue)
                    }
                    
                    // START BUTTON
                    NavigationLink(
                        destination: EquityTable(street: selectedStreet) // example
                            .toolbar(.hidden, for: .tabBar)
                    ) {
                        Text("Start Equity Drill")
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
    EquitySettingsView()
}
