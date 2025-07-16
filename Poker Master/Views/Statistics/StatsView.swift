//
//  StatsView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        VStack {
            Text("Statistics").font(.title).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
        .background(Color.black)
    }
}

#Preview {
    StatsView()
}
