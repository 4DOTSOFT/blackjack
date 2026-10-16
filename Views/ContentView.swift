//
//  ContentView.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/28/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    // Persistent App Storage
    @AppStorage("savedPlayerName") private var savedPlayerName: String = ""
    @AppStorage("gamesPlayed") private var gamesPlayed: Int = 0
    @AppStorage("gamesWon") private var gamesWon: Int = 0
    @AppStorage("gamesTied") private var gamesTied: Int = 0
    @AppStorage("borrowedAmount") private var borrowedAmount: Int = 100
    @AppStorage("netEarnings") private var netEarnings: Int = 0
    @AppStorage("recentHistoryData") private var recentHistoryRaw: String = ""
    @AppStorage("selectedTheme") private var selectedTheme: TableTheme = .classicGreen
    @AppStorage("showStrategyAdvisor") private var showStrategyAdvisor: Bool = false
    @AppStorage("maxGamesPerSession") private var maxGamesPerSession: Int = 0 // 0 = Unlimited

    @State private var activeSessionName: String = ""
    @State private var showNamePrompt: Bool = false
    @State private var showAnalysisView: Bool = false
    @State private var showSettingsView: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var recentHistory: [GameResultItem] = []

    private var isActionPhase: Bool {
        viewModel.isPlayerTurn && !viewModel.isGameOver
    }

    var body: some View {
        ZStack {
            // Dynamic Table Felt Radial Theme Background
            RadialGradient(
                gradient: Gradient(colors: selectedTheme.gradientColors),
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                VStack(spacing: isLandscape ? 4 : 8) {
                    // Top Header Bar
                    headerView(isLandscape: isLandscape)

                    // Table Divider Accent
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.clear, Color(hex: "#D4AF37"), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 1)
                        .padding(.horizontal)

                    // Strategy Advisor Banner (Only visible when turned ON in Settings)
                    if showStrategyAdvisor && !viewModel.recommendedMove.isEmpty {
                        Text(viewModel.recommendedMove)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#FFD43B"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                    }

                    // Main Gameplay Table Layout
                    if isLandscape {
                        HStack(alignment: .top, spacing: 12) {
                            ScrollView(.vertical, showsIndicators: false) {
                                dealerSection(isLandscape: true)
                            }
                            .frame(maxWidth: .infinity)

                            ScrollView(.vertical, showsIndicators: false) {
                                playerSection(isLandscape: true)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 16) {
                                dealerSection(isLandscape: false)
                                playerSection(isLandscape: false)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 2)

                    // Game Outcome Status Banner
                    Text(viewModel.gameStatusMessage)
                        .font(isLandscape ? .footnote : .headline)
                        .fontWeight(.heavy)
                        .foregroundColor(viewModel.gameResultColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(20)
                        .accessibilityLabel("Game Status: \(viewModel.gameStatusMessage)")

                    // Bet Adjustment Controls
                    if isActionPhase {
                        HStack(spacing: 12) {
                            Text("BET: $\(viewModel.currentBet)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#FFD43B"))

                            let maxBet = max(5, min(100, viewModel.bankroll))
                            HStack(spacing: 10) {
                                Button(action: {
                                    viewModel.currentBet = max(5, viewModel.currentBet - 5)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(isLandscape ? .title3 : .title2)
                                        .foregroundColor(viewModel.currentBet > 5 ? Color(hex: "#FFD43B") : .gray)
                                }
                                .disabled(viewModel.currentBet <= 5)
                                .accessibilityLabel("Decrease Bet")

                                Button(action: {
                                    viewModel.currentBet = min(maxBet, viewModel.currentBet + 5)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(isLandscape ? .title3 : .title2)
                                        .foregroundColor(viewModel.currentBet < maxBet ? Color(hex: "#FFD43B") : .gray)
                                }
                                .disabled(viewModel.currentBet >= maxBet)
                                .accessibilityLabel("Increase Bet")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current Bet: \(viewModel.currentBet) dollars")
                    }

                    // Game Action Controls
                    actionButtons(isLandscape: isLandscape)
                        .padding(.horizontal, 8)

                    // Bottom Navigation / Utility Bar
                    HStack(spacing: 16) {
                        if viewModel.isGameOver {
                            Button(action: {
                                viewModel.startNewGame(sessionLimit: maxGamesPerSession)
                            }) {
                                Text("DEAL NEXT HAND")
                                    .font(isLandscape ? .caption2 : .footnote)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "#FFD43B"), Color(hex: "#B58A00")]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                    .foregroundColor(.black)
                                    .cornerRadius(20)
                            }
                            .accessibilityHint("Deals a new hand of Blackjack")
                        }

                        Button("Borrow / Profile") { showNamePrompt = true }
                            .foregroundColor(Color(hex: "#E0E0E0"))
                            .font(isLandscape ? .caption2 : .caption)
                            .accessibilityHint("Opens player profile and allows borrowing extra funds")

                        Button("Settings") { showSettingsView = true }
                            .foregroundColor(Color(hex: "#E0E0E0"))
                            .font(isLandscape ? .caption2 : .caption)
                            .accessibilityHint("Opens game settings, audio controls, session limits, and felt themes")

                        Button("Reset All") { showResetAlert = true }
                            .foregroundColor(Color(hex: "#FF8E8E"))
                            .font(isLandscape ? .caption2 : .caption)
                            .accessibilityHint("Resets your balance, stats, and match history")
                    }
                    .padding(.bottom, 4)
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            loadRecentHistory()
            activeSessionName = savedPlayerName
            viewModel.setupInitialBankroll(borrowedAmount)
            
            // Show setup modal on launch if name/age profile is missing
            if savedPlayerName.isEmpty { showNamePrompt = true }
            
            viewModel.onGameResult = { isWin, isTie, netProfit in
                gamesPlayed += 1
                if isWin { gamesWon += 1 }
                else if isTie { gamesTied += 1 }
                netEarnings += netProfit
                
                let outcome: GameOutcome = isWin ? .win : (isTie ? .tie : .lose)
                let newItem = GameResultItem(gameIndex: gamesPlayed, outcome: outcome, netProfit: netProfit)
                recentHistory.append(newItem)
                if recentHistory.count > 15 {
                    recentHistory.removeFirst(recentHistory.count - 15)
                }
                saveRecentHistory()
            }
        }
        .sheet(isPresented: $showNamePrompt) {
            NamePromptView(
                playerName: Binding(get: { savedPlayerName }, set: { savedPlayerName = $0; activeSessionName = $0 }),
                isPresented: $showNamePrompt,
                currentBalance: viewModel.bankroll,
                onBorrowMoney: { additionalAmount in
                    borrowedAmount += additionalAmount
                    viewModel.bankroll += additionalAmount
                }
            )
        }
        .sheet(isPresented: $showAnalysisView) {
            PlayerAnalysisView(
                playerName: activeSessionName,
                gamesPlayed: gamesPlayed,
                gamesWon: gamesWon,
                gamesTied: gamesTied,
                netEarnings: netEarnings,
                borrowedAmount: borrowedAmount,
                currentBalance: viewModel.bankroll,
                recentHistory: recentHistory,
                onResetAllStats: { showResetAlert = true }
            )
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(selectedTheme: $selectedTheme)
        }
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { resetAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will wipe all statistics, recent history trends, and restore bankroll to $100.")
        }
    }

    // MARK: - State Management Helpers
    private func resetAllData() {
        gamesPlayed = 0
        gamesWon = 0
        gamesTied = 0
        netEarnings = 0
        borrowedAmount = 100
        recentHistory.removeAll()
        saveRecentHistory()
        viewModel.setupInitialBankroll(100)
        viewModel.startNewGame(sessionLimit: maxGamesPerSession)
    }

    private func saveRecentHistory() {
        if let encoded = try? JSONEncoder().encode(recentHistory) {
            recentHistoryRaw = String(data: encoded, encoding: .utf8) ?? ""
        }
    }

    private func loadRecentHistory() {
        if let data = recentHistoryRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([GameResultItem].self, from: data) {
            recentHistory = decoded
        }
    }

    // MARK: - Subviews & Layout Components
    private func headerView(isLandscape: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(activeSessionName.isEmpty ? "PLAYER" : activeSessionName.uppercased())
                    .font(isLandscape ? .caption : .subheadline)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(Color(hex: "#FFD43B"))
                    Text("$\(viewModel.bankroll)")
                        .font(isLandscape ? .caption : .subheadline)
                        .bold()
                        .foregroundColor(Color(hex: "#51CF66"))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Player \(activeSessionName), Balance \(viewModel.bankroll) dollars")

            Spacer()
            
            Button(action: { showAnalysisView = true }) {
                HStack(spacing: 6) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PROFIT: \(netEarnings >= 0 ? "+$" : "-$")\(abs(netEarnings))")
                            .font(isLandscape ? .caption2 : .caption)
                            .bold()
                            .foregroundColor(netEarnings >= 0 ? Color(hex: "#51CF66") : Color(hex: "#FF6B6B"))
                        Text("HANDS: \(gamesPlayed)")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    Image(systemName: "chart.bar.fill")
                        .font(isLandscape ? .caption : .body)
                        .foregroundColor(Color(hex: "#FFD43B"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
            .accessibilityLabel("View Player Performance Analytics")
        }
        .padding(.horizontal)
    }

    private func dealerSection(isLandscape: Bool) -> some View {
        VStack(spacing: 4) {
            Text("DEALER (\(viewModel.dealerCardSum))")
                .font(isLandscape ? .caption : .subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#E0E0E0"))
                .accessibilityLabel("Dealer cards total \(viewModel.dealerCardSum)")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isLandscape ? 6 : 12) {
                    ForEach(viewModel.dealerCards) { card in
                        CardView(card: card, isLandscape: isLandscape)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func playerSection(isLandscape: Bool) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text("MAIN HAND (\(viewModel.playerCardSum))")
                        .font(isLandscape ? .caption : .subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#FFD43B"))
                        .accessibilityLabel("Player main hand total \(viewModel.playerCardSum)")

                    if !viewModel.splitCards.isEmpty {
                        Text(viewModel.isSplitTurn ? "WAIT" : "ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(viewModel.isSplitTurn ? Color.gray.opacity(0.35) : Color(hex: "#FFD43B"))
                            .foregroundColor(viewModel.isSplitTurn ? .white : .black)
                            .cornerRadius(8)
                    }
                }
                .opacity(viewModel.splitCards.isEmpty || !viewModel.isSplitTurn ? 1.0 : 0.7)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isLandscape ? 6 : 12) {
                        ForEach(viewModel.playerCards) { card in
                            CardView(card: card, isLandscape: isLandscape)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if !viewModel.splitCards.isEmpty {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text("SPLIT HAND (\(viewModel.splitCardSum))")
                            .font(isLandscape ? .caption2 : .caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#4DABF7"))
                            .accessibilityLabel("Split hand total \(viewModel.splitCardSum)")

                        Text(viewModel.isSplitTurn ? "ACTIVE" : "WAIT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(viewModel.isSplitTurn ? Color(hex: "#4DABF7") : Color.gray.opacity(0.35))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .opacity(viewModel.isSplitTurn ? 1.0 : 0.7)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: isLandscape ? 6 : 12) {
                            ForEach(viewModel.splitCards) { card in
                                CardView(card: card, isLandscape: isLandscape)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func actionButtons(isLandscape: Bool) -> some View {
        HStack(spacing: 6) {
            Button(action: viewModel.executeHit) {
                Text("HIT")
                    .actionButtonStyle(backgroundColor: Color(hex: "#20C997"), isLandscape: isLandscape)
            }
            .disabled(!viewModel.isPlayerTurn || viewModel.isGameOver)
            .accessibilityLabel("Hit")

            Button(action: viewModel.executeStand) {
                Text("STAND")
                    .actionButtonStyle(backgroundColor: Color(hex: "#FD7E14"), isLandscape: isLandscape)
            }
            .disabled(!viewModel.isPlayerTurn || viewModel.isGameOver)
            .accessibilityLabel("Stand")

            Button(action: viewModel.executeDoubleDown) {
                Text("DOUBLE")
                    .actionButtonStyle(backgroundColor: Color(hex: "#339AF0"), isLandscape: isLandscape)
            }
            .disabled(!viewModel.isPlayerTurn || viewModel.playerCards.count != 2 || viewModel.isGameOver || !viewModel.splitCards.isEmpty || viewModel.bankroll < viewModel.currentBet * 2)
            .accessibilityLabel("Double Down")

            if viewModel.canSplit {
                Button(action: viewModel.executeSplit) {
                    Text("SPLIT")
                        .actionButtonStyle(backgroundColor: Color(hex: "#FCC419"), isLandscape: isLandscape)
                }
                .accessibilityLabel("Split Hand")
            }
        }
    }
}

// MARK: - Action Button ViewModifier
struct ActionButtonStyle: ViewModifier {
    let backgroundColor: Color
    let isLandscape: Bool

    func body(content: Content) -> some View {
        content
            .font(isLandscape ? .caption : .subheadline)
            .fontWeight(.heavy)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: isLandscape ? 36 : 48)
            .background(backgroundColor)
            .cornerRadius(8)
            .shadow(radius: 2)
    }
}

extension View {
    func actionButtonStyle(backgroundColor: Color, isLandscape: Bool) -> some View {
        self.modifier(ActionButtonStyle(backgroundColor: backgroundColor, isLandscape: isLandscape))
    }
}

#Preview {
    ContentView()
}
