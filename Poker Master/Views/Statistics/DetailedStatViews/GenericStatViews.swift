//
//  GenericStatViews.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/18/25.
//
import SwiftUI
import Charts

struct GradientBackgroundView: View {
    
    var body: some View {
        VStack(spacing: 0) {
                // Top gradient bar
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.2),
                    Color.mint.opacity(0.2)
                ],
                startPoint: .leading,   // left side
                endPoint: .trailing     // right side
            )
            .frame(height: 400)
                .overlay {
                    LinearGradient(
                        colors: [Color.clear, Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                        )
                }
                
                
                Spacer()
        }.ignoresSafeArea()
        
        EllipticalGradient(colors: [Color.teal.opacity(0.2), Color.mint.opacity(0.1), Color.clear], center: .center)
            .ignoresSafeArea()
    }
}

struct HandsPlayedStatView: View {
    let symbolName: String // Pass in "chevron.right" or "lock.fill"
    
    // Example data; you can also make these parameters if you want full flexibility
    let totalHandsPlayed: Int
    let totalHandsWon: Int
    let totalHandsLost: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Main header
            VStack(spacing: 4) {
                Text("Hands Played")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("\(totalHandsPlayed)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Divider()
                .background(Color.gray.opacity(0.5))
            
            // Won / Lost section
            HStack(spacing: 0) {
                VStack {
                    Text("Hands Won")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(totalHandsWon)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 50/255, green: 130/255, blue: 80/255))
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("Hands Lost")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(totalHandsLost)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 130/255, green: 50/255, blue: 60/255))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .applyGlass { view in
            if #available(iOS 26.0, *) {
                view
                    .glassEffect( in: .rect(cornerRadius: 16))
            }
            else {
                view
                    .background(.ultraThinMaterial)
            }
        }
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}


struct GenericStatBlock: View {
    let title: String
    let metric: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text(metric)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .applyGlass { view in
            if #available(iOS 26.0, *) {
                view
                    .glassEffect(in: .rect(cornerRadius: 16))
            }
            else {
                view
                    .background(.ultraThinMaterial)
            }
        }
        .shadow(radius: 4)
        .cornerRadius(16)
    }
}

// Structs for chart rendering
struct WinLossByCategory: Identifiable {
    let id = UUID()
    let category: String;
    let wins: Int;
    let losses: Int;
}

struct WinLossBarChartFromCategory: View {
    let title: String
    let equityHandsByType: [WinLossByCategory]
    let isLocked: Bool
    let showPremiumCallback: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .fontWeight(.semibold)
                .font(.headline)
            ZStack {
                // --- Your chart ---
                Chart(equityHandsByType) { stat in
                    BarMark(
                        x: .value("Category", stat.category.capitalizeFirst),
                        y: .value("Wins", stat.wins)
                    )
                    .foregroundStyle(Color(red: 50/255, green: 130/255, blue: 80/255))

                    BarMark(
                        x: .value("Category", stat.category.capitalizeFirst),
                        y: .value("Losses", stat.losses)
                    )
                    .foregroundStyle(Color(red: 130/255, green: 50/255, blue: 60/255))
                }
                .frame(height: 164)
                .blur(radius: isLocked ? 6 : 0)
                .disabled(isLocked)
                
                if isLocked {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.1))
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 26))
                                Text("Unlock detailed charts with premium")
                                    .font(.footnote)
                                    .opacity(0.8)
                            }
                            .foregroundColor(.white)
                        )
                        .frame(height: 170)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showPremiumCallback()
                        }
                }
            }
        }
    }
}

struct PieChartSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

struct PieChart: View {
    let values: [PieChartSlice]
    let isLocked: Bool
    let showPremiumCallback: () -> Void
    
    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple]
    
    
    // Pair values with colors cleanly
    private var coloredData: [(slice: PieChartSlice, color: Color)] {
        Array(zip(values, colors))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // MARK: Pie Chart
                Chart(coloredData, id: \.slice.id) { item in
                    SectorMark(
                        angle: .value("Count", item.slice.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color.opacity(0.9))
                    .annotation(position: .overlay) {
                        if item.slice.value > 0 {
                            Text("\(item.slice.value)")
                                .font(.caption)
                                .foregroundColor(.black)
                                .bold()
                        }
                    }
                }
                .frame(width: 270, height: 220)
                
                // MARK: Legend
                HStack(spacing: 16) {
                    ForEach(coloredData, id: \.slice.id) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color.opacity(0.9))
                                .frame(width: 12, height: 12)
                            
                            Text(item.slice.label)
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            if isLocked {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 26))
                            Text("Unlock Detailed Charts with Premium")
                                .font(.footnote)
                                .opacity(0.8)
                        }
                        .foregroundColor(.white)
                    )
                    .frame(height: 280)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showPremiumCallback()
                    }
            }
        }
    }
}


