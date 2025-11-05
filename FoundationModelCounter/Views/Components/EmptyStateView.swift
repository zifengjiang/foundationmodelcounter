//
//  EmptyStateView.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/11/05.
//

import SwiftUI

struct EmptyStateView: View {
    let transactionType: TransactionType
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                Image(systemName: transactionType == .expense ? "cart.fill" : "banknote.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.accentColor.opacity(0.6))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }

            Text("暂无\(transactionType.rawValue)记录")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text("点击右上角 + 按钮添加第一条记录")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("暂无\(transactionType.rawValue)记录，点击右上角加号按钮添加")
    }
}

