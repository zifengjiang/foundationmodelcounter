//
//  ExpenseRow.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/11/05.
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var transactionType: TransactionType {
        TransactionType(rawValue: expense.transactionType) ?? .expense
    }

    var body: some View {
        HStack(spacing: 12) {
                // 分类图标
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: categoryIcon)
                    .foregroundStyle(categoryColor)
                    .font(.system(size: 20))
            }

                // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(expense.merchant.isEmpty ? expense.subCategory : expense.merchant)
                        .font(.headline)

                        // 分期标识
                    if expense.isInstallment {
                        HStack(spacing: 2) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 10))
                            Text("\(expense.installmentNumber)/\(expense.installmentPeriods)")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    }
                }

                HStack(spacing: 4) {
                    Text(expense.mainCategory)
                    Text("·")
                    Text(expense.subCategory)
                    Text("·")
                    Text(formatTime(expense.date))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

                // 金额
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    Text(transactionType == .income ? "+" : "-")
                        .foregroundStyle(transactionType == .income ? .green : .red)
                    Text(String(format: "%.2f", expense.amount))
                        .foregroundStyle(transactionType == .income ? .green : .primary)
                }
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)

                    // 如果原始货币与存储货币不同，显示原始货币信息
                if let originalCurrency = expense.originalCurrency,
                   let originalAmount = expense.originalAmount,
                   originalCurrency != expense.currency {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(expense.currency)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 2) {
                            Text("原")
                                .font(.system(size: 8))
                            Text(String(format: "%.2f", originalAmount))
                                .font(.caption2)
                            Text(originalCurrency)
                                .font(.caption2)
                        }
                        .foregroundStyle(.tertiary)
                    }
                } else {
                    Text(expense.currency)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expense.mainCategory)，\(expense.subCategory)，\(transactionType == .income ? "收入" : "支出")\(String(format: "%.2f", expense.amount))元")
        .accessibilityHint("双击查看详情")
    }

    var categoryColor: Color {
        let colorName = CategoryService.getMainCategoryColor(for: expense.mainCategory, transactionType: transactionType)
        switch colorName {
        case "pink": return .pink
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .gray
        }
    }

    var categoryIcon: String {
            // 优先使用小类图标，提供更精确的视觉反馈
        return CategoryService.getSubCategoryIcon(
            for: expense.mainCategory,
            subCategory: expense.subCategory,
            transactionType: transactionType
        )
    }

        // 格式化时间显示
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

