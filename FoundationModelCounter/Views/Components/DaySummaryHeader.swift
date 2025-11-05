//
//  DaySummaryHeader.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/11/05.
//

import SwiftUI

struct DaySummaryHeader: View {
    let date: String
    let expenses: [Expense]
    let selectedType: TransactionType

        // 计算当天的收入和支出
    var dayIncome: Double {
        expenses
            .filter { $0.transactionType == TransactionType.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    var dayExpense: Double {
        expenses
            .filter { $0.transactionType == TransactionType.expense.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
                // 日期
            Text(date)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

                // 显示当天的收支统计
            HStack(spacing: 12) {
                    // 收入
                if dayIncome > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("收入")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", dayIncome))
                            .font(.subheadline)
                            .fontWeight(selectedType == .income ? .bold : .semibold)
                            .foregroundStyle(.green)
                    }
                }

                    // 支出
                if dayExpense > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("支出")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", dayExpense))
                            .font(.subheadline)
                            .fontWeight(selectedType == .expense ? .bold : .semibold)
                            .foregroundStyle(.red)
                    }
                }

                    // 净额（如果两种类型都有）
                if dayIncome > 0 && dayExpense > 0 {
                    let balance = dayIncome - dayExpense
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("净额")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%+.2f", balance))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(balance >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

