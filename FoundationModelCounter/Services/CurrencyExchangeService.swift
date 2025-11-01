//
//  CurrencyExchangeService.swift
//  FoundationModelCounter
//
//  Created by AI Assistant on 2025/11/01.
//

import Foundation

/// 货币代码枚举
enum CurrencyCode: String, CaseIterable, Codable {
    case CNY = "CNY"  // 人民币
    case USD = "USD"  // 美元
    case EUR = "EUR"  // 欧元
    case JPY = "JPY"  // 日元
    case GBP = "GBP"  // 英镑
    case HKD = "HKD"  // 港币
    case TWD = "TWD"  // 新台币
    case KRW = "KRW"  // 韩元
    case SGD = "SGD"  // 新加坡元
    case AUD = "AUD"  // 澳元
    case CAD = "CAD"  // 加元
    
    var symbol: String {
        switch self {
        case .CNY: return "¥"
        case .USD: return "$"
        case .EUR: return "€"
        case .JPY: return "¥"
        case .GBP: return "£"
        case .HKD: return "HK$"
        case .TWD: return "NT$"
        case .KRW: return "₩"
        case .SGD: return "S$"
        case .AUD: return "A$"
        case .CAD: return "C$"
        }
    }
    
    var name: String {
        switch self {
        case .CNY: return "人民币"
        case .USD: return "美元"
        case .EUR: return "欧元"
        case .JPY: return "日元"
        case .GBP: return "英镑"
        case .HKD: return "港币"
        case .TWD: return "新台币"
        case .KRW: return "韩元"
        case .SGD: return "新加坡元"
        case .AUD: return "澳元"
        case .CAD: return "加元"
        }
    }
}

/// 汇率服务
actor CurrencyExchangeService {
    static let shared = CurrencyExchangeService()
    
    private init() {}
    
    // 汇率缓存，键为"FROM_TO"格式，如"USD_CNY"
    private var exchangeRateCache: [String: (rate: Double, timestamp: Date)] = [:]
    
    // 缓存有效期（1小时）
    private let cacheValidDuration: TimeInterval = 3600
    
    /// 获取汇率（从fromCurrency到toCurrency）
    /// - Parameters:
    ///   - fromCurrency: 源货币
    ///   - toCurrency: 目标货币
    /// - Returns: 汇率值
    func getExchangeRate(from fromCurrency: String, to toCurrency: String) async throws -> Double {
        // 如果是相同货币，直接返回1
        if fromCurrency == toCurrency {
            return 1.0
        }
        
        let cacheKey = "\(fromCurrency)_\(toCurrency)"
        
        // 检查缓存
        if let cached = exchangeRateCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheValidDuration {
            return cached.rate
        }
        
        // 从API获取汇率
        do {
            let rate = try await fetchExchangeRateFromAPI(from: fromCurrency, to: toCurrency)
            // 更新缓存
            exchangeRateCache[cacheKey] = (rate, Date())
            return rate
        } catch {
            // 如果API失败，尝试使用过期的缓存
            if let cached = exchangeRateCache[cacheKey] {
                print("使用过期的汇率缓存: \(cacheKey)")
                return cached.rate
            }
            
            // 如果没有缓存，使用备用汇率
            return getFallbackRate(from: fromCurrency, to: toCurrency)
        }
    }
    
    /// 从API获取汇率
    private func fetchExchangeRateFromAPI(from fromCurrency: String, to toCurrency: String) async throws -> Double {
        // 使用ExchangeRate-API v6版本
        let apiKey = "1cc6d7d0ee8d44cf646b44ad"
        let urlString = "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/\(fromCurrency)"
        
        guard let url = URL(string: urlString) else {
            throw CurrencyError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CurrencyError.networkError
        }
        
        let result = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        
        guard result.result == "success",
              let rate = result.conversion_rates[toCurrency] else {
            throw CurrencyError.currencyNotFound
        }
        
        return rate
    }
    
    /// 转换金额
    /// - Parameters:
    ///   - amount: 金额
    ///   - fromCurrency: 源货币
    ///   - toCurrency: 目标货币
    /// - Returns: 转换后的金额
    func convert(amount: Double, from fromCurrency: String, to toCurrency: String) async throws -> Double {
        let rate = try await getExchangeRate(from: fromCurrency, to: toCurrency)
        return amount * rate
    }
    
    /// 获取备用汇率（离线使用）
    private func getFallbackRate(from fromCurrency: String, to toCurrency: String) -> Double {
        // 基于CNY的常用汇率（2025年大概值）
        let ratesToCNY: [String: Double] = [
            "USD": 7.20,
            "EUR": 7.85,
            "JPY": 0.048,
            "GBP": 9.10,
            "HKD": 0.92,
            "TWD": 0.23,
            "KRW": 0.0055,
            "SGD": 5.35,
            "AUD": 4.70,
            "CAD": 5.25,
            "CNY": 1.0
        ]
        
        guard let fromRate = ratesToCNY[fromCurrency],
              let toRate = ratesToCNY[toCurrency] else {
            return 1.0
        }
        
        // 通过CNY作为中间货币进行转换
        // 例如：USD -> CNY -> EUR
        // 1 USD = 7.20 CNY
        // 1 CNY = 1/7.85 EUR
        // 所以 1 USD = 7.20 * (1/7.85) EUR
        return fromRate / toRate
    }
    
    /// 清除缓存
    func clearCache() {
        exchangeRateCache.removeAll()
    }
}

/// 汇率API响应结构（v6版本）
private struct ExchangeRateResponse: Codable {
    let result: String
    let base_code: String
    let conversion_rates: [String: Double]
}

/// 货币错误
enum CurrencyError: LocalizedError {
    case invalidURL
    case networkError
    case currencyNotFound
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的汇率API地址"
        case .networkError:
            return "网络请求失败"
        case .currencyNotFound:
            return "找不到指定货币"
        case .conversionFailed:
            return "货币转换失败"
        }
    }
}

