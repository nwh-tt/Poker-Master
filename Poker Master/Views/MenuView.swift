//
//  MenuView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 3/26/25.
//

import SwiftUI

struct MenuView: View {
    let gameModes = ["Preflop", "Flop", "Turn", "River"]
        
        var body: some View {
            NavigationView {
                VStack {
                    Text("Select a Game Mode")
                        .font(.largeTitle)
                        .padding()

                    List(gameModes, id: \.self) { mode in
                        NavigationLink(destination: PokerTableView()) {
                            Text(mode)
                                .font(.title2)
                                .padding()
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
        }
}

#Preview {
    MenuView()
}
