//
//  Card.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/19/26.
//

import SwiftUI

struct Card: Identifiable, Equatable {
    let id = UUID()
    let suit: String
    let rank: String
    
    var splitValue: String {
        if ["J", "Q", "K"].contains(rank) { return "10" }
        return rank
    }
    
    var baseValue: Int {
        if ["J", "Q", "K"].contains(rank) { return 10 }
        if rank == "A" { return 11 }
        return Int(rank) ?? 0
    }
    
    var isRed: Bool {
        return suit == "❤️" || suit == "♦️"
    }
}

extension Array where Element == Card {
    var handValue: Int {
        var total = self.reduce(0) { $0 + $1.baseValue }
        var aceCount = self.filter { $0.rank == "A" }.count
        
        while total > 21 && aceCount > 0 {
            total -= 10
            aceCount -= 1
        }
        return total
    }
}
