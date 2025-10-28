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
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var recognizedText = ""
    @State private var errorMessage: String?
    
    // 账目信息
    @State private var date = Date()
    @State private var amount = ""
    @State private var currency = "CNY"
    @State private var mainCategory = "其他"
    @State private var subCategory = "其他"
    @State private var merchant = ""
    @State private var note = ""
    
    let currencies = ["CNY", "USD", "EUR", "JPY", "GBP", "HKD"]
    let categories = ExpenseCategory.allCases
    
    var selectedCategorySubcategories: [String] {
        ExpenseCategory(rawValue: mainCategory)?.subCategories ?? ["其他"]
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
                    
                    Picker("大类", selection: $mainCategory) {
                        ForEach(categories, id: \.rawValue) { category in
                            Text(category.rawValue).tag(category.rawValue)
                        }
                    }
                    .onChange(of: mainCategory) { oldValue, newValue in
                        // 当大类改变时，重置小类为该大类的第一个选项
                        subCategory = selectedCategorySubcategories.first ?? "其他"
                    }
                    
                    Picker("小类", selection: $subCategory) {
                        ForEach(selectedCategorySubcategories, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                    
                    TextField("商户", text: $merchant)
                    
                    TextField("备注", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("账目信息")
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
            .navigationTitle("添加账目")
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
            let expenseInfo = try await AIExpenseAnalyzer.shared.analyzeExpense(from: recognizedText)
            
            // 步骤 3: 填充表单
            await MainActor.run {
                if let dateString = expenseInfo.date,
                   let parsedDate = ISO8601DateFormatter().date(from: dateString) {
                    date = parsedDate
                }
                
                if let amt = expenseInfo.amount {
                    amount = String(format: "%.2f", amt)
                }
                
                if let curr = expenseInfo.currency {
                    currency = curr
                }
                
                if let main = expenseInfo.mainCategory {
                    mainCategory = main
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
        
        let expense = Expense(
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
        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: Expense.self, inMemory: true)
}

