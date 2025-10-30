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
    
    // 编辑相关的状态
    @State private var transactionType: TransactionType
    @State private var date: Date
    @State private var amount: String
    @State private var currency: String
    @State private var mainCategory: String
    @State private var subCategory: String
    @State private var merchant: String
    @State private var note: String
    
    @State private var availableMainCategories: [String] = []
    @State private var availableSubCategories: [String] = []
    
    // UI状态
    @State private var showDeleteAlert = false
    @State private var showFullScreenImage = false
    @State private var showImage = false
    @State private var showOriginalText = false
    @State private var showDiscardAlert = false
    @State private var errorMessage: String?
    
    let currencies = ["CNY", "USD", "EUR", "JPY", "GBP", "HKD"]
    let quickAmounts = [10.0, 20.0, 50.0, 100.0, 200.0, 500.0]
    
    init(expense: Expense) {
        self.expense = expense
        _transactionType = State(initialValue: TransactionType(rawValue: expense.transactionType) ?? .expense)
        _date = State(initialValue: expense.date)
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _currency = State(initialValue: expense.currency)
        _mainCategory = State(initialValue: expense.mainCategory)
        _subCategory = State(initialValue: expense.subCategory)
        _merchant = State(initialValue: expense.merchant)
        _note = State(initialValue: expense.note)
    }
    
    // 检查是否有更改
    private var hasChanges: Bool {
        let originalTransactionType = TransactionType(rawValue: expense.transactionType) ?? .expense
        let amountValue = Double(amount) ?? 0
        
        return transactionType != originalTransactionType ||
               date != expense.date ||
               abs(amountValue - expense.amount) > 0.01 ||
               currency != expense.currency ||
               mainCategory != expense.mainCategory ||
               subCategory != expense.subCategory ||
               merchant != expense.merchant ||
               note != expense.note
    }
    
    var body: some View {
        Form {
            // 账目信息
            Section {
                // 交易类型（只读）
                HStack {
                    Image(systemName: transactionType == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(transactionType == .expense ? .red : .green)
                    Text("类型")
                    Spacer()
                    Text(transactionType.rawValue)
                        .foregroundStyle(.secondary)
                }
                
                DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("金额")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                        
                        Picker("", selection: $currency) {
                            ForEach(currencies, id: \.self) { curr in
                                Text(curr).tag(curr)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                    
                    // 快速金额选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickAmounts, id: \.self) { quickAmount in
                                Button(action: {
                                    amount = String(format: "%.0f", quickAmount)
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }) {
                                    Text("¥\(Int(quickAmount))")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                
                // 大类选择 - 使用 Menu
                Menu {
                    ForEach(availableMainCategories, id: \.self) { category in
                        Button(category) {
                            mainCategory = category
                            updateSubCategories()
                        }
                    }
                } label: {
                    HStack {
                        Text("大类")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(mainCategory)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // 小类选择 - 使用 Menu
                Menu {
                    ForEach(availableSubCategories, id: \.self) { category in
                        Button(category) {
                            subCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text("小类")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(subCategory)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                TextField(transactionType == .expense ? "商户/商品" : "收入来源", text: $merchant)
                
                TextField("备注", text: $note, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("\(transactionType.rawValue)信息")
            }
            
            // 账单图片 - 折叠显示
            if let imageData = expense.imageData,
               let image = UIImage(data: imageData) {
                Section {
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
                } header: {
                    Text("附件")
                }
            }
            
            // 识别的原始文本 - 折叠显示
            if !expense.originalText.isEmpty {
                Section {
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
                } header: {
                    Text("原始信息")
                }
            }
            
            // 错误信息
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            // 删除按钮
            Section {
                Button(role: .destructive, action: { showDeleteAlert = true }) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                        Text("删除账目")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("账目详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: saveExpense) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("保存")
                    }
                }
                .disabled(!hasChanges || amount.isEmpty)
            }
        }
        .navigationBarBackButtonHidden(hasChanges)
        .toolbar {
            if hasChanges {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showDiscardAlert = true
                    }
                }
            }
        }
        .alert("放弃更改", isPresented: $showDiscardAlert) {
            Button("继续编辑", role: .cancel) { }
            Button("放弃", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("您有未保存的更改，确定要放弃吗？")
        }
        .alert("删除账目", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteExpense()
            }
        } message: {
            Text("确定要删除这条\(transactionType.rawValue)记录吗？此操作无法撤销。")
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        CategoryService.shared.initializeDefaultCategories(context: modelContext)
        availableMainCategories = CategoryService.shared.getMainCategories(
            context: modelContext,
            transactionType: transactionType
        )
        updateSubCategories()
    }
    
    private func updateSubCategories() {
        availableSubCategories = CategoryService.shared.getSubCategories(
            for: mainCategory,
            context: modelContext,
            transactionType: transactionType
        )
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else {
            errorMessage = "请输入有效的金额"
            return
        }
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        // 更新或添加类目
        if !mainCategory.isEmpty && !subCategory.isEmpty {
            _ = CategoryService.shared.addOrUpdateCategory(
                transactionType: transactionType,
                mainCategory: mainCategory,
                subCategory: subCategory,
                context: modelContext
            )
        }
        
        // 更新账目信息
        expense.transactionType = transactionType.rawValue
        expense.date = date
        expense.amount = amountValue
        expense.currency = currency
        expense.mainCategory = mainCategory
        expense.subCategory = subCategory
        expense.merchant = merchant
        expense.note = note
        
        // 保存到数据库
        try? modelContext.save()
        
        // 关闭页面
        dismiss()
    }
    
    private func deleteExpense() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        modelContext.delete(expense)
        try? modelContext.save()
        dismiss()
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

