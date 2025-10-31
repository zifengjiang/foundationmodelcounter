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
    
    // 分期相关字段
    var isInstallment: Bool  // 是否为分期账单
    var parentExpenseId: UUID?  // 父账单ID（子账单需要）
    var installmentPeriods: Int  // 分期总期数
    var installmentAnnualRate: Double  // 年化利率（百分比，如12.5表示12.5%）
    var installmentNumber: Int  // 当前是第几期（1-N）
    var totalInstallmentAmount: Double  // 分期总金额（原始金额）
    
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
        imageData: Data? = nil,
        isInstallment: Bool = false,
        parentExpenseId: UUID? = nil,
        installmentPeriods: Int = 0,
        installmentAnnualRate: Double = 0.0,
        installmentNumber: Int = 0,
        totalInstallmentAmount: Double = 0.0
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
        self.isInstallment = isInstallment
        self.parentExpenseId = parentExpenseId
        self.installmentPeriods = installmentPeriods
        self.installmentAnnualRate = installmentAnnualRate
        self.installmentNumber = installmentNumber
        self.totalInstallmentAmount = totalInstallmentAmount
    }
    
    // 判断是否为父账单（分期的第一期）
    var isParentInstallment: Bool {
        return isInstallment && parentExpenseId == nil && installmentNumber == 1
    }
    
    // 判断是否为子账单
    var isChildInstallment: Bool {
        return isInstallment && parentExpenseId != nil && installmentNumber > 1
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

