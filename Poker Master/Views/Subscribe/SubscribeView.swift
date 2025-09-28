import SwiftUI
import StoreKit

struct SubscribeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storeManager: StoreManager
    
    let timeFrames = ["Weekly", "Monthly", "Yearly"]
    @State private var selectedTimeFrame = "Monthly"
    
    @State private var isEligibleForTrial: Bool? = nil // nil = loading, true/false = eligibility known
    
    var buttonText: String {
        if selectedTimeFrame == "Monthly" && isEligibleForTrial == true {
            return "Try it Free for 7 days"
        } else {
            return "Subscribe Now"
        }
    }
    
    var pricingText: String {
        if selectedTimeFrame == "Weekly" {
            return "Only $2.99/week"
        } else if selectedTimeFrame == "Monthly" {
            return isEligibleForTrial == true ? "Only $4.99/month after trial ends" : "Only $4.99/month"
        } else {
            return "Only $39.99/year"
        }
    }
    
    var body: some View {
        Group {
            if isEligibleForTrial != nil {
                contentView
            } else {
                // Show a loading spinner until eligibility is determined
                ProgressView("Checking eligibility…")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            }
        }
        .task {
            // Determine trial eligibility for Monthly
            isEligibleForTrial = await storeManager.isEligibleForTrial()
            print("isEligibleForTrial: \(String(describing: isEligibleForTrial))")
        }
    }
    
    var contentView: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color(red: 15/255, green: 30/255, blue: 20/255)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text(isEligibleForTrial == true ? "Try 7 days Free" : "Get Premium")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                    Text(isEligibleForTrial == true ? "Must select monthly for free trial": "Unlock the full power of Poker Master")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                }
                
                ZStack {
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(timeFrames, id: \.self) { timeFrame in
                            Text(timeFrame)
                                .foregroundColor(.white)
                                .tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .preferredColorScheme(.dark)
                    
                    GeometryReader { geo in
                        let segmentWidth = geo.size.width / CGFloat(timeFrames.count)
                        VStack { Text("33% OFF")
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            LinearGradient( colors: [Color.green, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing ), lineWidth: 2 )
                                )
                                .offset(x: segmentWidth / 2 + segmentWidth * 2 - geo.size.width / 2) // centers above "Yearly"
                                .offset(y: -4) // move it above picker
                        }
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    }
                    .allowsHitTesting(false) // don’t block touches
                }
                FeatureComparisonView()
                    .padding(8)
                    .overlay( HStack { Spacer() // Premium highlight outline
                        RoundedRectangle(cornerRadius: 12) .stroke( LinearGradient( colors: [Color.green, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing ), lineWidth: 3 ) .frame(width: 96, height: .infinity)
                    })
                Spacer()
                
                VStack(spacing: 4) {
                    Button {
                        Task {
                            await storeManager.purchase(timeFrame: selectedTimeFrame)
                        }
                    } label: {
                        Text(buttonText)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 19/255, green: 70/255, blue: 50/255),
                                        Color(red: 50/255, green: 130/255, blue: 80/255)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    Text(pricingText)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Close button
                Button("Not now") { dismiss() }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 4)
            }
            .padding()
        }
    }
}

#Preview {
    SubscribeView()
}
