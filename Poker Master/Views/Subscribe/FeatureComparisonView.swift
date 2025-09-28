//
//  FeatureComparisonView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/26/25.
//

import SwiftUI


struct FeatureComparisonView: View {
    struct FeatureRow: Identifiable {
        let id = UUID()
        let name: String
        let free: Bool
        let premium: Bool
    }
    
    let features: [FeatureRow] = [
        .init(name: "Basic Training", free: true, premium: true),
        .init(name: "Advanced Stat Tracking", free: false, premium: true),
        .init(name: "Unlimited Equity Drills", free: false, premium: true),
        .init(name: "Custom Ranges", free: false, premium: true),
        .init(name: "Premium Solver", free: false, premium: true),
        .init(name: "Hand History Review", free: false, premium: true)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header row
            HStack {
                Text("Feature")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 80, alignment: .center)
                Text("Premium")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 80, alignment: .center)
            }
            
            Divider()
            
            // Feature rows
            ForEach(features) { feature in
                HStack {
                    Text(feature.name)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Image(systemName: feature.free ? "checkmark" : "xmark")
                        .foregroundColor(feature.free ? .green : .gray.opacity(0.5))
                        .frame(width: 80, alignment: .center)
                    
                    Image(systemName: feature.premium ? "checkmark" : "xmark")
                        .foregroundColor(feature.premium ? .green : .gray.opacity(0.5))
                        .frame(width: 80, alignment: .center)
                }
                Divider()
            }
        }
        .background(.black)
        .cornerRadius(12)
    }
}

#Preview {
    FeatureComparisonView()
}

