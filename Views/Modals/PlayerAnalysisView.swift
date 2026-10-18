//
//  PlayerAnalysisView.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/28/26.
//

import SwiftUI

struct PlayerAnalysisView: View {
    let playerName: String
    let gamesPlayed: Int
    let gamesWon: Int
    let gamesTied: Int
    let netEarnings: Int
    let borrowedAmount: Int
    let currentBalance: Int
    let recentHistory: [GameResultItem]
    var onResetAllStats: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var gamesLost: Int {
        max(0, gamesPlayed - gamesWon - gamesTied)
    }

    private var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return (Double(gamesWon) / Double(gamesPlayed)) * 100
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text("\(playerName.isEmpty ? "Player" : playerName)'s Analytics")
                            .font(.title2)
                            .bold()

                        Text(netEarnings >= 0 ? "🟢 Currently Profitable" : "🔴 In Loss")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    // Graphical Representation: Last 15 Games
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Hand History (Last 15)")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)

                        recentHistoryChart
                            .frame(height: horizontalChartHeight)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Financial Statistics
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Financial Breakdown")
                            .font(.headline)

                        HStack(spacing: 12) {
                            statCard(title: "Current Balance", value: "$\(currentBalance)", color: .green)
                            statCard(title: "Total Borrowed", value: "$\(borrowedAmount)", color: .orange)
                        }
                        HStack(spacing: 12) {
                            statCard(title: "Net Earnings", value: "\(netEarnings >= 0 ? "+$" : "-$")\(abs(netEarnings))", color: netEarnings >= 0 ? .green : .red)
                            statCard(title: "Win Rate", value: String(format: "%.1f%%", winRate), color: .purple)
                        }
                    }

                    // Reset Button
                    Button(role: .destructive) {
                        onResetAllStats()
                        dismiss()
                    } label: {
                        Label("Reset All Stats & Money", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .navigationTitle("Player Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var horizontalChartHeight: CGFloat {
        horizontalSizeClass == .regular ? 240 : 180
    }

    private var recentHistoryChart: some View {
        GeometryReader { geo in
            let items = Array(recentHistory.suffix(15))
            if items.isEmpty {
                VStack {
                    Spacer()
                    Text("No hands recorded yet. Start playing to view trend graph!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading) {
                            Text("WIN").font(.caption2).foregroundColor(.green)
                            Spacer()
                            Text("TIE").font(.caption2).foregroundColor(.yellow)
                            Spacer()
                            Text("LOSE").font(.caption2).foregroundColor(.red)
                        }
                        .frame(width: 38)

                        Divider()

                        HStack(alignment: .center, spacing: 0) {
                            ForEach(0..<items.count, id: \.self) { idx in
                                let item = items[idx]
                                VStack {
                                    if item.outcome == .win {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(item.outcome.color)
                                            .frame(width: 12, height: 40)
                                        Spacer()
                                    } else if item.outcome == .tie {
                                        Spacer()
                                        Circle()
                                            .fill(item.outcome.color)
                                            .frame(width: 12, height: 12)
                                        Spacer()
                                    } else {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(item.outcome.color)
                                            .frame(width: 12, height: 40)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    Text("Hand # (Oldest → Latest)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
