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
    
    @State var viewModel: ExpenseDetailViewModel
    
    let currencies = ["CNY", "USD", "EUR", "JPY", "GBP", "HKD"]
    let quickAmounts = [10.0, 20.0, 50.0, 100.0, 200.0, 500.0]
    
    init(expense: Expense, viewModel: ExpenseDetailViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = State(initialValue: vm)
        } else {
            let vm = ExpenseDetailViewModel()
            vm.setup(with: expense)
            _viewModel = State(initialValue: vm)
        }
    }
    
    var body: some View {
        Form {
            // 账目信息
            Section {
                // 交易类型（只读）
                HStack {
                    Image(systemName: viewModel.transactionType == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(viewModel.transactionType == .expense ? .red : .green)
                    Text("类型")
                    Spacer()
                    Text(viewModel.transactionType.rawValue)
                        .foregroundStyle(.secondary)
                }
                
                DatePicker("日期", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("金额")
                        Spacer()
                        TextField("0.00", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                            .disabled(viewModel.expense?.isInstallment ?? false)
                            .foregroundStyle((viewModel.expense?.isInstallment ?? false) ? .secondary : .primary)
                        
                        Picker("", selection: $viewModel.currency) {
                            ForEach(currencies, id: \.self) { curr in
                                Text(curr).tag(curr)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                        .disabled(viewModel.expense?.isInstallment ?? false)
                    }
                    
                    // 货币转换信息
                    if let expense = viewModel.expense,
                       let originalCurrency = expense.originalCurrency,
                       let originalAmount = expense.originalAmount,
                       let exchangeRate = expense.exchangeRate,
                       originalCurrency != expense.currency {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("原始金额: \(String(format: "%.2f", originalAmount)) \(originalCurrency)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("汇率: 1 \(originalCurrency) = \(String(format: "%.4f", exchangeRate)) \(expense.currency)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // 快速金额选择（分期账单不显示）
                    if !(viewModel.expense?.isInstallment ?? false) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickAmounts, id: \.self) { quickAmount in
                                    Button(action: {
                                        viewModel.amount = String(format: "%.0f", quickAmount)
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
                    ForEach(viewModel.availableMainCategories, id: \.self) { category in
                        Button(category) {
                            viewModel.mainCategory = category
                            viewModel.updateSubCategories(context: modelContext)
                        }
                    }
                } label: {
                    HStack {
                        Text("大类")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.mainCategory)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // 小类选择 - 使用 Menu
                Menu {
                    ForEach(viewModel.availableSubCategories, id: \.self) { category in
                        Button(category) {
                            viewModel.subCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text("小类")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.subCategory)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                TextField(viewModel.transactionType == .expense ? "商户/商品" : "收入来源", text: $viewModel.merchant)
                
                TextField("备注", text: $viewModel.note, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("\(viewModel.transactionType.rawValue)信息")
            }
            
            // 分期信息/设置
            if let expense = viewModel.expense, expense.isInstallment {
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
                        viewModel.showInstallmentInfo.toggle()
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        HStack {
                            Text(viewModel.showInstallmentInfo ? "收起详情" : "查看详情")
                            Spacer()
                            Image(systemName: viewModel.showInstallmentInfo ? "chevron.up" : "chevron.down")
                        }
                        .foregroundStyle(.blue)
                    }
                    
                    if viewModel.showInstallmentInfo {
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
            } else if viewModel.transactionType == .expense {
                // 非分期账单且为支出类型，显示分期设置
                Section {
                    Toggle("启用分期", isOn: $viewModel.enableInstallment)
                        .onChange(of: viewModel.enableInstallment) { oldValue, newValue in
                            if newValue {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                        }
                    
                    if viewModel.enableInstallment {
                        Picker("分期期数", selection: $viewModel.installmentPeriods) {
                            ForEach([3, 6, 9, 12, 18, 24], id: \.self) { period in
                                Text("\(period)期").tag(period)
                            }
                        }
                        
                        HStack {
                            Text("年化利率")
                            Spacer()
                            TextField("0.00", text: $viewModel.installmentAnnualRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                            Text("%")
                                .foregroundStyle(.secondary)
                        }
                        
                        // 分期预览
                        if let amountValue = Double(viewModel.amount), amountValue > 0 {
                            let rate = Double(viewModel.installmentAnnualRate) ?? 0.0
                            let monthlyPayment = InstallmentCalculator.calculateMonthlyPayment(
                                principal: amountValue,
                                annualRate: rate,
                                periods: viewModel.installmentPeriods
                            )
                            let totalInterest = InstallmentCalculator.calculateTotalInterest(
                                principal: amountValue,
                                annualRate: rate,
                                periods: viewModel.installmentPeriods
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
                                viewModel.showInstallmentPreview.toggle()
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }) {
                                HStack {
                                    Text(viewModel.showInstallmentPreview ? "收起详情" : "查看详情")
                                    Spacer()
                                    Image(systemName: viewModel.showInstallmentPreview ? "chevron.up" : "chevron.down")
                                }
                                .foregroundStyle(.blue)
                            }
                            
                            if viewModel.showInstallmentPreview {
                                let details = InstallmentCalculator.calculateInstallmentDetails(
                                    principal: amountValue,
                                    annualRate: rate,
                                    periods: viewModel.installmentPeriods
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
                                    Text("... 共\(viewModel.installmentPeriods)期")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("分期设置")
                } footer: {
                    if viewModel.enableInstallment {
                        Text("启用分期后，当前账单将被替换为\(viewModel.installmentPeriods)条按月分期的账单")
                            .font(.caption)
                    }
                }
            }
            
            // 账单图片 - 折叠显示
            if let expense = viewModel.expense,
               let imageData = expense.imageData,
               let image = UIImage(data: imageData) {
                Section {
                    DisclosureGroup(isExpanded: $viewModel.showImage) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                            .padding(.top, 8)
                            .onTapGesture {
                                viewModel.showFullScreenImage = true
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
                    .sheet(isPresented: $viewModel.showFullScreenImage) {
                        FullScreenImageView(image: image)
                    }
                } header: {
                    Text("附件")
                }
            }
            
            // 识别的原始文本 - 折叠显示
            if let expense = viewModel.expense, !expense.originalText.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $viewModel.showOriginalText) {
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
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
        }
        .navigationTitle("账目详情")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.hasChanges)
        .toolbar {
            if viewModel.hasChanges {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        viewModel.showDiscardAlert = true
                    }
                }
            }
        }
        .alert("放弃更改", isPresented: $viewModel.showDiscardAlert) {
            Button("继续编辑", role: .cancel) { }
            Button("放弃", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("您有未保存的更改，确定要放弃吗？")
        }
        .alert("删除账目", isPresented: $viewModel.showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                viewModel.deleteExpense(context: modelContext, dismiss: dismiss)
            }
        } message: {
            if let expense = viewModel.expense {
                Text("确定要删除这条\(TransactionType(rawValue: expense.transactionType)?.rawValue ?? "")记录吗？此操作无法撤销。")
            }
        }
        .confirmationDialog("删除分期账单", isPresented: $viewModel.showInstallmentDeleteOptions, titleVisibility: .visible) {
            Button("仅删除当前这一期", role: .destructive) {
                viewModel.deleteCurrentInstallment(context: modelContext, dismiss: dismiss)
            }
            
            Button("删除全部分期", role: .destructive) {
                viewModel.deleteAllInstallments(context: modelContext, dismiss: dismiss)
            }
            
            // 只有当前不是最后一期时，才显示提前还清选项
            if let expense = viewModel.expense, expense.installmentNumber < expense.installmentPeriods {
                Button("提前还清（删除未来期数）", role: .destructive) {
                    viewModel.earlyPayoff(context: modelContext, dismiss: dismiss)
                }
            }
            
            Button("取消", role: .cancel) { }
        } message: {
            if let expense = viewModel.expense {
                Text("这是第\(expense.installmentNumber)/\(expense.installmentPeriods)期分期账单，请选择删除方式")
            }
        }
        .onAppear {
            viewModel.loadCategories(context: modelContext)
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

