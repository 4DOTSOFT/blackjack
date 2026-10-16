//
//  SoundManager.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/28/26.
//

import Foundation
import AVFoundation
import Combine

final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var isMuted: Bool {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "isSoundMuted")
        }
    }

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let audioQueue = DispatchQueue(label: "com.blackjack.audio.queue")

    private init() {
        self.isMuted = UserDefaults.standard.bool(forKey: "isSoundMuted")
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let session = AVAudioSession.sharedInstance()
                // .playback category ensures sound plays EVEN IF physical Silent Switch is turned ON
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)

                self.audioEngine.attach(self.playerNode)
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
                self.audioEngine.connect(self.playerNode, to: self.audioEngine.mainMixerNode, format: format)
                try self.audioEngine.start()
            } catch {
                print("SoundManager engine initialization failed: \(error.localizedDescription)")
            }
        }
    }

    enum SoundEffect {
        case win, lose, tie

        // Musical frequencies in Hertz for synthesized casino chimes
        var frequencies: [Double] {
            switch self {
            case .win:
                return [523.25, 659.25, 783.99, 1046.50] // C5 -> E5 -> G5 -> C6 (Winning Major Arpeggio)
            case .lose:
                return [400.0, 330.0, 260.0]            // Descending Sad Tone
            case .tie:
                return [587.33, 587.33]                // Double Neutral Beep
            }
        }
    }

    func playSound(_ sound: SoundEffect) {
        guard !isMuted else { return }

        audioQueue.async { [weak self] in
            self?.synthesizeAndPlayTone(frequencies: sound.frequencies)
        }
    }

    private func synthesizeAndPlayTone(frequencies: [Double]) {
        let sampleRate: Double = 44100.0
        let noteDuration: Double = 0.10
        let totalSamples = Int(sampleRate * noteDuration * Double(frequencies.count))

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)) else {
            return
        }

        buffer.frameLength = AVAudioFrameCount(totalSamples)
        guard let channelData = buffer.floatChannelData else { return }
        let channel = channelData[0]

        var samplePointer = 0
        for freq in frequencies {
            let noteSamples = Int(sampleRate * noteDuration)
            for i in 0..<noteSamples {
                let time = Double(i) / sampleRate
                // Smooth linear decay to avoid popping clicks
                let fade = 1.0 - (Double(i) / Double(noteSamples))
                let sineValue = Float(sin(2.0 * .pi * freq * time) * 0.25 * fade)

                if samplePointer < totalSamples {
                    channel[samplePointer] = sineValue
                    samplePointer += 1
                }
            }
        }

        // Re-enable engine if paused by iOS audio interrupts
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }

        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        playerNode.play()
    }
}
