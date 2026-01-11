//
//  EquitySettingsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/11/25.
//

import SwiftUI
import SwiftData

struct EquitySettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStreet: String = "Any"
    @State private var selectedEquityType: String = "Any"
    @State private var navigateToTable = false
    
    let streetOptions = ["Any", "Preflop", "Flop", "Turn"]
    let equityOptions = ["Any", "Ranges", "Cards"]
    
        
    
    var body: some View {
        VStack(spacing: 24) {
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
                
            NavigationLink(
                destination: EquityTable(street: "Any", villainType: "Any", authManager: authManager)
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
            
            Spacer()
        }
        .padding()
        .navigationTitle("Options")
        .preferredColorScheme(.dark)
    }
}

#Preview {
    @Previewable @StateObject var authManager = AuthManager()
    EquitySettingsView()
        .environmentObject(authManager)
}
