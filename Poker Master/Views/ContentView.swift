//
//  ContentView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/11/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    let darkGreen = Color(red: 0, green: 0.15, blue: 0)
    let darkBlue = Color(red: 0.3, green: 0.3, blue: 0.3)
    let borderColor = Color(red: 1,green: 1,blue: 0.95).opacity(0.8)
    let padding = 40.0

    var body: some View {
        VStack {
            PokerTableView()
            HStack {
                
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
