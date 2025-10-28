//
//  ExpenseDetailView.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 账单图片
                if let imageData = expense.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 5)
                }
                
                // 金额
                HStack {
                    Spacer()
                    VStack(spacing: 5) {
                        Text(expense.currency)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", expense.amount))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.vertical)
                
                // 详细信息
                GroupBox {
                    VStack(spacing: 15) {
                        InfoRow(label: "日期", value: expense.date.formatted(date: .long, time: .shortened))
                        Divider()
                        InfoRow(label: "大类", value: expense.mainCategory)
                        Divider()
                        InfoRow(label: "小类", value: expense.subCategory)
                        
                        if !expense.merchant.isEmpty {
                            Divider()
                            InfoRow(label: "商户", value: expense.merchant)
                        }
                        
                        if !expense.note.isEmpty {
                            Divider()
                            InfoRow(label: "备注", value: expense.note)
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                // 原始文本
                if !expense.originalText.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("识别的原始文本")
                                .font(.headline)
                            Text(expense.originalText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("账目详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationView {
        ExpenseDetailView(
            expense: Expense(
                date: Date(),
                amount: 58.50,
                currency: "CNY",
                mainCategory: "餐饮",
                subCategory: "午餐",
                merchant: "麦当劳",
                note: "工作日午餐",
                originalText: "麦当劳\n2025-10-28 12:30\n总计：58.50元"
            )
        )
    }
}

