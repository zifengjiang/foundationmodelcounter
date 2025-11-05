//
//  SearchEmptyView.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/11/05.
//

import SwiftUI

struct SearchEmptyView: View {
    let searchText: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.orange.opacity(0.6))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }

            Text("未找到相关记录")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text("搜索 \"\(searchText)\" 没有找到匹配的记录")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("试试其他关键词或清除筛选条件")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("搜索\(searchText)未找到相关记录")
    }
}

