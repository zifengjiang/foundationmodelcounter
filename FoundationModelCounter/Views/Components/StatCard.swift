//
//  StatCard.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/11/05.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Text(String(format: "%.2f", amount))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: amount)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(String(format: "%.2f", amount))元")
    }
}

