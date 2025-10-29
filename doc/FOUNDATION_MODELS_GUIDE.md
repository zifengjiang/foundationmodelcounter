# FoundationModels API 使用指南

## 🎯 核心概念

### @Generable vs @Model 的冲突

在使用 FoundationModels 的结构化输出功能时，会遇到一个重要的架构问题：

| 框架 | 要求 | 用途 |
|------|------|------|
| **FoundationModels** | `@Generable struct` | AI 生成结构化输出 |
| **SwiftData** | `@Model class` | 数据持久化存储 |

这两个宏**不能同时使用**在同一个类型上！

## 🔧 解决方案

采用**分离架构**：

```
AI 生成 (@Generable struct)  →  数据转换  →  持久化 (@Model class)
    ExpenseInfo                              Expense
```

### 1. AI 生成层 - ExpenseInfo

```swift
// 用于 AI 生成的 struct
@Generable
struct ExpenseInfo: Identifiable {
    var id: Int
    
    @Guide(description: "消费日期，ISO8601 格式")
    var date: String?
    
    @Guide(description: "消费金额")
    var amount: Double?
    
    @Guide(description: "币种代码")
    var currency: String?
    
    @Guide(description: "消费大类")
    var mainCategory: String?
    
    // ... 其他字段
}
```

**关键点**：
- ✅ 使用 `struct`
- ✅ 使用 `@Generable` 宏
- ✅ 每个字段使用 `@Guide` 描述
- ✅ 实现 `Identifiable` 协议

### 2. 数据持久化层 - Expense

```swift
// 用于数据存储的 class
@Model
final class Expense {
    var id: UUID
    var date: Date
    var amount: Double
    var currency: String
    var mainCategory: String
    // ... 其他字段
}
```

**关键点**：
- ✅ 使用 `class`
- ✅ 使用 `@Model` 宏
- ✅ 不需要 `@Guide` 描述
- ✅ 支持 SwiftData 持久化

## 🚀 使用 streamResponse API

### 正确的 API 调用方式

```swift
func analyzeExpense(from text: String) async throws -> ExpenseInfo {
    // 1. 创建 session
    let session = LanguageModelSession(
        model: .default,
        instructions: "你的系统提示词..."
    )
    
    // 2. 使用 streamResponse 生成结构化输出
    let responseStream = try session.streamResponse(
        to: userPrompt,
        generating: [ExpenseInfo].self  // 注意：是数组类型
    )
    
    // 3. 处理流式响应
    var result: ExpenseInfo?
    
    for try await partialResult in responseStream {
        // 获取第一个生成的结果
        if let firstExpense = partialResult.output.first {
            result = firstExpense
        }
    }
    
    return result!
}
```

### 关键参数说明

#### `generating` 参数
```swift
generating: [ExpenseInfo].self
```
- **必须是数组类型**：`[YourType].self`
- 即使只生成一个对象，也要用数组包裹
- AI 会返回 `[ExpenseInfo]` 类型的数组

#### `includeSchemaInPrompt` 参数（可选）
```swift
session.streamResponse(
    to: prompt,
    generating: [ExpenseInfo].self,
    includeSchemaInPrompt: true  // 是否在提示词中包含 schema
)
```

#### `options` 参数（可选）
```swift
let options = GenerationOptions()
// 配置生成选项

session.streamResponse(
    to: prompt,
    generating: [ExpenseInfo].self,
    options: options
)
```

## 📋 @Guide 宏的使用

`@Guide` 用于为 AI 提供字段说明，帮助 AI 理解如何填充数据。

### 基本用法

```swift
@Generable
struct ExpenseInfo {
    @Guide(description: "消费日期，ISO8601 格式，例如：2025-10-28T14:30:00Z")
    var date: String?
    
    @Guide(description: "消费金额，数字类型")
    var amount: Double?
    
    @Guide(description: "币种代码，如：CNY、USD、EUR")
    var currency: String?
}
```

### 编写高质量的 @Guide 描述

✅ **好的描述**：
```swift
@Guide(description: "消费大类，从以下选择：餐饮、交通、购物、娱乐、住房、医疗、教育、其他")
var mainCategory: String?
```

❌ **不够详细的描述**：
```swift
@Guide(description: "分类")
var mainCategory: String?
```

### @Guide 最佳实践

1. **明确格式要求**
```swift
@Guide(description: "消费日期，ISO8601 格式，例如：2025-10-28T14:30:00Z")
```

2. **提供可选值**
```swift
@Guide(description: "币种代码，如：CNY、USD、EUR、JPY、GBP、HKD")
```

3. **说明取值范围**
```swift
@Guide(description: "消费小类，根据大类选择对应的小类")
```

4. **解释字段用途**
```swift
@Guide(description: "商户名称或店铺名称")
```

## 🔄 数据转换

从 `ExpenseInfo` (AI 生成) 转换到 `Expense` (持久化)：

```swift
// 在 AddExpenseView.swift 中
private func processImage(_ image: UIImage) async {
    // 1. OCR 识别
    recognizedText = try await OCRService.shared.recognizeText(from: image)
    
    // 2. AI 分析（返回 ExpenseInfo）
    let expenseInfo = try await AIExpenseAnalyzer.shared.analyzeExpense(from: recognizedText)
    
    // 3. 填充 UI 表单
    await MainActor.run {
        if let dateString = expenseInfo.date,
           let parsedDate = ISO8601DateFormatter().date(from: dateString) {
            date = parsedDate
        }
        
        if let amt = expenseInfo.amount {
            amount = String(format: "%.2f", amt)
        }
        
        if let curr = expenseInfo.currency {
            currency = curr
        }
        
        // ... 其他字段
    }
}

// 4. 保存时创建 Expense 对象
private func saveExpense() {
    let expense = Expense(
        date: date,
        amount: amountValue,
        currency: currency,
        mainCategory: mainCategory,
        // ... 其他字段
    )
    
    modelContext.insert(expense)  // SwiftData 持久化
}
```

