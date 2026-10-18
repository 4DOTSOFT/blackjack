//
//  TableTheme.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/29/26.
//

import SwiftUI

enum TableTheme: String, CaseIterable, Identifiable {
    case classicGreen = "Classic Green"
    case royalBlue = "Royal Blue"
    case midnightBlack = "Midnight Black"
    case crimsonRed = "Crimson Red"

    var id: String { rawValue }

    var gradientColors: [Color] {
        switch self {
        case .classicGreen:
            return [Color(hex: "#1A5220"), Color(hex: "#09230C"), Color(hex: "#041005")]
        case .royalBlue:
            return [Color(hex: "#1B3B6F"), Color(hex: "#0C1B33"), Color(hex: "#030811")]
        case .midnightBlack:
            return [Color(hex: "#2C2C2E"), Color(hex: "#1C1C1E"), Color(hex: "#0A0A0C")]
        case .crimsonRed:
            return [Color(hex: "#6B1D1D"), Color(hex: "#3D0C0C"), Color(hex: "#1A0303")]
        }
    }
}
