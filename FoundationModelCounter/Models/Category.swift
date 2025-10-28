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
    
    // 初始默认类目 - 衣食住行分类体系
    static let defaultCategories: [(main: String, subs: [String])] = [
        // 衣 - 外在与形象相关
        ("衣", [
            "日常穿着",    // 衣服、鞋袜、内衣
            "形象提升",    // 理发、美发、美甲、美容、护肤、化妆
            "社交形象"     // 配饰、饰品、特殊场合穿搭
        ]),
        
        // 食 - 吃喝与健康摄入
        ("食", [
            "日常饮食",    // 买菜、做饭、基础饮品
            "外食餐饮",    // 餐厅、外卖、咖啡、奶茶
            "社交应酬",    // 聚会、请客、小酒局
            "营养补充"     // 蛋白粉、维生素、保健
        ]),
        
        // 住 - 生活稳定成本
        ("住", [
            "居住成本",    // 房租、水电、物业、宽带
            "日常生活",    // 清洁、家用品、厨具、学习办公
            "医疗健康",    // 看病、药品、护理
            "长期保障",    // 保险、会员订阅
            "情感家庭"     // 人情往来、礼金礼品
        ]),
        
        // 行 - 移动 + 体验
        ("行", [
            "城市出行",    // 公交、地铁、打车、共享出行
            "运动健身",    // 游泳、篮球、健身卡等
            "休闲娱乐",    // 电影、音乐会、展览、桌游
            "旅行度假",    // 机票、酒店、旅途中开销
            "数码提升"     // 手机、电脑、生产力设备
        ])
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
        
        var result = "已有类目（请优先使用）：\n\n"
        
        // 按大类分组
        let grouped = Dictionary(grouping: categories) { $0.mainCategory }
        
        // 定义顺序
        let categoryOrder = ["衣", "食", "住", "行"]
        
        for mainCategory in categoryOrder {
            if let subCategories = grouped[mainCategory] {
                let subCatList = subCategories
                    .map { $0.subCategory }
                    .sorted()
                    .joined(separator: "、")
                result += "【\(mainCategory)】\(subCatList)\n"
            }
        }
        
        return result
    }
    
    // 获取大类图标
    static func getMainCategoryIcon(for category: String) -> String {
        switch category {
        case "衣": return "tshirt.fill"
        case "食": return "fork.knife"
        case "住": return "house.fill"
        case "行": return "car.fill"
        default: return "circle.fill"
        }
    }
    
    // 获取小类图标（可选，提供更细致的图标）
    static func getSubCategoryIcon(for mainCategory: String, subCategory: String) -> String {
        switch mainCategory {
        case "衣":
            switch subCategory {
            case "日常穿着": return "tshirt.fill"
            case "形象提升": return "scissors"
            case "社交形象": return "sparkles"
            default: return "tshirt.fill"
            }
        case "食":
            switch subCategory {
            case "日常饮食": return "cart.fill"
            case "外食餐饮": return "fork.knife"
            case "社交应酬": return "wineglass.fill"
            case "营养补充": return "pills.fill"
            default: return "fork.knife"
            }
        case "住":
            switch subCategory {
            case "居住成本": return "building.2.fill"
            case "日常生活": return "cart.fill"
            case "医疗健康": return "cross.case.fill"
            case "长期保障": return "shield.fill"
            case "情感家庭": return "heart.fill"
            default: return "house.fill"
            }
        case "行":
            switch subCategory {
            case "城市出行": return "bus.fill"
            case "运动健身": return "figure.run"
            case "休闲娱乐": return "theatermasks.fill"
            case "旅行度假": return "airplane"
            case "数码提升": return "laptopcomputer"
            default: return "car.fill"
            }
        default:
            return getMainCategoryIcon(for: mainCategory)
        }
    }
    
    // 获取大类颜色
    static func getMainCategoryColor(for category: String) -> String {
        switch category {
        case "衣": return "pink"
        case "食": return "orange"
        case "住": return "green"
        case "行": return "blue"
        default: return "gray"
        }
    }
}

