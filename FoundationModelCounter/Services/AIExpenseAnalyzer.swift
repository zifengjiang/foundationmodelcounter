//
//  AIExpenseAnalyzer.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import Foundation
import FoundationModels
import SwiftData

// 使用 @Generable 标记的 struct 用于 AI 生成
@Generable
struct ExpenseInfo: Identifiable {
    var id: Int
    
    @Guide(description: "消费日期，格式：YYYY-MM-DD HH:mm:ss，使用账单上显示的本地时间，例如：2025-10-28 14:30:00")
    var date: String?
    
    @Guide(description: "消费金额，数字类型")
    var amount: Double?
    
    @Guide(description: "币种代码，如：CNY、USD、EUR、JPY、GBP、HKD")
    var currency: String?
    
    @Guide(description: "消费大类，优先从已有类目中选择，如需要可创建新类目")
    var mainCategory: String?
    
    @Guide(description: "消费小类，优先从已有类目中选择，如需要可创建新类目")
    var subCategory: String?
    
    @Guide(description: "商品/服务用途的简短描述")
    var merchant: String?
    
    @Guide(description: "备注信息")
    var note: String?
}

class AIExpenseAnalyzer {
    static let shared = AIExpenseAnalyzer()
    
    private init() {}
    
    func analyzeExpense(from text: String, context: ModelContext) async throws -> ExpenseInfo {
        let config = AIConfiguration.shared
        
        switch config.currentProvider {
        case .apple:
            return try await analyzeWithAppleAI(text: text, context: context)
        case .deepseek:
            return try await analyzeWithDeepSeek(text: text, context: context)
        }
    }
    
    // 使用 Apple 端侧 AI 分析
    private func analyzeWithAppleAI(text: String, context: ModelContext) async throws -> ExpenseInfo {
        // 获取已有类目
        let existingCategories = CategoryService.shared.formatCategoriesForPrompt(context: context)
        
        // 创建提示词说明
        let instructions = """
        你是一个专业的账单分析助手。请从账单文本中提取财务信息。

        ## 分类体系（衣食住行）

        \(existingCategories)

        ## 分类说明

        **衣** - 外在与形象相关：
        - 日常穿着：衣服、鞋袜、内衣等
        - 形象提升：理发、美发、美甲、美容、护肤、化妆
        - 社交形象：配饰、饰品、特殊场合穿搭

        **食** - 吃喝与健康摄入：
        - 日常饮食：买菜、做饭、基础饮品
        - 外食餐饮：餐厅、外卖、咖啡、奶茶
        - 社交应酬：聚会、请客、小酒局
        - 营养补充：蛋白粉、维生素、保健品

        **住** - 生活稳定成本：
        - 居住成本：房租、水电、物业、宽带
        - 日常生活：清洁用品、家用品、厨具、学习办公用品
        - 医疗健康：看病、药品、护理
        - 长期保障：保险、会员订阅
        - 情感家庭：人情往来、礼金礼品

        **行** - 移动 + 体验：
        - 城市出行：公交、地铁、打车、共享出行
        - 运动健身：游泳、篮球、健身卡等
        - 休闲娱乐：电影、音乐会、展览、桌游
        - 旅行度假：机票、酒店、旅途中开销
        - 数码提升：手机、电脑、生产力设备

        ## 分类规则

        1. 大类必须是：衣、食、住、行 之一
        2. 小类优先从上述已有类目中选择
        3. 根据消费的**实际用途**来分类，不要根据支付渠道（如"网购"）分类
        4. 如果账单内容与某个小类高度相关，直接使用该小类
        5. 商户字段填写具体的商品或服务描述

        ## 输出要求

        - 提取金额、时间、商品用途简述
        - 只关注实际支付的产品
        - 忽略广告信息
        - 如果某些信息无法提取，设置为 null
        - 日期格式：YYYY-MM-DD HH:mm:ss（本地时间，不要UTC）
        - 日期只有日期没时间时，使用 12:00:00
        - 币种默认为 CNY
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
    
    // 使用 DeepSeek API 分析
    private func analyzeWithDeepSeek(text: String, context: ModelContext) async throws -> ExpenseInfo {
        let config = AIConfiguration.shared
        
        guard !config.deepseekAPIKey.isEmpty else {
            throw AIAnalyzerError.apiKeyNotConfigured
        }
        
        // 获取已有类目
        let existingCategories = CategoryService.shared.formatCategoriesForPrompt(context: context)
        
        let jsonString = try await DeepSeekService.shared.analyzeExpense(
            from: text,
            existingCategories: existingCategories,
            apiKey: config.deepseekAPIKey
        )
        
        // 解析 JSON 响应
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIAnalyzerError.invalidJSONResponse
        }
        
        // 提取 JSON 部分（处理可能包含的其他文字）
        let cleanedJSON = extractJSON(from: jsonString)
        guard let cleanedData = cleanedJSON.data(using: .utf8) else {
            throw AIAnalyzerError.invalidJSONResponse
        }
        
        // 定义解码结构
        struct DeepSeekExpenseResult: Codable {
            var date: String?
            var amount: Double?
            var currency: String?
            var mainCategory: String?
            var subCategory: String?
            var merchant: String?
            var note: String?
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(DeepSeekExpenseResult.self, from: cleanedData)
        
        // 转换为 ExpenseInfo
        return ExpenseInfo(
            id: 0,
            date: result.date,
            amount: result.amount,
            currency: result.currency,
            mainCategory: result.mainCategory,
            subCategory: result.subCategory,
            merchant: result.merchant,
            note: result.note
        )
    }
    
    // 从响应中提取 JSON
    private func extractJSON(from text: String) -> String {
        // 如果包含 ```json ... ``` 格式
        if let startRange = text.range(of: "```json"),
           let endRange = text.range(of: "```", range: startRange.upperBound..<text.endIndex) {
            let jsonPart = text[startRange.upperBound..<endRange.lowerBound]
            return String(jsonPart).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 如果包含 { ... } 格式
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AIAnalyzerError: LocalizedError {
    case generationFailed(Error)
    case noResultGenerated
    case apiKeyNotConfigured
    case invalidJSONResponse
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let error):
            return "AI 生成失败：\(error.localizedDescription)"
        case .noResultGenerated:
            return "AI 未能生成有效的账目信息"
        case .apiKeyNotConfigured:
            return "DeepSeek API Key 未配置，请在设置中配置"
        case .invalidJSONResponse:
            return "无法解析 API 返回的数据"
        }
    }
}

