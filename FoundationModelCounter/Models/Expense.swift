//
//  Expense.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var date: Date
    var amount: Double
    var currency: String
    var mainCategory: String
    var subCategory: String
    var merchant: String
    var note: String
    var originalText: String
    var imageData: Data?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        currency: String = "CNY",
        mainCategory: String,
        subCategory: String,
        merchant: String = "",
        note: String = "",
        originalText: String = "",
        imageData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.currency = currency
        self.mainCategory = mainCategory
        self.subCategory = subCategory
        self.merchant = merchant
        self.note = note
        self.originalText = originalText
        self.imageData = imageData
    }
}

// 账目分类
enum ExpenseCategory: String, CaseIterable {
    case food = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case housing = "住房"
    case healthcare = "医疗"
    case education = "教育"
    case other = "其他"
    
    var subCategories: [String] {
        switch self {
        case .food:
            return ["早餐", "午餐", "晚餐", "零食", "咖啡", "外卖"]
        case .transport:
            return ["打车", "公交", "地铁", "加油", "停车"]
        case .shopping:
            return ["服装", "日用品", "电子产品", "书籍", "化妆品"]
        case .entertainment:
            return ["电影", "游戏", "旅游", "运动", "订阅"]
        case .housing:
            return ["房租", "水费", "电费", "网费", "物业费"]
        case .healthcare:
            return ["药品", "挂号", "检查", "保险"]
        case .education:
            return ["学费", "培训", "书籍", "课程"]
        case .other:
            return ["其他"]
        }
    }
}

