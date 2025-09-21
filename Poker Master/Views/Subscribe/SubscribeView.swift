import SwiftUI

struct SubscribeView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
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
                    Text("Upgrade to Premium")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Unlock the full power of Poker Master")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                    // Free vs Premium columns
                    HStack(spacing: 16) {
                        // Free plan
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Free")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            featureBullet("20 Equity Hands / Day")
                            featureBullet("Ads")
                            featureBullet("Basic Solver")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        // Premium plan
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Premium")
                                .font(.headline)
                                .foregroundColor(Color(red: 50/255, green: 130/255, blue: 80/255))
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            featureBullet("Unlimited Premium Hands")
                            featureBullet("Ad-Free")
                            featureBullet("Premium Solver")
                            featureBullet("Early Access to New Features")
                            featureBullet("Custom Ranges")
                            featureBullet("Detailed Analytics")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 19/255, green: 70/255, blue: 50/255).opacity(0.6),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                
                Spacer()
                
                // CTA Button
                Button {
                    // TODO: Trigger purchase flow
                    print("Subscribe tapped")
                } label: {
                    Text("Subscribe Now – $4.99 / month")
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
                .padding(.horizontal)
                
                // Restore purchases
                Button("Restore Purchases") {
                    // TODO: Restore purchases
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 8)
                
                // Close
                Button("Not now") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
            }
            .padding()
        }
    }
    
    // Bullet point style
    private func featureBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 6, height: 6)
                .padding(.top, 5)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
        }
    }
}

#Preview {
    SubscribeView()
}
