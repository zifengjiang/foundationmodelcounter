//
//  ExpenseDetailView.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let expense: Expense
    @State private var showEditExpense = false
    @State private var showDeleteAlert = false
    @State private var showFullScreenImage = false
    @State private var showImage = false
    @State private var showOriginalText = false
    
    var transactionType: TransactionType {
        TransactionType(rawValue: expense.transactionType) ?? .expense
    }
    
    // 格式化日期为中文
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: expense.date)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 金额卡片 - 美化
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: transactionType == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundStyle(transactionType == .expense ? .red : .green)
                        Text(transactionType.rawValue)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(expense.currency)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", expense.amount))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(transactionType == .expense ? .red : .green)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(transactionType == .expense ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                )

                // 详细信息
                GroupBox {
                    VStack(spacing: 15) {
                        InfoRow(label: "日期", value: formattedDate)
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

                // 账单图片 - 折叠显示
                if let imageData = expense.imageData,
                   let image = UIImage(data: imageData) {
                    DisclosureGroup(isExpanded: $showImage) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                            .padding(.top, 8)
                            .onTapGesture {
                                showFullScreenImage = true
                            }
                            .accessibilityHint("双击查看大图")
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundStyle(Color.accentColor)
                            Text("账单图片")
                                .font(.headline)
                        }
                    }
                    .sheet(isPresented: $showFullScreenImage) {
                        FullScreenImageView(image: image)
                    }
                }
                
                // 识别的原始文本 - 折叠显示
                if !expense.originalText.isEmpty {
                    DisclosureGroup(isExpanded: $showOriginalText) {
                        Text(expense.originalText)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(Color.accentColor)
                            Text("识别的原始文本")
                                .font(.headline)
                        }
                    }
                }
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button(action: { showEditExpense = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("编辑")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { showDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("删除")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("账目详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditExpense) {
            EditExpenseView(expense: expense)
        }
        .alert("删除账目", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteExpense()
            }
        } message: {
            Text("确定要删除这条\(transactionType.rawValue)记录吗？此操作无法撤销。")
        }
    }
    
    private func deleteExpense() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        modelContext.delete(expense)
        try? modelContext.save()
        dismiss()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: iconForLabel(label))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func iconForLabel(_ label: String) -> String {
        switch label {
        case "日期": return "calendar"
        case "大类": return "folder.fill"
        case "小类": return "tag.fill"
        case "商户": return "building.2.fill"
        case "备注": return "note.text"
        default: return "circle.fill"
        }
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                // 限制缩放范围
                                if scale < 1 {
                                    withAnimation(.spring()) {
                                        scale = 1
                                        lastScale = 1
                                    }
                                } else if scale > 5 {
                                    withAnimation(.spring()) {
                                        scale = 5
                                        lastScale = 5
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        // 双击重置缩放
                        withAnimation(.spring()) {
                            scale = 1
                            lastScale = 1
                        }
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
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

