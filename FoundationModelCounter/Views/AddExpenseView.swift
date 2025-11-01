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
    @State private var showMainCategoryPicker = false
    @State private var showSubCategoryPicker = false
    
    let currencies = CurrencyCode.allCases.map { $0.rawValue }
    let categories = ExpenseCategory.allCases
    let quickAmounts = [10.0, 20.0, 50.0, 100.0, 200.0, 500.0]
    
    @AppStorage("defaultCurrency") private var defaultCurrency = "CNY"
    
    @State private var availableMainCategories: [String] = []
    @State private var availableSubCategories: [String] = []
    
    // 分期相关状态
    @State private var enableInstallment = false
    @State private var installmentPeriods = 3
    @State private var installmentAnnualRate = ""
    @State private var showInstallmentPreview = false
    
    // 货币转换相关状态
    @State private var isConvertingCurrency = false
    @State private var conversionRate: Double?
    
    var selectedCategorySubcategories: [String] {
        availableSubCategories.isEmpty ? ["其他"] : availableSubCategories
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 图片选择区域
                Section {
                    if let image = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button(action: {
                                withAnimation {
                                    selectedImage = nil
                                    recognizedText = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                    }
                    
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showImagePicker = true
                    }) {
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("金额")
                            Spacer()
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 150)
                                .onChange(of: amount) { oldValue, newValue in
                                    if currency != defaultCurrency {
                                        fetchConversionRate()
                                    }
                                }
                            
                            Picker("", selection: $currency) {
                                ForEach(currencies, id: \.self) { curr in
                                    Text(curr).tag(curr)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 80)
                            .onChange(of: currency) { oldValue, newValue in
                                if newValue != defaultCurrency {
                                    fetchConversionRate()
                                } else {
                                    conversionRate = nil
                                }
                            }
                        }
                        
                        // 货币转换提示
                        if currency != defaultCurrency, 
                           let amountValue = Double(amount), 
                           amountValue > 0,
                           let rate = conversionRate {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("≈ \(String(format: "%.2f", amountValue * rate)) \(defaultCurrency)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("(汇率: \(String(format: "%.4f", rate)))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.top, 2)
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
                
                // 分期设置（仅支出类型）
                if transactionType == .expense {
                    Section {
                        Toggle("启用分期", isOn: $enableInstallment)
                            .onChange(of: enableInstallment) { oldValue, newValue in
                                if newValue {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                            }
                        
                        if enableInstallment {
                            Picker("分期期数", selection: $installmentPeriods) {
                                ForEach([3, 6, 9, 12, 18, 24], id: \.self) { period in
                                    Text("\(period)期").tag(period)
                                }
                            }
                            
                            HStack {
                                Text("年化利率")
                                Spacer()
                                TextField("0.00", text: $installmentAnnualRate)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 100)
                                Text("%")
                                    .foregroundStyle(.secondary)
                            }
                            
                            // 分期预览
                            if let amountValue = Double(amount), amountValue > 0 {
                                let rate = Double(installmentAnnualRate) ?? 0.0
                                let monthlyPayment = InstallmentCalculator.calculateMonthlyPayment(
                                    principal: amountValue,
                                    annualRate: rate,
                                    periods: installmentPeriods
                                )
                                let totalInterest = InstallmentCalculator.calculateTotalInterest(
                                    principal: amountValue,
                                    annualRate: rate,
                                    periods: installmentPeriods
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("每期还款")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(format: "%.2f", monthlyPayment))
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    HStack {
                                        Text("总利息")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(format: "%.2f", totalInterest))
                                            .foregroundStyle(totalInterest > 0 ? .red : .secondary)
                                    }
                                    
                                    HStack {
                                        Text("还款总额")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(format: "%.2f", amountValue + totalInterest))
                                            .font(.headline)
                                    }
                                }
                                .padding(.vertical, 4)
                                
                                Button(action: {
                                    showInstallmentPreview.toggle()
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }) {
                                    HStack {
                                        Text(showInstallmentPreview ? "收起详情" : "查看详情")
                                        Spacer()
                                        Image(systemName: showInstallmentPreview ? "chevron.up" : "chevron.down")
                                    }
                                    .foregroundStyle(.blue)
                                }
                                
                                if showInstallmentPreview {
                                    let details = InstallmentCalculator.calculateInstallmentDetails(
                                        principal: amountValue,
                                        annualRate: rate,
                                        periods: installmentPeriods
                                    )
                                    
                                    ForEach(details.prefix(3), id: \.period) { detail in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("第\(detail.period)期")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            HStack {
                                                Text("本金: \(String(format: "%.2f", detail.principalPayment))")
                                                    .font(.caption2)
                                                Text("利息: \(String(format: "%.2f", detail.interestPayment))")
                                                    .font(.caption2)
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                    
                                    if details.count > 3 {
                                        Text("... 共\(installmentPeriods)期")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("分期设置")
                    } footer: {
                        if enableInstallment {
                            Text("分期后将按月自动生成\(installmentPeriods)条账单记录")
                                .font(.caption)
                        }
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
    
    /// 获取货币转换汇率
    private func fetchConversionRate() {
        guard currency != defaultCurrency,
              let amountValue = Double(amount),
              amountValue > 0 else {
            conversionRate = nil
            return
        }
        
        Task {
            do {
                let rate = try await CurrencyExchangeService.shared.getExchangeRate(
                    from: currency,
                    to: defaultCurrency
                )
                await MainActor.run {
                    conversionRate = rate
                }
            } catch {
                // 获取汇率失败时静默处理
                await MainActor.run {
                    conversionRate = nil
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
        
        // 如果选择的货币不是默认货币，需要进行汇率转换
        if currency != defaultCurrency {
            isProcessing = true
            Task {
                do {
                    let rate = try await CurrencyExchangeService.shared.getExchangeRate(
                        from: currency,
                        to: defaultCurrency
                    )
                    let convertedAmount = amountValue * rate
                    
                    await MainActor.run {
                        isProcessing = false
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.success)
                        
                        // 判断是否为分期账单
                        if enableInstallment && transactionType == .expense && installmentPeriods > 0 {
                            // 创建分期账单（传入转换后的金额）
                            createInstallmentExpenses(
                                originalAmount: amountValue,
                                originalCurrency: currency,
                                convertedAmount: convertedAmount,
                                exchangeRate: rate,
                                periods: installmentPeriods,
                                annualRate: Double(installmentAnnualRate) ?? 0.0
                            )
                        } else {
                            // 创建普通账单
                            let expense = Expense(
                                transactionType: transactionType.rawValue,
                                date: date,
                                amount: convertedAmount,
                                currency: defaultCurrency,
                                originalAmount: amountValue,
                                originalCurrency: currency,
                                exchangeRate: rate,
                                mainCategory: mainCategory,
                                subCategory: subCategory,
                                merchant: merchant,
                                note: note,
                                originalText: recognizedText,
                                imageData: selectedImage?.jpegData(compressionQuality: 0.7)
                            )
                            
                            modelContext.insert(expense)
                        }
                        
                        // 保存数据库
                        try? modelContext.save()
                        
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        isProcessing = false
                        errorMessage = "汇率转换失败：\(error.localizedDescription)"
                    }
                }
            }
        } else {
            // 相同货币，不需要转换
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
            
            // 判断是否为分期账单
            if enableInstallment && transactionType == .expense && installmentPeriods > 0 {
                // 创建分期账单
                createInstallmentExpenses(
                    originalAmount: amountValue,
                    originalCurrency: currency,
                    convertedAmount: amountValue,
                    exchangeRate: 1.0,
                    periods: installmentPeriods,
                    annualRate: Double(installmentAnnualRate) ?? 0.0
                )
            } else {
                // 创建普通账单
                let expense = Expense(
                    transactionType: transactionType.rawValue,
                    date: date,
                    amount: amountValue,
                    currency: defaultCurrency,
                    originalAmount: amountValue,
                    originalCurrency: currency,
                    exchangeRate: 1.0,
                    mainCategory: mainCategory,
                    subCategory: subCategory,
                    merchant: merchant,
                    note: note,
                    originalText: recognizedText,
                    imageData: selectedImage?.jpegData(compressionQuality: 0.7)
                )
                
                modelContext.insert(expense)
            }
            
            // 保存数据库
            try? modelContext.save()
            
            dismiss()
        }
    }
    
    /// 创建分期账单
    private func createInstallmentExpenses(
        originalAmount: Double,
        originalCurrency: String,
        convertedAmount: Double,
        exchangeRate: Double,
        periods: Int,
        annualRate: Double
    ) {
        let parentId = UUID()
        
        // 使用转换后的金额计算每期还款
        let monthlyPayment = InstallmentCalculator.calculateMonthlyPayment(
            principal: convertedAmount,
            annualRate: annualRate,
            periods: periods
        )
        
        // 计算原始货币的每期还款金额（用于显示）
        let originalMonthlyPayment = InstallmentCalculator.calculateMonthlyPayment(
            principal: originalAmount,
            annualRate: annualRate,
            periods: periods
        )
        
        let calendar = Calendar.current
        
        for period in 1...periods {
            // 计算每期的日期
            let periodDate: Date
            if period == 1 {
                // 第一期使用原始日期
                periodDate = date
            } else {
                // 后续期数使用对应月份的第一天
                if let nextMonth = calendar.date(byAdding: .month, value: period - 1, to: date) {
                    let components = calendar.dateComponents([.year, .month], from: nextMonth)
                    periodDate = calendar.date(from: components) ?? nextMonth
                } else {
                    periodDate = date
                }
            }
            
            // 创建每期的账单
            let installmentNote = note.isEmpty ? "第\(period)/\(periods)期" : "\(note) - 第\(period)/\(periods)期"
            
            let expense = Expense(
                transactionType: transactionType.rawValue,
                date: periodDate,
                amount: monthlyPayment,
                currency: defaultCurrency,
                originalAmount: originalMonthlyPayment,
                originalCurrency: originalCurrency,
                exchangeRate: exchangeRate,
                mainCategory: mainCategory,
                subCategory: subCategory,
                merchant: merchant,
                note: installmentNote,
                originalText: recognizedText,
                imageData: period == 1 ? selectedImage?.jpegData(compressionQuality: 0.7) : nil,
                isInstallment: true,
                parentExpenseId: period == 1 ? nil : parentId,
                installmentPeriods: periods,
                installmentAnnualRate: annualRate,
                installmentNumber: period,
                totalInstallmentAmount: convertedAmount
            )
            
            // 第一期使用 parentId 作为其 id，后续期作为子账单
            if period == 1 {
                expense.id = parentId
            }
            
            modelContext.insert(expense)
        }
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

