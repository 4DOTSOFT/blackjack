//
//  CardView.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/28/26.
//

import SwiftUI

struct CardView: View {
    let card: Card
    var isLandscape: Bool = false
    var isPad: Bool = false
    
    @State private var isDealt: Bool = false

    var body: some View {
        let cardWidth: CGFloat = isPad ? (isLandscape ? 92 : 106) : (isLandscape ? 65 : 82)
        let cardHeight: CGFloat = isPad ? (isLandscape ? 132 : 150) : (isLandscape ? 92 : 116)
        let rankFont: CGFloat = isPad ? (isLandscape ? 18 : 20) : (isLandscape ? 13 : 16)
        let cornerSuitFont: CGFloat = isPad ? (isLandscape ? 14 : 16) : (isLandscape ? 10 : 12)
        let centerSuitFont: CGFloat = isPad ? (isLandscape ? 34 : 38) : (isLandscape ? 22 : 30)

        ZStack {
            // Card Base Shadow
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 3)

            // Outer Card Border
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)

            // Top-left index
            VStack(alignment: .leading, spacing: 0) {
                Text(card.rank)
                    .font(.system(size: rankFont, weight: .bold, design: .serif))
                Text(card.suit)
                    .font(.system(size: cornerSuitFont))
            }
            .foregroundColor(card.isRed ? Color(hex: "#D63031") : Color(hex: "#2D3436"))
            .padding(isPad ? 6 : 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Center suit symbol
            VStack {
                Text(card.suit)
                    .font(.system(size: centerSuitFont))
            }

            // Bottom-right inverted index
            VStack(alignment: .trailing, spacing: 0) {
                Text(card.rank)
                    .font(.system(size: rankFont, weight: .bold, design: .serif))
                Text(card.suit)
                    .font(.system(size: cornerSuitFont))
            }
            .foregroundColor(card.isRed ? Color(hex: "#D63031") : Color(hex: "#2D3436"))
            .rotationEffect(.degrees(180))
            .padding(isPad ? 6 : 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: cardWidth, height: cardHeight)
        // Dealing Animation Modifiers
        .scaleEffect(isDealt ? 1.0 : 0.2)
        .offset(y: isDealt ? 0 : -50)
        .opacity(isDealt ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                isDealt = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.rank) of \(suitAccessibilityName)")
        .accessibilityAddTraits(.isImage)
    }

    private var suitAccessibilityName: String {
        switch card.suit {
        case "♠️": return "Spades"
        case "❤️": return "Hearts"
        case "♣️": return "Clubs"
        case "♦️": return "Diamonds"
        default: return "Suit"
        }
    }
}
