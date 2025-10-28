//
//  QuickExpenseIntent.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import AppIntents
import SwiftUI
import SwiftData
import UIKit

/// 图片记账快捷指令 - 接收截屏图片作为输入
/// 配合快捷指令中的"截取屏幕"动作使用，实现一键截屏记账
struct QuickExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "图片记账"
    static var description = IntentDescription("从图片自动分析记账")
    
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "账单图片")
    var image: IntentFile
    
    @Parameter(title: "交易类型", default: "支出")
    var transactionType: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("分析\(\.$image)并记录\(\.$transactionType)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 步骤1: 获取图片
        guard let uiImage = UIImage(data: image.data) else {
            throw QuickExpenseError.invalidImage
        }
        
        // 步骤2: OCR识别文字
        let recognizedText = try await OCRService.shared.recognizeText(from: uiImage, isScreenShot: true)
        
        // 步骤3: 获取ModelContext
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        // 初始化类目
        CategoryService.shared.initializeDefaultCategories(context: context)
        
        // 步骤4: AI分析账单信息
        let preferredType: TransactionType = transactionType == "收入" ? .income : .expense
        let expenseInfo = try await AIExpenseAnalyzer.shared.analyzeExpense(
            from: recognizedText,
            context: context,
            preferredType: preferredType
        )
        
        // 步骤5: 创建账目记录
        guard let amount = expenseInfo.amount, amount > 0 else {
            throw QuickExpenseError.invalidAmount
        }
        
        let finalTransactionType = expenseInfo.transactionType ?? preferredType.rawValue
        let date = parseDate(from: expenseInfo.date) ?? Date()
        let currency = expenseInfo.currency ?? "CNY"
        let mainCategory = expenseInfo.mainCategory ?? "其他"
        let subCategory = expenseInfo.subCategory ?? "其他"
        let merchant = expenseInfo.merchant ?? ""
        let note = expenseInfo.note ?? ""
        
        // 步骤6: 检查重复记账（基于时间和金额）
        if try checkDuplicateExpense(
            amount: amount,
            date: date,
            transactionType: finalTransactionType,
            context: context
        ) {
            // 发现重复记账，返回提示而不是报错
            let duplicateMessage = """
            ⚠️ 检测到可能的重复记账
            
            金额: \(currency) \(String(format: "%.2f", amount))
            时间: \(formatDate(date))
            
            已跳过保存，避免重复。
            如需强制添加，请在 App 中手动添加。
            """
            return .result(dialog: IntentDialog(stringLiteral: duplicateMessage))
        }
        
        // 更新或添加类目
        let transType = TransactionType(rawValue: finalTransactionType) ?? preferredType
        _ = CategoryService.shared.addOrUpdateCategory(
            transactionType: transType,
            mainCategory: mainCategory,
            subCategory: subCategory,
            context: context
        )
        
        // 保存账目
        let expense = Expense(
            transactionType: finalTransactionType,
            date: date,
            amount: amount,
            currency: currency,
            mainCategory: mainCategory,
            subCategory: subCategory,
            merchant: merchant,
            note: note,
            originalText: recognizedText,
            imageData: uiImage.jpegData(compressionQuality: 0.7)
        )
        
        context.insert(expense)
        try context.save()
        
        // 返回结果
        let resultMessage = """
        ✅ 记账成功！
        
        类型: \(finalTransactionType)
        金额: \(currency) \(String(format: "%.2f", amount))
        类别: \(mainCategory) - \(subCategory)
        \(merchant.isEmpty ? "" : "商户: \(merchant)")
        日期: \(formatDate(date))
        """
        
        return .result(dialog: IntentDialog(stringLiteral: resultMessage))
    }
    
    // MARK: - Helper Methods
    
    private func getModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Expense.self,
            Category.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            throw QuickExpenseError.databaseError
        }
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let trimmed = dateString.trimmingCharacters(in: .whitespaces)
        
        // 尝试格式1: YYYY-MM-DD HH:mm:ss
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter1.locale = Locale(identifier: "en_US_POSIX")
        formatter1.timeZone = TimeZone.current
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
        
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    /// 检查是否存在重复记账
    /// 判断标准：相同金额 + 时间接近（±2分钟内）+ 相同交易类型
    /// - Returns: true表示发现重复，false表示无重复
    private func checkDuplicateExpense(
        amount: Double,
        date: Date,
        transactionType: String,
        context: ModelContext
    ) throws -> Bool {
        // 定义时间窗口：前后2分钟
        let timeWindow: TimeInterval = 2 * 60  // 2分钟
        let startDate = date.addingTimeInterval(-timeWindow)
        let endDate = date.addingTimeInterval(timeWindow)
        
        // 定义金额误差范围：±0.01
        let amountTolerance = 0.01
        let minAmount = amount - amountTolerance
        let maxAmount = amount + amountTolerance
        
        // 查询相同交易类型、金额接近、时间接近的记录
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                expense.transactionType == transactionType &&
                expense.amount >= minAmount &&
                expense.amount <= maxAmount &&
                expense.date >= startDate &&
                expense.date <= endDate
            }
        )
        
        let existingExpenses = try context.fetch(descriptor)
        
        // 如果找到任何匹配的记录，认为是重复
        return !existingExpenses.isEmpty
    }
}

// MARK: - Error Types

enum QuickExpenseError: LocalizedError {
    case invalidImage
    case invalidAmount
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .invalidAmount:
            return "无法识别有效的金额"
        case .databaseError:
            return "数据库错误"
        }
    }
}

// MARK: - App Shortcuts Provider

/// 快捷指令提供者
/// 提供"图片记账"快捷指令，配合"截取屏幕"动作使用
struct QuickExpenseShortcuts: AppShortcutsProvider {
    
    static var shortcutTileColor: ShortcutTileColor { .orange }
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickExpenseIntent(),
            phrases: [
                "\(.applicationName)图片记账",
                "\(.applicationName)分析账单",
                "\(.applicationName) 记账"
            ],
            shortTitle: "图片记账",
            systemImageName: "photo.on.rectangle.angled"
        )
    }
}
