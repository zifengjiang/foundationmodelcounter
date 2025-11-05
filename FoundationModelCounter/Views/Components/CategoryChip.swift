//
//  CategoryChip.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/11/05.
//

import SwiftUI

struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let transactionType: TransactionType
    let action: () -> Void

    var chipColor: Color {
        if isSelected {
            return Color.accentColor
        }
        let colorName = CategoryService.getMainCategoryColor(for: category, transactionType: transactionType)
        switch colorName {
        case "pink": return .pink.opacity(0.2)
        case "orange": return .orange.opacity(0.2)
        case "green": return .green.opacity(0.2)
        case "blue": return .blue.opacity(0.2)
        case "purple": return .purple.opacity(0.2)
        default: return Color(.systemGray5)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: CategoryService.getMainCategoryIcon(for: category, transactionType: transactionType))
                    .font(.caption)
                Text(category)
                    .font(.subheadline)
            }
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(chipColor)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

