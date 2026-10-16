//
//  GameViewModel.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/28/26.
//

import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var playerCards: [Card] = []
    @Published var splitCards: [Card] = []
    @Published var dealerCards: [Card] = []
    
    @Published var isPlayerTurn: Bool = true
    @Published var isSplitTurn: Bool = false
    @Published var isGameOver: Bool = false
    @Published var gameStatusMessage: String = ""
    @Published var gameResultColor: Color = .white
    
    // Financial & Session Limits
    @Published var currentBet: Int = 10
    @Published var bankroll: Int = 100
    @Published var borrowedAmount: Int = 100
    @Published var sessionGamesPlayed: Int = 0
    
    var onGameResult: ((_ isWin: Bool, _ isTie: Bool, _ netProfit: Int) -> Void)?
    
    // MARK: - Private Deck Initialization
    private let fullDeck: [Card] = {
        let suits = ["♠️️", "❤️", "♣️", "♦️"]
        let ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
        return suits.flatMap { suit in
            ranks.map { rank in Card(suit: suit, rank: rank) }
        }
    }()
    
    private var activeDeck: [Card] = []

    init() {
        startNewGame()
    }

    // MARK: - Hand Valuation
    var playerCardSum: Int { playerCards.handValue }
    var splitCardSum: Int { splitCards.handValue }
    var dealerCardSum: Int { dealerCards.handValue }

    var canSplit: Bool {
        isPlayerTurn && !isGameOver && playerCards.count == 2 && splitCards.isEmpty && (playerCards[0].splitValue == playerCards[1].splitValue)
    }

    // MARK: - Strategy Trainer Advisor
    var recommendedMove: String {
        guard isPlayerTurn && !isGameOver, let dealerUpCard = dealerCards.first?.baseValue else { return "" }
        let hand = isSplitTurn ? splitCardSum : playerCardSum
        
        if hand <= 11 { return "Recommendation: HIT (Low Total)" }
        if hand >= 17 { return "Recommendation: STAND (Bust Risk)" }
        if dealerUpCard >= 7 { return "Recommendation: HIT (Dealer Strong)" }
        return "Recommendation: STAND (Dealer Weak)"
    }

    // MARK: - Setup & Game Lifecycle
    func setupInitialBankroll(_ amount: Int) {
        self.borrowedAmount = amount
        self.bankroll = amount
    }

    func startNewGame(sessionLimit: Int = 0) {
        // Enforce maximum hands per app session if enabled in settings
        if sessionLimit > 0 && sessionGamesPlayed >= sessionLimit {
            withAnimation(.easeInOut(duration: 0.2)) {
                gameStatusMessage = "Session limit of \(sessionLimit) hands reached! You are stopped from playing further. Go to Settings to update your limit."
                gameResultColor = Color(hex: "#FFD43B")
                isGameOver = true
                isPlayerTurn = false
            }
            HapticManager.shared.notification(.warning)
            return
        }

        guard bankroll >= 5 else {
            withAnimation {
                gameStatusMessage = "Out of funds! Borrow more money to play."
                gameResultColor = Color(hex: "#FF6B6B")
                isGameOver = true
                isPlayerTurn = false
            }
            return
        }
        
        currentBet = min(max(currentBet, 5), min(100, bankroll))
        activeDeck = fullDeck.shuffled()
        
        withAnimation(.easeInOut(duration: 0.25)) {
            playerCards = []
            splitCards = []
            dealerCards = []
            isPlayerTurn = true
            isSplitTurn = false
            isGameOver = false
            gameStatusMessage = "Place your move!"
            gameResultColor = .white
        }
        
        if activeDeck.count >= 3 {
            let card1 = activeDeck.removeFirst()
            let card2 = activeDeck.removeFirst()
            let card3 = activeDeck.removeFirst()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                playerCards.append(card1)
                HapticManager.shared.impact(.light)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.dealerCards.append(card2)
                    HapticManager.shared.impact(.light)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.playerCards.append(card3)
                    HapticManager.shared.impact(.light)
                }
                self.checkInitialState()
            }
        }
    }

    private func checkInitialState() {
        if playerCardSum == 21 {
            let winAmount = Int(Double(currentBet) * 1.5) // Standard 3:2 Blackjack payout
            bankroll += winAmount
            sessionGamesPlayed += 1
            withAnimation {
                gameStatusMessage = "BLACKJACK! Won $\(winAmount)"
                gameResultColor = Color(hex: "#51CF66")
                isGameOver = true
                isPlayerTurn = false
            }
            HapticManager.shared.notification(.success)
            SoundManager.shared.playSound(.win)
            onGameResult?(true, false, winAmount)
        }
    }

    // MARK: - Gameplay Actions
    func executeHit() {
        guard isPlayerTurn && !isGameOver && !activeDeck.isEmpty else { return }
        HapticManager.shared.impact(.medium)
        
        let newCard = activeDeck.removeFirst()
        
        if isSplitTurn {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                splitCards.append(newCard)
            }
            if splitCardSum > 21 {
                isSplitTurn = false
                withAnimation {
                    gameStatusMessage = "Split Hand Busted! Main hand turn."
                    gameResultColor = Color(hex: "#FF6B6B")
                }
            }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                playerCards.append(newCard)
            }
            
            if playerCardSum > 21 {
                if !splitCards.isEmpty && splitCardSum <= 21 {
                    withAnimation {
                        gameStatusMessage = "Main hand busted! Resolving split hand..."
                    }
                    executeStand()
                } else {
                    bankroll -= currentBet
                    sessionGamesPlayed += 1
                    withAnimation {
                        gameStatusMessage = "BUST! Lost $\(currentBet)"
                        gameResultColor = Color(hex: "#FF6B6B")
                        isGameOver = true
                        isPlayerTurn = false
                    }
                    HapticManager.shared.notification(.error)
                    SoundManager.shared.playSound(.lose)
                    onGameResult?(false, false, -currentBet)
                }
            } else if playerCardSum == 21 {
                executeStand()
            }
        }
    }

    func executeStand() {
        guard isPlayerTurn && !isGameOver else { return }
        HapticManager.shared.impact(.light)
        
        if isSplitTurn {
            isSplitTurn = false
            withAnimation {
                gameStatusMessage = "Main Hand turn."
                gameResultColor = .white
            }
        } else {
            isPlayerTurn = false
            
            let mainBusted = playerCardSum > 21
            let splitBusted = !splitCards.isEmpty && splitCardSum > 21
            let allBusted = mainBusted && (splitCards.isEmpty || splitBusted)
            
            if !allBusted {
                runDealerAutomatedAI()
            } else {
                evaluateWinner()
            }
        }
    }

    func executeDoubleDown() {
        // This version supports double-down only before any split to keep per-hand bet accounting correct.
        guard isPlayerTurn && !isGameOver && playerCards.count == 2 && splitCards.isEmpty && bankroll >= (currentBet * 2) else { return }
        HapticManager.shared.impact(.heavy)
        currentBet *= 2
        executeHit()
        if !isGameOver {
            executeStand()
        }
    }

    func executeSplit() {
        guard canSplit && activeDeck.count >= 2 else { return }
        HapticManager.shared.impact(.medium)
        
        if bankroll < (currentBet * 2) {
            let maxAllowedBet = bankroll / 2
            currentBet = max(5, maxAllowedBet)
            gameStatusMessage = "Bet adjusted to $\(currentBet) per hand to fit balance."
            gameResultColor = Color(hex: "#FFD43B")
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let splitCard = playerCards.removeLast()
            splitCards.append(splitCard)
            playerCards.append(activeDeck.removeFirst())
            splitCards.append(activeDeck.removeFirst())
            isSplitTurn = true
        }
    }

    // MARK: - Dealer AI & Outcome Resolution
    private func runDealerAutomatedAI() {
        if dealerCardSum < 17 && !activeDeck.isEmpty {
            let newCard = activeDeck.removeFirst()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                dealerCards.append(newCard)
                HapticManager.shared.impact(.light)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.runDealerAutomatedAI()
            }
        } else {
            evaluateWinner()
        }
    }

    private func evaluateWinner() {
        isGameOver = true
        sessionGamesPlayed += 1
        var netProfit = 0

        func evaluateHand(sum: Int, bet: Int) -> Int {
            if sum > 21 { return -bet }
            if dealerCardSum > 21 { return bet }
            if sum > dealerCardSum { return bet }
            if sum < dealerCardSum { return -bet }
            return 0
        }

        let mainProfit = evaluateHand(sum: playerCardSum, bet: currentBet)
        netProfit += mainProfit

        if !splitCards.isEmpty {
            let splitProfit = evaluateHand(sum: splitCardSum, bet: currentBet)
            netProfit += splitProfit
        }

        bankroll += netProfit

        withAnimation {
            if netProfit > 0 {
                gameStatusMessage = "PLAYER WINS! Profit: +$\(netProfit)"
                gameResultColor = Color(hex: "#51CF66")
                HapticManager.shared.notification(.success)
                SoundManager.shared.playSound(.win)
                onGameResult?(true, false, netProfit)
            } else if netProfit < 0 {
                gameStatusMessage = "DEALER WINS! Lost $\(abs(netProfit))"
                gameResultColor = Color(hex: "#FF6B6B")
                HapticManager.shared.notification(.error)
                SoundManager.shared.playSound(.lose)
                onGameResult?(false, false, netProfit)
            } else {
                gameStatusMessage = "PUSH! It's a Tie."
                gameResultColor = Color(hex: "#FFD43B")
                HapticManager.shared.notification(.warning)
                SoundManager.shared.playSound(.tie)
                onGameResult?(false, true, 0)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
