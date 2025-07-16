//
//  ProfileView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 7/16/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile").font(.title).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
        .background(Color.black)
    }
}

#Preview {
    ProfileView()
}
