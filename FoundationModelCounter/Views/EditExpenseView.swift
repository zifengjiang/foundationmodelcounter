//
//  EditExpenseView.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let expense: Expense
    
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
    @State private var errorMessage: String?
    
    let currencies = ["CNY", "USD", "EUR", "JPY", "GBP", "HKD"]
    
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
    
    var body: some View {
        NavigationView {
            Form {
                // 账目信息
                Section {
                    // 交易类型（只读）
                    HStack {
                        Text("类型")
                        Spacer()
                        Text(transactionType.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    HStack {
                        Text("金额")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        
                        Picker("", selection: $currency) {
                            ForEach(currencies, id: \.self) { curr in
                                Text(curr).tag(curr)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                    
                    HStack {
                        Text("大类")
                        TextField("输入或选择", text: $mainCategory)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: mainCategory) { oldValue, newValue in
                                updateSubCategories()
                            }
                    }
                    
                    HStack {
                        Text("小类")
                        TextField("输入或选择", text: $subCategory)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField(transactionType == .expense ? "商户/商品" : "收入来源", text: $merchant)
                    
                    TextField("备注", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("\(transactionType.rawValue)信息")
                }
                
                // 原始信息
                if !expense.originalText.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("识别的文本")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(expense.originalText)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
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
            }
            .navigationTitle("编辑\(transactionType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveExpense()
                    }
                    .disabled(amount.isEmpty)
                }
            }
            .onAppear {
                loadCategories()
            }
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
        
        dismiss()
    }
}

#Preview {
    EditExpenseView(
        expense: Expense(
            date: Date(),
            amount: 58.50,
            currency: "CNY",
            mainCategory: "餐饮",
            subCategory: "午餐",
            merchant: "麦当劳",
            note: "工作日午餐"
        )
    )
    .modelContainer(for: Expense.self, inMemory: true)
}

