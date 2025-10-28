//
//  Category.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import Foundation
import SwiftData

// 类目模型
@Model
final class Category {
    var id: UUID
    var mainCategory: String  // 大类
    var subCategory: String   // 小类
    var createdAt: Date
    var usageCount: Int       // 使用次数，用于排序
    
    init(
        id: UUID = UUID(),
        mainCategory: String,
        subCategory: String,
        createdAt: Date = Date(),
        usageCount: Int = 0
    ) {
        self.id = id
        self.mainCategory = mainCategory
        self.subCategory = subCategory
        self.createdAt = createdAt
        self.usageCount = usageCount
    }
}

// 类目管理服务
class CategoryService {
    static let shared = CategoryService()
    
    private init() {}
    
    // 初始默认类目
    static let defaultCategories: [(main: String, subs: [String])] = [
        ("服饰", ["上衣", "裤子", "裙子", "鞋子", "包包", "配饰", "内衣"]),
        ("餐饮", ["早餐", "午餐", "晚餐", "零食", "咖啡", "奶茶", "外卖", "水果"]),
        ("交通", ["地铁", "公交", "打车", "共享单车", "火车", "飞机", "加油", "停车"]),
        ("居家", ["家具", "厨具", "清洁用品", "收纳用品", "床上用品", "装饰品"]),
        ("数码", ["手机", "电脑", "耳机", "充电器", "数据线", "软件订阅", "游戏"]),
        ("医疗", ["药品", "挂号", "检查", "治疗", "保健品", "医疗保险"]),
        ("娱乐", ["电影", "演出", "旅游", "运动", "健身", "音乐订阅", "视频订阅"]),
        ("学习", ["书籍", "课程", "培训", "学费", "文具", "在线教育"])
    ]
    
    // 初始化默认类目
    func initializeDefaultCategories(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        // 如果已有类目，不重复初始化
        if existingCount > 0 {
            return
        }
        
        for (mainCat, subCats) in CategoryService.defaultCategories {
            for subCat in subCats {
                let category = Category(
                    mainCategory: mainCat,
                    subCategory: subCat,
                    usageCount: 0
                )
                context.insert(category)
            }
        }
        
        try? context.save()
    }
    
    // 获取所有类目，按使用频率排序
    func getAllCategories(context: ModelContext) -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [
                SortDescriptor(\.usageCount, order: .reverse),
                SortDescriptor(\.mainCategory),
                SortDescriptor(\.subCategory)
            ]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // 获取大类列表
    func getMainCategories(context: ModelContext) -> [String] {
        let categories = getAllCategories(context: context)
        let mainCategories = Set(categories.map { $0.mainCategory })
        return Array(mainCategories).sorted()
    }
    
    // 获取指定大类的小类列表
    func getSubCategories(for mainCategory: String, context: ModelContext) -> [String] {
        let categories = getAllCategories(context: context)
        return categories
            .filter { $0.mainCategory == mainCategory }
            .map { $0.subCategory }
            .sorted()
    }
    
    // 添加或更新类目
    func addOrUpdateCategory(mainCategory: String, subCategory: String, context: ModelContext) -> Category {
        // 查找是否已存在
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.mainCategory == mainCategory && category.subCategory == subCategory
            }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            existing.usageCount += 1
            return existing
        } else {
            let newCategory = Category(
                mainCategory: mainCategory,
                subCategory: subCategory,
                usageCount: 1
            )
            context.insert(newCategory)
            return newCategory
        }
    }
    
    // 格式化为 prompt 文本
    func formatCategoriesForPrompt(context: ModelContext) -> String {
        let categories = getAllCategories(context: context)
        
        var result = "已有类目（请优先使用）：\n"
        
        // 按大类分组
        let grouped = Dictionary(grouping: categories) { $0.mainCategory }
        
        for mainCategory in grouped.keys.sorted() {
            let subCategories = grouped[mainCategory]?
                .map { $0.subCategory }
                .sorted()
                .joined(separator: "、") ?? ""
            result += "- \(mainCategory)：\(subCategories)\n"
        }
        
        return result
    }
}

