//
//  AIExpenseAnalyzer.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import Foundation
import FoundationModels

// 使用 @Generable 标记的 struct 用于 AI 生成
@Generable
struct ExpenseInfo: Identifiable {
    var id: Int
    
    @Guide(description: "消费日期，ISO8601 格式，例如：2025-10-28T14:30:00Z")
    var date: String?
    
    @Guide(description: "消费金额，数字类型")
    var amount: Double?
    
    @Guide(description: "币种代码，如：CNY、USD、EUR、JPY、GBP、HKD")
    var currency: String?
    
    @Guide(description: "消费大类，从以下选择：餐饮、交通、购物、娱乐、住房、医疗、教育、其他")
    var mainCategory: String?
    
    @Guide(description: "消费小类，根据大类选择对应的小类")
    var subCategory: String?
    
    @Guide(description: "商户名称或店铺名称")
    var merchant: String?
    
    @Guide(description: "备注信息")
    var note: String?
}

class AIExpenseAnalyzer {
    static let shared = AIExpenseAnalyzer()
    
    private init() {}
    
    func analyzeExpense(from text: String) async throws -> ExpenseInfo {
        // 创建提示词说明
        let instructions = """
        你是一个专业的账单分析助手。请分析用户提供的账单文本，提取结构化的账目信息。
        
        消费大类和小类对应关系：
        - 餐饮：早餐、午餐、晚餐、零食、咖啡、外卖
        - 交通：打车、公交、地铁、加油、停车
        - 购物：服装、日用品、电子产品、书籍、化妆品
        - 娱乐：电影、游戏、旅游、运动、订阅
        - 住房：房租、水费、电费、网费、物业费
        - 医疗：药品、挂号、检查、保险
        - 教育：学费、培训、书籍、课程
        - 其他：其他支出
        
        如果某些信息无法从文本中提取，请将对应字段设置为 null。
        日期格式使用 ISO8601 标准（如：2025-10-28T14:30:00Z）。
        币种默认为 CNY。
        """
        
        // 创建 LanguageModelSession
        let session = LanguageModelSession(
            model: .default,
            instructions: instructions
        )
        
        // 构建用户提示词
        let userPrompt = """
        请分析以下账单文本并提取账目信息：
        
        \(text)
        """
        
        // 使用 streamResponse API 生成结构化输出
        var result: ExpenseInfo?
        
        result = try await session.respond(
            to: userPrompt,
            generating: ExpenseInfo.self
        ).content
        
        
        guard let expenseInfo = result else {
            throw AIAnalyzerError.noResultGenerated
        }
        
        return expenseInfo
    }
}

enum AIAnalyzerError: LocalizedError {
    case generationFailed(Error)
    case noResultGenerated
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let error):
            return "AI 生成失败：\(error.localizedDescription)"
        case .noResultGenerated:
            return "AI 未能生成有效的账目信息"
        }
    }
}