## 💡 架构优势

### 关注点分离
- **ExpenseInfo**：专注于 AI 生成和数据提取
- **Expense**：专注于数据持久化和业务逻辑

### 灵活性
- 可以独立修改 AI 生成的结构
- 不影响数据库 schema
- 便于测试和调试

### 类型安全
- 编译时检查
- 自动补全
- 避免 JSON 解析错误

## 🎨 完整示例

### 定义 @Generable 结构

```swift
import FoundationModels

@Generable
struct PaletteInfo: Identifiable {
    var id: Int
    
    @Guide(description: "Palette name")
    var name: String
    
    @Guide(description: "Hex color codes")
    var colors: [String]
}
```

### 使用 streamResponse

```swift
class AIService {
    func generatePalettes(prompt: String) async throws -> [PaletteInfo] {
        let session = LanguageModelSession(
            model: .default,
            instructions: "Generate color palettes based on user descriptions"
        )
        
        let response = try session.streamResponse(
            to: prompt,
            generating: [PaletteInfo].self
        )
        
        var palettes: [PaletteInfo] = []
        
        for try await partial in response {
            palettes = partial.output
        }
        
        return palettes
    }
}
```

### 在 SwiftUI 中使用

```swift
struct PaletteGeneratorView: View {
    @State private var userPrompt = ""
    @State private var palettes: [PaletteInfo] = []
    @State private var isGenerating = false
    
    var body: some View {
        VStack {
            TextField("Describe your palette", text: $userPrompt)
            
            Button("Generate") {
                Task {
                    isGenerating = true
                    do {
                        palettes = try await AIService.shared.generatePalettes(prompt: userPrompt)
                    } catch {
                        // 错误处理
                    }
                    isGenerating = false
                }
            }
            .disabled(isGenerating)
            
            List(palettes) { palette in
                PaletteRow(palette: palette)
            }
        }
    }
}
```

## ⚠️ 常见错误

### 错误 1：在 @Model 类上使用 @Guide

```swift
❌ 错误：
@Model
final class Expense {
    @Guide(description: "...")  // 编译错误！
    var date: Date
}
```

**解决方案**：使用分离的 struct

### 错误 2：generating 参数不是数组

```swift
❌ 错误：
session.streamResponse(
    to: prompt,
    generating: ExpenseInfo.self  // 错误！
)

✅ 正确：
session.streamResponse(
    to: prompt,
    generating: [ExpenseInfo].self  // 必须是数组
)
```

### 错误 3：@Generable 用于 class

```swift
❌ 错误：
@Generable
class ExpenseInfo { ... }  // 必须是 struct

✅ 正确：
@Generable
struct ExpenseInfo { ... }
```

## 📊 性能考虑

### 流式处理
```swift
// 实时更新 UI
for try await partialResult in responseStream {
    await MainActor.run {
        // 更新 UI 显示部分结果
        self.currentResult = partialResult.output.first
    }
}
```

### 错误处理
```swift
do {
    let response = try session.streamResponse(...)
    // 处理响应
} catch {
    if error is LanguageModelSessionError {
        // 处理 FoundationModels 特定错误
    } else {
        // 处理其他错误
    }
}
```

## 🔍 调试技巧

### 1. 打印生成的内容

```swift
for try await partial in responseStream {
    print("Partial output: \(partial.output)")
    result = partial.output.first
}
```

### 2. 验证 @Guide 描述

确保 AI 能理解你的描述：
- 使用清晰的语言
- 提供示例值
- 指定格式要求

### 3. 测试提示词

在 instructions 中提供详细的上下文：

```swift
let instructions = """
你是一个专业的账单分析助手。

输入：用户提供的账单文本
输出：结构化的账目信息

字段说明：
- date: ISO8601 格式的日期时间
- amount: 纯数字，不包含货币符号
- currency: 三字母货币代码
...
"""
```

## 📚 参考资料

- [FoundationModels 官方文档](https://developer.apple.com/documentation/foundationmodels/)
- [LanguageModelSession API](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)
- [SwiftData 文档](https://developer.apple.com/documentation/swiftdata)

## 🎯 总结

### 关键要点

1. **分离关注点**：AI 生成用 `@Generable struct`，持久化用 `@Model class`
2. **使用 streamResponse**：正确的 API 用于结构化输出
3. **编写好的 @Guide**：详细的描述帮助 AI 理解字段
4. **流式处理**：实时更新 UI，提供更好的用户体验
5. **错误处理**：妥善处理生成失败的情况

### 架构模式

```
用户输入（图片/文本）
    ↓
OCR 识别
    ↓
AI 分析 (@Generable struct)
    ↓
数据验证/转换
    ↓
UI 展示/编辑
    ↓
保存 (@Model class)
    ↓
SwiftData 持久化
```

这个架构既满足了 FoundationModels 的要求，又保持了 SwiftData 的便利性！

---

Created by didi | 2025-10-28

