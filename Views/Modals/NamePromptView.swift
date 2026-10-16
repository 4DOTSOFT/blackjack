//
//  NamePromptView.swift
//  BlackJack
//
//  Created by Maheshkumar Palled on 9/28/26.
//

import SwiftUI

struct NamePromptView: View {
    @Binding var playerName: String
    @Binding var isPresented: Bool
    let currentBalance: Int
    var onBorrowMoney: (Int) -> Void

    @State private var inputName: String = ""
    @State private var additionalBorrow: Double = 100
    private let maxNameLength: Int = 20

    private var sanitizedName: String {
        inputName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Banner
                    VStack(spacing: 6) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "#FFD43B"))

                        Text("Profile & Virtual Loan")
                            .font(.title2)
                            .bold()

                        Text("Current Balance: $\(currentBalance)")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#51CF66"))
                    }

                    // Virtual Money & Educational Disclaimer Box
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Virtual Chips Notice")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Text("All chips, bankroll balances, and loans in this app are 100% virtual play money intended strictly for fun and strategy practice. No real-money transactions, deposits, or transfers are involved or required.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )

                    // Player Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Player Name")
                            .font(.headline)
                        TextField("Enter name", text: $inputName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(1)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                    }

                    // Additional Virtual Loan Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Borrow Additional Play Money")
                                .font(.headline)
                            Spacer()
                            Text("+$\(Int(additionalBorrow))")
                                .font(.title3)
                                .bold()
                                .foregroundColor(Color(hex: "#51CF66"))
                        }

                        Slider(value: $additionalBorrow, in: 25...10000, step: 25)
                            .tint(Color(hex: "#51CF66"))

                        HStack {
                            Text("Min: $25")
                            Spacer()
                            Text("Max: $10,000")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Text("New Total Balance: $\(currentBalance + Int(additionalBorrow))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                    }

                    // Save Button
                    Button("Confirm & Add $\(Int(additionalBorrow)) Virtual Chips") {
                        if !sanitizedName.isEmpty {
                            playerName = sanitizedName
                            onBorrowMoney(Int(additionalBorrow))
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#51CF66"))
                    .disabled(sanitizedName.isEmpty)
                }
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .navigationTitle("Player Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !playerName.isEmpty {
                        Button("Cancel") { isPresented = false }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            inputName = playerName
        }
        .onChange(of: inputName) { _, newValue in
            if newValue.count > maxNameLength {
                inputName = String(newValue.prefix(maxNameLength))
            }
        }
    }
}
