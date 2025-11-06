//
//  ExpenseDetailViewModel.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/11/06.
//

import SwiftUI
import SwiftData

@Observable
class ExpenseDetailViewModel {
    var expense: Expense?
    
    // 编辑相关的状态
    var transactionType: TransactionType = .expense
    var date: Date = Date()
    var amount: String = ""
    var currency: String = "CNY"
    var mainCategory: String = ""
    var subCategory: String = ""
    var merchant: String = ""
    var note: String = ""
    
    var availableMainCategories: [String] = []
    var availableSubCategories: [String] = []
    
    // UI状态
    var showDeleteAlert = false
    var showInstallmentDeleteOptions = false
    var showFullScreenImage = false
    var showImage = false
    var showOriginalText = false
    var showDiscardAlert = false
    var showInstallmentInfo = false
    var errorMessage: String?
    
    // 分期设置状态
    var enableInstallment = false
    var installmentPeriods = 3
    var installmentAnnualRate = ""
    var showInstallmentPreview = false
    
    // 检查是否有更改
    var hasChanges: Bool {
        guard let expense = expense else { return false }
        
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
    
    // 初始化
    func setup(with expense: Expense) {
        self.expense = expense
        self.transactionType = TransactionType(rawValue: expense.transactionType) ?? .expense
        self.date = expense.date
        self.amount = String(format: "%.2f", expense.amount)
        self.currency = expense.currency
        self.mainCategory = expense.mainCategory
        self.subCategory = expense.subCategory
        self.merchant = expense.merchant
        self.note = expense.note
    }
    
    // 加载分类
    func loadCategories(context: ModelContext) {
        CategoryService.shared.initializeDefaultCategories(context: context)
        availableMainCategories = CategoryService.shared.getMainCategories(
            context: context,
            transactionType: transactionType
        )
        updateSubCategories(context: context)
    }
    
    // 更新子分类
    func updateSubCategories(context: ModelContext) {
        availableSubCategories = CategoryService.shared.getSubCategories(
            for: mainCategory,
            context: context,
            transactionType: transactionType
        )
    }
    
    // 保存账目
    func saveExpense(context: ModelContext, dismiss: DismissAction) {
        guard let expense = expense else { return }
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
                context: context
            )
        }
        
        // 判断是否要将普通账单转换为分期账单
        if enableInstallment && !expense.isInstallment && transactionType == .expense && installmentPeriods > 0 {
            // 删除原账单
            context.delete(expense)
            
            // 创建分期账单
            createInstallmentExpenses(
                totalAmount: amountValue,
                periods: installmentPeriods,
                annualRate: Double(installmentAnnualRate) ?? 0.0,
                context: context
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
        try? context.save()
        
        // 关闭页面
        dismiss()
    }
    
    // 创建分期账单
    private func createInstallmentExpenses(totalAmount: Double, periods: Int, annualRate: Double, context: ModelContext) {
        guard let expense = expense else { return }
        
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
            
            context.insert(newExpense)
        }
    }
    
    // 删除账目
    func deleteExpense(context: ModelContext, dismiss: DismissAction) {
        guard let expense = expense else { return }
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        context.delete(expense)
        try? context.save()
        dismiss()
    }
    
    // MARK: - 分期删除方法
    
    // 仅删除当前这一期
    func deleteCurrentInstallment(context: ModelContext, dismiss: DismissAction) {
        guard let expense = expense else { return }
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        context.delete(expense)
        try? context.save()
        dismiss()
    }
    
    // 删除全部分期
    func deleteAllInstallments(context: ModelContext, dismiss: DismissAction) {
        guard let expense = expense else { return }
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        // 获取所有相关的分期账单
        let relatedExpenses = getAllRelatedInstallments(context: context)
        
        // 删除所有相关账单
        for relatedExpense in relatedExpenses {
            context.delete(relatedExpense)
        }
        
        try? context.save()
        dismiss()
    }
    
    // 提前还清（删除未来期数，将剩余金额合并到当前期）
    func earlyPayoff(context: ModelContext, dismiss: DismissAction) {
        guard let expense = expense else { return }
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        // 获取所有相关的分期账单
        let relatedExpenses = getAllRelatedInstallments(context: context)
        
        // 筛选出未来的期数（大于当前期数的）
        let futureInstallments = relatedExpenses.filter { $0.installmentNumber > expense.installmentNumber }
        
        // 计算未来期数的总金额
        let futureAmount = futureInstallments.reduce(0.0) { $0 + $1.amount }
        
        // 将当前期的金额增加未来期数的金额
        expense.amount += futureAmount
        expense.note = expense.note.replacingOccurrences(of: "第\(expense.installmentNumber)/\(expense.installmentPeriods)期", with: "已提前还清")
        
        // 删除所有未来期数
        for futureExpense in futureInstallments {
            context.delete(futureExpense)
        }
        
        try? context.save()
        dismiss()
    }
    
    // 获取所有相关的分期账单
    func getAllRelatedInstallments(context: ModelContext) -> [Expense] {
        guard let expense = expense else { return [] }
        
        let descriptor = FetchDescriptor<Expense>()
        let allExpenses = (try? context.fetch(descriptor)) ?? []
        
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

