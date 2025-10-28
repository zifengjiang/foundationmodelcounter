//
//  Category.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import Foundation
import SwiftData

// 交易类型枚举
enum TransactionType: String, Codable {
    case expense = "支出"
    case income = "收入"
}

// 类目模型
@Model
final class Category {
    var id: UUID
    var transactionType: String  // 交易类型：支出/收入
    var mainCategory: String     // 大类
    var subCategory: String      // 小类
    var createdAt: Date
    var usageCount: Int          // 使用次数，用于排序
    
    init(
        id: UUID = UUID(),
        transactionType: String = TransactionType.expense.rawValue,
        mainCategory: String,
        subCategory: String,
        createdAt: Date = Date(),
        usageCount: Int = 0
    ) {
        self.id = id
        self.transactionType = transactionType
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
    
    // 初始默认类目 - 支出类目（衣食住行分类体系）
    static let defaultExpenseCategories: [(main: String, subs: [String])] = [
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
    
    // 初始默认类目 - 收入类目
    static let defaultIncomeCategories: [(main: String, subs: [String])] = [
        // 职薪 - 工作相关收入
        ("职薪", [
            "工资薪金",    // 基本工资、奖金、津贴
            "兼职收入",    // 兼职、外包、咨询
            "绩效奖励",    // 年终奖、项目奖金、提成
            "福利补贴"     // 餐补、交通补贴、通讯补贴
        ]),
        
        // 理财 - 投资理财收益
        ("理财", [
            "投资收益",    // 股票、基金、债券收益
            "利息收入",    // 存款利息、债券利息
            "分红收益",    // 股票分红、基金分红
            "租金收入"     // 房租、车位租赁
        ]),
        
        // 经营 - 生意经营收入
        ("经营", [
            "销售收入",    // 商品销售、服务收入
            "佣金收入",    // 中介佣金、代理费
            "版权收入",    // 版税、专利授权
            "广告收入"     // 自媒体、内容创作
        ]),
        
        // 其他 - 其他收入来源
        ("其他", [
            "礼金红包",    // 节日红包、生日礼金
            "退款返现",    // 商品退款、信用卡返现
            "中奖收入",    // 彩票、抽奖、奖品
            "其他收入"     // 未分类的其他收入
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
        
        // 初始化支出类目
        for (mainCat, subCats) in CategoryService.defaultExpenseCategories {
            for subCat in subCats {
                let category = Category(
                    transactionType: TransactionType.expense.rawValue,
                    mainCategory: mainCat,
                    subCategory: subCat,
                    usageCount: 0
                )
                context.insert(category)
            }
        }
        
        // 初始化收入类目
        for (mainCat, subCats) in CategoryService.defaultIncomeCategories {
            for subCat in subCats {
                let category = Category(
                    transactionType: TransactionType.income.rawValue,
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
    func getAllCategories(context: ModelContext, transactionType: TransactionType? = nil) -> [Category] {
        var descriptor = FetchDescriptor<Category>(
            sortBy: [
                SortDescriptor(\.usageCount, order: .reverse),
                SortDescriptor(\.mainCategory),
                SortDescriptor(\.subCategory)
            ]
        )
        
        // 根据交易类型过滤
        if let type = transactionType {
            descriptor.predicate = #Predicate { category in
                category.transactionType == type.rawValue
            }
        }
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // 获取大类列表
    func getMainCategories(context: ModelContext, transactionType: TransactionType? = nil) -> [String] {
        let categories = getAllCategories(context: context, transactionType: transactionType)
        let mainCategories = Set(categories.map { $0.mainCategory })
        return Array(mainCategories).sorted()
    }
    
    // 获取指定大类的小类列表
    func getSubCategories(for mainCategory: String, context: ModelContext, transactionType: TransactionType? = nil) -> [String] {
        let categories = getAllCategories(context: context, transactionType: transactionType)
        return categories
            .filter { $0.mainCategory == mainCategory }
            .map { $0.subCategory }
            .sorted()
    }
    
    // 添加或更新类目
    func addOrUpdateCategory(transactionType: TransactionType, mainCategory: String, subCategory: String, context: ModelContext) -> Category {
        // 查找是否已存在
        let typeString = transactionType.rawValue
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.transactionType == typeString && 
                category.mainCategory == mainCategory && 
                category.subCategory == subCategory
            }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            existing.usageCount += 1
            return existing
        } else {
            let newCategory = Category(
                transactionType: transactionType.rawValue,
                mainCategory: mainCategory,
                subCategory: subCategory,
                usageCount: 1
            )
            context.insert(newCategory)
            return newCategory
        }
    }
    
    // 格式化为 prompt 文本
    func formatCategoriesForPrompt(context: ModelContext, transactionType: TransactionType) -> String {
        let categories = getAllCategories(context: context, transactionType: transactionType)
        
        var result = "已有\(transactionType.rawValue)类目（请优先使用）：\n\n"
        
        // 按大类分组
        let grouped = Dictionary(grouping: categories) { $0.mainCategory }
        
        // 定义顺序
        let categoryOrder: [String]
        if transactionType == .expense {
            categoryOrder = ["衣", "食", "住", "行"]
        } else {
            categoryOrder = ["职薪", "理财", "经营", "其他"]
        }
        
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
    static func getMainCategoryIcon(for category: String, transactionType: TransactionType = .expense) -> String {
        if transactionType == .expense {
            switch category {
            case "衣": return "tshirt.fill"
            case "食": return "fork.knife"
            case "住": return "house.fill"
            case "行": return "car.fill"
            default: return "circle.fill"
            }
        } else {
            switch category {
            case "职薪": return "briefcase.fill"
            case "理财": return "chart.line.uptrend.xyaxis"
            case "经营": return "building.2.fill"
            case "其他": return "ellipsis.circle.fill"
            default: return "circle.fill"
            }
        }
    }
    
    // 获取小类图标（可选，提供更细致的图标）
    static func getSubCategoryIcon(for mainCategory: String, subCategory: String, transactionType: TransactionType = .expense) -> String {
        if transactionType == .expense {
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
                return getMainCategoryIcon(for: mainCategory, transactionType: transactionType)
            }
        } else {
            switch mainCategory {
            case "职薪":
                switch subCategory {
                case "工资薪金": return "banknote.fill"
                case "兼职收入": return "briefcase.fill"
                case "绩效奖励": return "trophy.fill"
                case "福利补贴": return "gift.fill"
                default: return "briefcase.fill"
                }
            case "理财":
                switch subCategory {
                case "投资收益": return "chart.line.uptrend.xyaxis"
                case "利息收入": return "percent"
                case "分红收益": return "dollarsign.circle.fill"
                case "租金收入": return "house.fill"
                default: return "chart.line.uptrend.xyaxis"
                }
            case "经营":
                switch subCategory {
                case "销售收入": return "cart.fill"
                case "佣金收入": return "dollarsign.circle"
                case "版权收入": return "doc.text.fill"
                case "广告收入": return "megaphone.fill"
                default: return "building.2.fill"
                }
            case "其他":
                switch subCategory {
                case "礼金红包": return "envelope.fill"
                case "退款返现": return "arrow.uturn.backward.circle.fill"
                case "中奖收入": return "gift.fill"
                case "其他收入": return "ellipsis.circle.fill"
                default: return "ellipsis.circle.fill"
                }
            default:
                return getMainCategoryIcon(for: mainCategory, transactionType: transactionType)
            }
        }
    }
    
    // 获取大类颜色
    static func getMainCategoryColor(for category: String, transactionType: TransactionType = .expense) -> String {
        if transactionType == .expense {
            switch category {
            case "衣": return "pink"
            case "食": return "orange"
            case "住": return "green"
            case "行": return "blue"
            default: return "gray"
            }
        } else {
            switch category {
            case "职薪": return "blue"
            case "理财": return "green"
            case "经营": return "purple"
            case "其他": return "orange"
            default: return "gray"
            }
        }
    }
}

