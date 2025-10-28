//
//  DeepSeekService.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import Foundation

// DeepSeek API 响应结构
struct DeepSeekResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// DeepSeek 请求结构
struct DeepSeekRequest: Codable {
    let model: String
    let messages: [Message]
    let stream: Bool
    let temperature: Double?
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

class DeepSeekService {
    static let shared = DeepSeekService()
    
    private let baseURL = "https://api.deepseek.com/chat/completions"
    
    private init() {}
    
    func chat(messages: [(role: String, content: String)], apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw DeepSeekError.missingAPIKey
        }
        
        // 构建请求
        guard let url = URL(string: baseURL) else {
            throw DeepSeekError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = DeepSeekRequest(
            model: "deepseek-chat",
            messages: messages.map { DeepSeekRequest.Message(role: $0.role, content: $0.content) },
            stream: false,
            temperature: 0.7
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // 尝试解析错误信息
            if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorMessage["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw DeepSeekError.apiError(message)
            }
            throw DeepSeekError.httpError(httpResponse.statusCode)
        }
        
        // 解析响应
        let decoder = JSONDecoder()
        let deepSeekResponse = try decoder.decode(DeepSeekResponse.self, from: data)
        
        guard let firstChoice = deepSeekResponse.choices.first else {
            throw DeepSeekError.noResponse
        }
        
        return firstChoice.message.content
    }
    
    func analyzeExpense(from text: String, existingCategories: String, apiKey: String) async throws -> String {
        let systemMessage = """
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

        ## 输出格式

        请以 JSON 格式返回（如果某字段无法提取则设为 null）：
        {
            "date": "YYYY-MM-DD HH:mm:ss（本地时间，不要UTC）",
            "amount": 数字类型的金额,
            "currency": "币种代码（CNY/USD/EUR/JPY/GBP/HKD）",
            "mainCategory": "衣/食/住/行",
            "subCategory": "对应的小类",
            "merchant": "商品/服务的简短描述",
            "note": "备注信息"
        }

        注意事项：
        - 只返回 JSON，不要有其他文字
        - 日期只有日期没时间时，使用 12:00:00
        - 币种默认为 CNY
        - 忽略广告信息，只关注实际支付的产品
        """
        
        let userMessage = """
        请分析以下账单文本并提取账目信息：
        
        \(text)
        """
        
        let response = try await chat(
            messages: [
                (role: "system", content: systemMessage),
                (role: "user", content: userMessage)
            ],
            apiKey: apiKey
        )
        
        return response
    }
}

enum DeepSeekError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noResponse
    case jsonParseError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "DeepSeek API Key 未配置"
        case .invalidURL:
            return "无效的 API 地址"
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let code):
            return "HTTP 错误：\(code)"
        case .apiError(let message):
            return "API 错误：\(message)"
        case .noResponse:
            return "服务器未返回有效响应"
        case .jsonParseError:
            return "JSON 解析失败"
        }
    }
}

