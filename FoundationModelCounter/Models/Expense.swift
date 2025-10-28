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
    var transactionType: String  // 交易类型：支出/收入
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
        transactionType: String = TransactionType.expense.rawValue,
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
        self.transactionType = transactionType
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

// 账目分类（基础分类，用于快速筛选）
enum ExpenseCategory: String, CaseIterable {
    case clothing = "服饰"
    case food = "餐饮"
    case transport = "交通"
    case home = "居家"
    case digital = "数码"
    case healthcare = "医疗"
    case entertainment = "娱乐"
    case learning = "学习"
    case other = "其他"
    
    static func from(string: String) -> ExpenseCategory {
        return ExpenseCategory.allCases.first { $0.rawValue == string } ?? .other
    }
}

