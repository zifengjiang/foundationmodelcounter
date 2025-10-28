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
        你是一个专业的账单分析助手。请从图片/记录中提取财务信息，分类方式采用"实际用途分类"：
        
        \(existingCategories)
        
        分类规则：
        - 大类使用生活类目（如：服饰、餐饮、交通、居家、数码、医疗）
        - 小类为更具体的物品/用途（如：上衣、外卖、地铁、清洁用品、耳机 等）
        - 禁止使用"网购/消费/线上"这类支付渠道做大类
        - 优先从已有类目中选择匹配的分类
        - 如果已有类目无法准确描述，可以创建新的合适类目
        
        输出要求：
        - 提取金额、时间、商品用途简述
        - 只关注实际支付的产品
        - 图片中可能包含商品金额的广告信息，请忽略它们
        
        请以 JSON 格式返回，包含以下字段（如果无法提取则设为 null）：
        {
            "date": "日期格式 YYYY-MM-DD HH:mm:ss，使用账单上的本地时间，例如：2025-10-28 14:30:00",
            "amount": 数字类型的金额,
            "currency": "币种代码，如：CNY、USD、EUR、JPY、GBP、HKD",
            "mainCategory": "消费大类",
            "subCategory": "消费小类",
            "merchant": "商品/服务用途的简短描述",
            "note": "备注信息"
        }
        
        注意：
        - 日期不要使用 ISO8601 的 UTC 格式（不要带 Z 或时区信息）
        - 使用账单上显示的本地时间
        - 如果只有日期没有时间，时间部分使用 12:00:00
        
        只返回 JSON，不要有其他文字说明。
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

