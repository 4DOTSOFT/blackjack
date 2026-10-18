//
//  GameResultItem.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/29/26.
//

import SwiftUI

enum GameOutcome: String, Codable {
    case win = "WIN"
    case lose = "LOSE"
    case tie = "TIE"

    var color: Color {
        switch self {
        case .win: return Color(hex: "#51CF66")
        case .lose: return Color(hex: "#FF6B6B")
        case .tie: return Color(hex: "#FFD43B")
        }
    }

    var yValue: Double {
        switch self {
        case .win: return 1.0
        case .tie: return 0.0
        case .lose: return -1.0
        }
    }
}

struct GameResultItem: Identifiable, Codable {
    let id: UUID
    let gameIndex: Int
    let outcome: GameOutcome
    let netProfit: Int

    init(id: UUID = UUID(), gameIndex: Int, outcome: GameOutcome, netProfit: Int) {
        self.id = id
        self.gameIndex = gameIndex
        self.outcome = outcome
        self.netProfit = netProfit
    }
}
