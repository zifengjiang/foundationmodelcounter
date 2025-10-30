//
//  ThemeManager.swift
//  FoundationModelCounter
//
//  Created on 2025/10/30.
//

import SwiftUI

// MARK: - 主题枚举

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色模式"
        case .dark:
            return "深色模式"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - 主题管理器

@Observable
class ThemeManager {
    static let shared = ThemeManager()
    
    private let themeKey = "appTheme"
    
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        }
    }
    
    private init() {
        if let themeString = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeString) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }
    
    // 获取当前应用的 ColorScheme
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}

