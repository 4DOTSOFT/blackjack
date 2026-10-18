//
//  HapticManager.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/29/26.
//

import UIKit
import Combine

final class HapticManager: ObservableObject {
    static let shared = HapticManager()

    @Published var isHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "isHapticsEnabled")
        }
    }

    private init() {
        // Defaults to true if key hasn't been set yet
        if UserDefaults.standard.object(forKey: "isHapticsEnabled") == nil {
            self.isHapticsEnabled = true
        } else {
            self.isHapticsEnabled = UserDefaults.standard.bool(forKey: "isHapticsEnabled")
        }
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
