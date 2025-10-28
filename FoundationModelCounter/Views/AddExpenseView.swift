//
//  AddExpenseView.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import SwiftUI
import PhotosUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var defaultTransactionType: TransactionType = .expense
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var recognizedText = ""
    @State private var errorMessage: String?
    
    // 账目信息
    @State private var transactionType: TransactionType = .expense
    @State private var date = Date()
    @State private var amount = ""
    @State private var currency = "CNY"
    @State private var mainCategory = "其他"
    @State private var subCategory = "其他"
    @State private var merchant = ""
    @State private var note = ""
    
    let currencies = ["CNY", "USD", "EUR", "JPY", "GBP", "HKD"]
    let categories = ExpenseCategory.allCases
    
    @State private var availableMainCategories: [String] = []
    @State private var availableSubCategories: [String] = []
    
    var selectedCategorySubcategories: [String] {
        availableSubCategories.isEmpty ? ["其他"] : availableSubCategories
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 图片选择区域
                Section {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button(action: { showImagePicker = true }) {
                        Label(selectedImage == nil ? "选择账单图片" : "更换图片", 
                              systemImage: "photo.on.rectangle")
                    }
                    
                    if !recognizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("识别的文本")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(recognizedText)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                } header: {
                    Text("账单图片")
                }
                
                // 账目信息
                Section {
                    // 交易类型选择
                    Picker("类型", selection: $transactionType) {
                        Text("支出").tag(TransactionType.expense)
                        Text("收入").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: transactionType) { oldValue, newValue in
                        loadCategories()
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
                
                // 错误信息
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("添加\(transactionType.rawValue)")
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
                    .disabled(amount.isEmpty || isProcessing)
                }
            }
            .photosPicker(isPresented: $showImagePicker, selection: Binding(
                get: { nil },
                set: { newValue in
                    if let newValue {
                        loadImage(from: newValue)
                    }
                }
            ), matching: .images)
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("正在分析账单...")
                                .font(.headline)
                        }
                        .padding(30)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .onAppear {
                transactionType = defaultTransactionType
                loadCategories()
            }
        }
    }
    
    private func loadCategories() {
        // 初始化默认类目（如果需要）
        CategoryService.shared.initializeDefaultCategories(context: modelContext)
        
        // 根据交易类型加载可用的大类
        availableMainCategories = CategoryService.shared.getMainCategories(
            context: modelContext,
            transactionType: transactionType
        )
        
        // 如果主类目为空或为默认值，设置为第一个可用类目
        if mainCategory == "其他" || mainCategory.isEmpty || !availableMainCategories.contains(mainCategory) {
            mainCategory = availableMainCategories.first ?? "其他"
        }
        
        updateSubCategories()
    }
    
    private func updateSubCategories() {
        availableSubCategories = CategoryService.shared.getSubCategories(
            for: mainCategory,
            context: modelContext,
            transactionType: transactionType
        )
        
        // 如果小类不在可用列表中，重置为第一个
        if !availableSubCategories.contains(subCategory) {
            subCategory = availableSubCategories.first ?? "其他"
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                await processImage(image)
            }
        }
    }
    
    private func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            // 步骤 1: OCR 识别文字
            recognizedText = try await OCRService.shared.recognizeText(from: image)
            
            // 步骤 2: AI 分析账单信息
            let expenseInfo = try await AIExpenseAnalyzer.shared.analyzeExpense(
                from: recognizedText, 
                context: modelContext,
                preferredType: transactionType
            )
            
            // 步骤 3: 填充表单
            await MainActor.run {
                // 更新交易类型
                if let typeString = expenseInfo.transactionType,
                   let type = TransactionType(rawValue: typeString) {
                    transactionType = type
                    loadCategories()
                }
                
                if let dateString = expenseInfo.date {
                    date = parseDate(from: dateString) ?? Date()
                }
                
                if let amt = expenseInfo.amount {
                    amount = String(format: "%.2f", amt)
                }
                
                if let curr = expenseInfo.currency {
                    currency = curr
                }
                
                if let main = expenseInfo.mainCategory {
                    mainCategory = main
                    updateSubCategories()
                }
                
                if let sub = expenseInfo.subCategory {
                    subCategory = sub
                }
                
                if let merc = expenseInfo.merchant {
                    merchant = merc
                }
                
                if let nt = expenseInfo.note {
                    note = nt
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "处理失败：\(error.localizedDescription)"
            }
        }
        
        isProcessing = false
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
        
        let expense = Expense(
            transactionType: transactionType.rawValue,
            date: date,
            amount: amountValue,
            currency: currency,
            mainCategory: mainCategory,
            subCategory: subCategory,
            merchant: merchant,
            note: note,
            originalText: recognizedText,
            imageData: selectedImage?.jpegData(compressionQuality: 0.7)
        )
        
        modelContext.insert(expense)
        
        // 保存数据库
        try? modelContext.save()
        
        dismiss()
    }
    
    // 解析日期字符串（支持多种格式）
    private func parseDate(from dateString: String) -> Date? {
        let trimmed = dateString.trimmingCharacters(in: .whitespaces)
        
        // 尝试格式1: YYYY-MM-DD HH:mm:ss
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter1.locale = Locale(identifier: "en_US_POSIX")
        formatter1.timeZone = TimeZone.current  // 使用本地时区
        if let date = formatter1.date(from: trimmed) {
            return date
        }
        
        // 尝试格式2: YYYY-MM-DD
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd"
        formatter2.locale = Locale(identifier: "en_US_POSIX")
        formatter2.timeZone = TimeZone.current
        if let date = formatter2.date(from: trimmed) {
            return date
        }
        
        // 尝试格式3: ISO8601 (如果 AI 还是返回了这种格式)
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: trimmed) {
            return date
        }
        
        // 尝试不带分数秒的 ISO8601
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: trimmed) {
            return date
        }
        
        return nil
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: Expense.self, inMemory: true)
}

