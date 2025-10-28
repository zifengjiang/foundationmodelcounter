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
    
    func analyzeExpense(from text: String, expenseCategories: String, incomeCategories: String, preferredType: TransactionType? = nil, apiKey: String) async throws -> String {
        let systemMessage = """
        你是一个专业的财务分析助手。请从账单或收入凭证文本中提取财务信息。

        ## 交易类型判断

        首先判断这是**支出**还是**收入**：
        - 支出：购买商品、服务消费、转账支付等花钱的行为
        - 收入：工资到账、转账收款、退款、分红、利息等收钱的行为

        ## 支出分类体系（衣食住行）

        \(expenseCategories)

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

        ## 收入分类体系

        \(incomeCategories)

        **职薪** - 工作相关收入：
        - 工资薪金：基本工资、奖金、津贴
        - 兼职收入：兼职、外包、咨询
        - 绩效奖励：年终奖、项目奖金、提成
        - 福利补贴：餐补、交通补贴、通讯补贴

        **理财** - 投资理财收益：
        - 投资收益：股票、基金、债券收益
        - 利息收入：存款利息、债券利息
        - 分红收益：股票分红、基金分红
        - 租金收入：房租、车位租赁

        **经营** - 生意经营收入：
        - 销售收入：商品销售、服务收入
        - 佣金收入：中介佣金、代理费
        - 版权收入：版税、专利授权
        - 广告收入：自媒体、内容创作

        **其他** - 其他收入来源：
        - 礼金红包：节日红包、生日礼金
        - 退款返现：商品退款、信用卡返现
        - 中奖收入：彩票、抽奖、奖品
        - 其他收入：未分类的其他收入

        ## 分类规则

        1. transactionType 必须是：支出 或 收入
        2. 支出大类必须是：衣、食、住、行 之一
        3. 收入大类必须是：职薪、理财、经营、其他 之一
        4. 小类优先从上述已有类目中选择
        5. 根据交易的**实际用途**来分类，不要根据支付渠道分类
        6. 商户字段填写具体的商品/服务/收入来源描述

        ## 输出格式

        请以 JSON 格式返回（如果某字段无法提取则设为 null）：
        {
            "transactionType": "支出 或 收入",
            "date": "YYYY-MM-DD HH:mm:ss（本地时间，不要UTC）",
            "amount": 数字类型的金额（正数）,
            "currency": "币种代码（CNY/USD/EUR/JPY/GBP/HKD）",
            "mainCategory": "根据类型选择对应的大类",
            "subCategory": "对应的小类",
            "merchant": "商品/服务/收入来源的简短描述",
            "note": "备注信息"
        }

        注意事项：
        - 只返回 JSON，不要有其他文字
        - 日期只有日期没时间时，使用 12:00:00
        - 币种默认为 CNY
        - 金额始终为正数
        - 忽略广告信息，只关注实际的交易信息
        """
        
        var userMessage = "请分析以下文本并提取财务信息"
        if let type = preferredType {
            userMessage += "（这是一条\(type.rawValue)记录）"
        }
        userMessage += "：\n\n\(text)"
        
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

