//
//  MenuView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 3/26/25.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var navState: NavigationState
    
    var body: some View {
        NavigationStack {
            VStack {
                // add a header that is white with a little spade icon
                HStack {
                    Image(systemName: "suit.spade.fill")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                    Text("Poker Master")
                        .font(.custom("Audiowide-Regular", size: 32))
                    Image(systemName: "suit.spade.fill")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                }
                .foregroundColor(.white)
                .padding(.bottom, 120)
                
                VStack {
                    NavigationLink {
                        PokerTableView(gameManager: SimplePreFlopManager())
                            .toolbar(.hidden, for: .tabBar)
                            .onAppear {
                                navState.showTabBar = false
                            }
                            .onDisappear {
                                navState.showTabBar = true
                            }
                    } label: {
                        MenuOption(gameName: "Basic Preflop", gameDescription: "Heads-up preflop decision training", gradientColor: Color(red: 80/255, green: 15/255, blue: 25/255).opacity(0.7))
                    }
                    NavigationLink {
                        PokerTableView(gameManager: GameManager())
                            .toolbar(.hidden, for: .tabBar)
                            .onAppear {
                                navState.showTabBar = false
                            }
                            .onDisappear {
                                navState.showTabBar = true
                            }
                    } label: {
                        MenuOption(gameName: "Advanced Preflop (WIP)", gameDescription: "Multiway preflop with EV", gradientColor: Color(red: 15/255, green: 32/255, blue: 60/255).opacity(0.7))
                    }
                    
                    MenuOption(gameName: "Post Flop (WIP)", gameDescription: "Multiway postflop with EV", gradientColor: Color(red: 0.0, green: 40/255, blue: 0.0).opacity(0.9))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Fill available space
            .background(Color.black)  // Set background color to black
            
        }
        
    }
        
}

#Preview {
    MenuView()
}
