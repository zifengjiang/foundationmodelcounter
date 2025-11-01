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
    @State private var showInstallmentDeleteOptions = false
    @State private var showFullScreenImage = false
    @State private var showImage = false
    @State private var showOriginalText = false
    @State private var showDiscardAlert = false
    @State private var showInstallmentInfo = false
    @State private var errorMessage: String?
    
    // 分期设置状态
    @State private var enableInstallment = false
    @State private var installmentPeriods = 3
    @State private var installmentAnnualRate = ""
    @State private var showInstallmentPreview = false
    
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
        
        // 基本字段的更改检测
        let basicChanges = transactionType != originalTransactionType ||
                          date != expense.date ||
                          abs(amountValue - expense.amount) > 0.01 ||
                          currency != expense.currency ||
                          mainCategory != expense.mainCategory ||
                          subCategory != expense.subCategory ||
                          merchant != expense.merchant ||
                          note != expense.note
        
        // 分期设置的更改检测（如果启用了分期，视为有更改）
        let installmentChanges = enableInstallment && !expense.isInstallment
        
        return basicChanges || installmentChanges
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
                            .disabled(expense.isInstallment)
                            .foregroundStyle(expense.isInstallment ? .secondary : .primary)
                        
                        Picker("", selection: $currency) {
                            ForEach(currencies, id: \.self) { curr in
                                Text(curr).tag(curr)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                        .disabled(expense.isInstallment)
                    }
                    
                    // 快速金额选择（分期账单不显示）
                    if !expense.isInstallment {
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
            
            // 分期信息/设置
            if expense.isInstallment {
                // 已经是分期账单，显示信息（只读）
                Section {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundStyle(.blue)
                        Text("分期账单")
                            .font(.headline)
                        Spacer()
                        Text("第\(expense.installmentNumber)/\(expense.installmentPeriods)期")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(action: {
                        showInstallmentInfo.toggle()
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        HStack {
                            Text(showInstallmentInfo ? "收起详情" : "查看详情")
                            Spacer()
                            Image(systemName: showInstallmentInfo ? "chevron.up" : "chevron.down")
                        }
                        .foregroundStyle(.blue)
                    }
                    
                    if showInstallmentInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("原始金额")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", expense.totalInstallmentAmount))
                            }
                            
                            HStack {
                                Text("分期期数")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(expense.installmentPeriods)期")
                            }
                            
                            HStack {
                                Text("年化利率")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f%%", expense.installmentAnnualRate))
                            }
                            
                            HStack {
                                Text("每期还款")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", expense.amount))
                                    .font(.headline)
                            }
                            
                            let totalInterest = InstallmentCalculator.calculateTotalInterest(
                                principal: expense.totalInstallmentAmount,
                                annualRate: expense.installmentAnnualRate,
                                periods: expense.installmentPeriods
                            )
                            
                            HStack {
                                Text("总利息")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", totalInterest))
                                    .foregroundStyle(.red)
                            }
                            
                            HStack {
                                Text("还款总额")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", expense.totalInstallmentAmount + totalInterest))
                                    .font(.headline)
                            }
                        }
                    }
                } header: {
                    Text("分期信息")
                } footer: {
                    Text("分期账单的金额和分期信息不可编辑")
                        .font(.caption)
                }
            } else if transactionType == .expense {
                // 非分期账单且为支出类型，显示分期设置
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
                        Text("启用分期后，当前账单将被替换为\(installmentPeriods)条按月分期的账单")
                            .font(.caption)
                    }
                }
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
                Button(role: .destructive, action: {
                    // 如果是分期账单，显示分期删除选项
                    if expense.isInstallment {
                        showInstallmentDeleteOptions = true
                    } else {
                        showDeleteAlert = true
                    }
                }) {
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
        .confirmationDialog("删除分期账单", isPresented: $showInstallmentDeleteOptions, titleVisibility: .visible) {
            Button("仅删除当前这一期", role: .destructive) {
                deleteCurrentInstallment()
            }
            
            Button("删除全部分期", role: .destructive) {
                deleteAllInstallments()
            }
            
            // 只有当前不是最后一期时，才显示提前还清选项
            if expense.installmentNumber < expense.installmentPeriods {
                Button("提前还清（删除未来期数）", role: .destructive) {
                    earlyPayoff()
                }
            }
            
            Button("取消", role: .cancel) { }
        } message: {
            Text("这是第\(expense.installmentNumber)/\(expense.installmentPeriods)期分期账单，请选择删除方式")
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
        
        // 判断是否要将普通账单转换为分期账单
        if enableInstallment && !expense.isInstallment && transactionType == .expense && installmentPeriods > 0 {
            // 删除原账单
            modelContext.delete(expense)
            
            // 创建分期账单
            createInstallmentExpenses(
                totalAmount: amountValue,
                periods: installmentPeriods,
                annualRate: Double(installmentAnnualRate) ?? 0.0
            )
        } else {
            // 更新账目信息
            expense.transactionType = transactionType.rawValue
            expense.date = date
            
            // 分期账单不允许修改金额
            if !expense.isInstallment {
                expense.amount = amountValue
            }
            
            expense.currency = currency
            expense.mainCategory = mainCategory
            expense.subCategory = subCategory
            expense.merchant = merchant
            expense.note = note
        }
        
        // 保存到数据库
        try? modelContext.save()
        
        // 关闭页面
        dismiss()
    }
    
    /// 创建分期账单
    private func createInstallmentExpenses(totalAmount: Double, periods: Int, annualRate: Double) {
        let parentId = UUID()
        let monthlyPayment = InstallmentCalculator.calculateMonthlyPayment(
            principal: totalAmount,
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
            
            let newExpense = Expense(
                transactionType: transactionType.rawValue,
                date: periodDate,
                amount: monthlyPayment,
                currency: currency,
                mainCategory: mainCategory,
                subCategory: subCategory,
                merchant: merchant,
                note: installmentNote,
                originalText: expense.originalText,
                imageData: period == 1 ? expense.imageData : nil,
                isInstallment: true,
                parentExpenseId: period == 1 ? nil : parentId,
                installmentPeriods: periods,
                installmentAnnualRate: annualRate,
                installmentNumber: period,
                totalInstallmentAmount: totalAmount
            )
            
            // 第一期使用 parentId 作为其 id，后续期作为子账单
            if period == 1 {
                newExpense.id = parentId
            }
            
            modelContext.insert(newExpense)
        }
    }
    
    private func deleteExpense() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        modelContext.delete(expense)
        try? modelContext.save()
        dismiss()
    }
    
    // MARK: - 分期删除方法
    
    /// 仅删除当前这一期
    private func deleteCurrentInstallment() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        modelContext.delete(expense)
        try? modelContext.save()
        dismiss()
    }
    
    /// 删除全部分期
    private func deleteAllInstallments() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        // 获取所有相关的分期账单
        let relatedExpenses = getAllRelatedInstallments()
        
        // 删除所有相关账单
        for relatedExpense in relatedExpenses {
            modelContext.delete(relatedExpense)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    /// 提前还清（删除未来期数，将剩余金额合并到当前期）
    private func earlyPayoff() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        // 获取所有相关的分期账单
        let relatedExpenses = getAllRelatedInstallments()
        
        // 筛选出未来的期数（大于当前期数的）
        let futureInstallments = relatedExpenses.filter { $0.installmentNumber > expense.installmentNumber }
        
        // 计算未来期数的总金额
        let futureAmount = futureInstallments.reduce(0.0) { $0 + $1.amount }
        
        // 将当前期的金额增加未来期数的金额
        expense.amount += futureAmount
        expense.note = expense.note.replacingOccurrences(of: "第\(expense.installmentNumber)/\(expense.installmentPeriods)期", with: "已提前还清")
        
        // 删除所有未来期数
        for futureExpense in futureInstallments {
            modelContext.delete(futureExpense)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    /// 获取所有相关的分期账单
    private func getAllRelatedInstallments() -> [Expense] {
        let descriptor = FetchDescriptor<Expense>()
        let allExpenses = (try? modelContext.fetch(descriptor)) ?? []
        
        // 如果是第一期（父账单）
        if expense.parentExpenseId == nil && expense.installmentNumber == 1 {
            // 查找所有子账单
            return allExpenses.filter { $0.parentExpenseId == expense.id || $0.id == expense.id }
        } else {
            // 如果是子账单，通过 parentExpenseId 查找所有相关账单
            if let parentId = expense.parentExpenseId {
                return allExpenses.filter { $0.parentExpenseId == parentId || $0.id == parentId }
            }
        }
        
        return [expense]
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

