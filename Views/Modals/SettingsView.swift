//
//  SettingsView.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/29/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var hapticManager = HapticManager.shared
    @Binding var selectedTheme: TableTheme
    
    @AppStorage("showStrategyAdvisor") private var showStrategyAdvisor: Bool = false
    @AppStorage("maxGamesPerSession") private var maxGamesPerSession: Int = 0 // 0 = Unlimited
    @AppStorage("showApplePaySupportLink") private var showApplePaySupportLink: Bool = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Audio & Haptics") {
                    Toggle("Mute Sound Effects", isOn: $soundManager.isMuted)
                        .onChange(of: soundManager.isMuted) { _, _ in
                            hapticManager.impact(.light)
                        }

                    Toggle("Enable Haptic Vibrations", isOn: $hapticManager.isHapticsEnabled)
                        .onChange(of: hapticManager.isHapticsEnabled) { _, newValue in
                            if newValue {
                                hapticManager.notification(.success)
                            }
                        }
                }

                Section("Responsible Gaming & Session Limits") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Game Limit")
                            .font(.headline)
                        Text("Setting a maximum hand limit per app launch helps cultivate mindful gameplay habits and prevents fatigued decision-making during extended practice sessions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)

                    Stepper(
                        maxGamesPerSession == 0 ? "Hand Limit: Unlimited" : "Hand Limit: \(maxGamesPerSession) hands",
                        value: $maxGamesPerSession,
                        in: 0...100,
                        step: 5
                    )
                    .onChange(of: maxGamesPerSession) { _, _ in
                        hapticManager.impact(.light)
                    }
                }

                Section("Gameplay & Training") {
                    Toggle("Show Strategy Advisor", isOn: $showStrategyAdvisor)
                        .onChange(of: showStrategyAdvisor) { _, _ in
                            hapticManager.impact(.light)
                        }
                }

                Section("Table Felt Theme") {
                    Picker("Theme Style", selection: $selectedTheme) {
                        ForEach(TableTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Support Developer (Optional)") {
                    Toggle("Show Apple Pay Support Link", isOn: $showApplePaySupportLink)
                        .onChange(of: showApplePaySupportLink) { _, _ in
                            hapticManager.impact(.light)
                        }

                    if showApplePaySupportLink {
                        Link("Support via Apple Pay (Coming Soon)", destination: URL(string: "https://example.com/apple-pay-support")!)
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }

                Section("App Store Compliance & Legal") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Entertainment Disclaimer")
                            .font(.headline)
                        Text("This app is for amusement and strategic practice only. It does not offer real-money gambling or an opportunity to win real money or prizes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Link("Privacy Policy & Terms", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
