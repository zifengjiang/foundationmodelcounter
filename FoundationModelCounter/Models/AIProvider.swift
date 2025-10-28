//
//  AIProvider.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import Foundation
import SwiftUI

// AI 提供商枚举
enum AIProvider: String, CaseIterable, Identifiable {
    case apple = "Apple 端侧 AI"
    case deepseek = "DeepSeek API"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .apple:
            return "apple.logo"
        case .deepseek:
            return "cloud.fill"
        }
    }
    
    var description: String {
        switch self {
        case .apple:
            return "使用设备端 AI，保护隐私，无需联网"
        case .deepseek:
            return "使用 DeepSeek API，需要联网和 API Key"
        }
    }
}

// AI 配置管理
@Observable
class AIConfiguration {
    static let shared = AIConfiguration()
    
    // 当前选择的 AI 提供商
    var currentProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(currentProvider.rawValue, forKey: "selectedAIProvider")
        }
    }
    
    // DeepSeek API Key
    var deepseekAPIKey: String {
        didSet {
            // 保存到 Keychain 会更安全，这里为了简化使用 UserDefaults
            UserDefaults.standard.set(deepseekAPIKey, forKey: "deepseekAPIKey")
        }
    }
    
    private init() {
        // 从 UserDefaults 读取配置
        if let providerRaw = UserDefaults.standard.string(forKey: "selectedAIProvider"),
           let provider = AIProvider(rawValue: providerRaw) {
            self.currentProvider = provider
        } else {
            self.currentProvider = .apple
        }
        
        self.deepseekAPIKey = UserDefaults.standard.string(forKey: "deepseekAPIKey") ?? ""
    }
    
    var isConfigured: Bool {
        switch currentProvider {
        case .apple:
            return true
        case .deepseek:
            return !deepseekAPIKey.isEmpty
        }
    }
}

