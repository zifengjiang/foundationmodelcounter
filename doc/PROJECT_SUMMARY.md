# 项目总结 - 智能记账应用

## 🎯 项目概述

这是一个基于 iOS 26 FoundationModels API 的智能记账应用，通过 AI 和 OCR 技术自动识别账单信息，实现快速记账。

## 📱 核心功能

### 1. 智能账单识别
- **OCR 技术**：使用 Vision 框架识别图片中的文字
- **AI 分析**：利用 FoundationModels 提取结构化账目信息
- **自动填充**：智能填充日期、金额、分类等字段

### 2. 账目管理
- **分类管理**：8 大类 + 多个小类
- **多币种支持**：CNY、USD、EUR、JPY、GBP、HKD
- **数据持久化**：使用 SwiftData 本地存储

### 3. 数据展示
- **分组列表**：按日期分组展示
- **统计功能**：实时统计总支出
- **分类筛选**：按大类筛选账目
- **详情查看**：查看完整账目信息和原始图片

## 🏗️ 技术架构

### 技术栈
```
SwiftUI          - UI 框架
SwiftData        - 数据持久化
Vision           - OCR 文字识别
FoundationModels - 设备端 AI 模型
PhotosUI         - 图片选择
```

### 架构模式
- **MVVM**：清晰的视图-模型分离
- **Service Layer**：服务层封装核心功能
- **Dependency Injection**：通过 Environment 注入依赖

## 📂 项目结构

```
FoundationModelCounter/
├── FoundationModelCounter/
│   ├── Models/
│   │   └── Expense.swift              # 账目数据模型
│   │       - Expense 类（@Model）
│   │       - ExpenseCategory 枚举
│   │       - 分类和小类定义
│   │
│   ├── Services/
│   │   ├── OCRService.swift           # OCR 服务
│   │   │   - recognizeText() 方法
│   │   │   - Vision 框架集成
│   │   │   - 支持中英文识别
│   │   │
│   │   └── AIExpenseAnalyzer.swift    # AI 分析服务
│   │       - analyzeExpense() 方法
│   │       - FoundationModels 集成
│   │       - JSON 解析和提取
│   │
│   ├── Views/
│   │   ├── AddExpenseView.swift       # 添加账目视图
│   │   │   - 图片选择器
│   │   │   - 表单输入
│   │   │   - OCR + AI 处理流程
│   │   │
│   │   └── ExpenseDetailView.swift    # 详情视图
│   │       - 账目详细信息展示
│   │       - 原始图片展示
│   │       - 识别文本展示
│   │
│   ├── ContentView.swift              # 主视图
│   │   - 账目列表
│   │   - 分类筛选
│   │   - 统计显示
│   │   - ExpenseRow 组件
│   │   - CategoryChip 组件
│   │
│   ├── FoundationModelCounterApp.swift # 应用入口
│   │   - SwiftData 配置
│   │   - ModelContainer 初始化
│   │
│   └── Assets.xcassets/               # 资源文件
│
├── README.md                          # 项目说明
├── SETUP.md                           # 配置指南
├── USAGE_GUIDE.md                     # 使用指南
└── PROJECT_SUMMARY.md                 # 本文件
```

## 🔑 核心代码说明

### 1. 数据模型（Expense.swift）

```swift
@Model
final class Expense {
    var date: Date
    var amount: Double
    var currency: String
    var mainCategory: String
    var subCategory: String
    var merchant: String
    var note: String
    var originalText: String
    var imageData: Data?
}
```

**特点**：
- 使用 SwiftData 的 @Model 宏
- 支持图片数据存储
- 保留原始识别文本

### 2. OCR 服务（OCRService.swift）

```swift
func recognizeText(from image: UIImage) async throws -> String
```

**特点**：
- 使用 Vision 框架的 VNRecognizeTextRequest
- 支持中英文识别
- 异步处理，不阻塞 UI
- 高准确度模式

### 3. AI 分析服务（AIExpenseAnalyzer.swift）

```swift
func analyzeExpense(from text: String) async throws -> ExpenseInfo
```

**特点**：
- 使用 FoundationModels 的 LanguageModelSession
- 精心设计的提示词
- JSON 格式输出
- 结构化数据提取

**提示词设计**：
- 明确指定字段和格式
- 提供分类选项
- 要求 JSON 输出
- 处理缺失信息

### 4. 添加账目视图（AddExpenseView.swift）

**流程**：
1. 用户选择图片
2. OCR 识别文字
3. AI 分析账单
4. 自动填充表单
5. 用户确认/修改
6. 保存到数据库

**特点**：
- PhotosUI 集成
- 加载状态显示
- 错误处理
- 表单验证

### 5. 主视图（ContentView.swift）

**组件**：
- 统计卡片：显示总支出
- 分类筛选：水平滚动的标签
- 账目列表：按日期分组
- ExpenseRow：单个账目项
- CategoryChip：分类标签

**特点**：
- 响应式设计
- 流畅动画
- 彩色分类标识
- 左滑删除

## 💡 技术亮点

### 1. FoundationModels 集成

```swift
let session = try await LanguageModelSession(
    model: .large,
    instructions: "..."
)

for try await chunk in session.generateText(prompt: prompt) {
    fullResponse += chunk.text
}
```

**优势**：
- 设备端运行，无需网络
- 隐私保护
- 实时响应
- 流式输出

### 2. Vision 框架优化

```swift
request.recognitionLanguages = ["zh-Hans", "en-US"]
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
```

**优势**：
- 中英文混合识别
- 高准确度模式
- 语言纠错
- 异步处理

### 3. SwiftData 应用

```swift
@Query(sort: \Expense.date, order: .reverse) 
private var expenses: [Expense]
```

**优势**：
- 声明式查询
- 自动排序
- 响应式更新
- 类型安全

### 4. UI/UX 设计

- **现代设计**：圆角卡片、阴影、渐变
- **彩色标识**：不同分类使用不同颜色
- **流畅动画**：withAnimation 包裹状态变化
- **加载状态**：处理过程中显示进度
- **错误处理**：友好的错误提示

## 🎨 UI 组件

### 统计卡片
- 显示总支出金额
- 支持分类筛选
- 阴影效果

### 账目行（ExpenseRow）
- 分类图标（彩色圆形背景）
- 商户名称/小类
- 分类信息
- 金额和币种

### 分类标签（CategoryChip）
- 胶囊形状
- 选中/未选中状态
- 颜色变化动画

### 详情页
- 账单图片
- 大号金额显示
- 分组信息框
- 原始文本（可选中复制）

## 🔒 隐私和安全

1. **本地处理**：
   - OCR 在设备端完成
   - AI 分析在设备端完成
   - 无需网络连接

2. **数据存储**：
   - 仅存储在设备本地
   - 不上传到云端
   - SwiftData 加密存储

3. **权限管理**：
   - 相机权限（可选）
   - 相册权限（可选）
   - 明确的权限说明

## 📊 性能优化

1. **图片压缩**：
   - JPEG 压缩质量 0.7
   - 减少存储空间

2. **异步处理**：
   - OCR 异步执行
   - AI 分析异步执行
   - 不阻塞主线程

3. **懒加载**：
   - 使用 @Query 自动加载
   - 按需加载图片

4. **内存管理**：
   - 及时释放图片资源
   - 避免内存泄漏

## 🚀 未来扩展

### 短期计划
- [ ] 添加搜索功能
- [ ] 支持编辑已有账目
- [ ] 添加标签功能
- [ ] 支持多选删除

### 中期计划
- [ ] 月度/年度报表
- [ ] 图表可视化
- [ ] 预算管理
- [ ] 数据导出（CSV/Excel）

### 长期计划
- [ ] iCloud 同步
- [ ] Widget 小组件
- [ ] Apple Watch 支持
- [ ] 多账户管理
- [ ] 收入记录
- [ ] 分账功能

## 📝 开发日志

**2025-10-28**
- ✅ 创建项目基础架构
- ✅ 实现 Expense 数据模型
- ✅ 集成 OCR 服务
- ✅ 集成 FoundationModels AI 分析
- ✅ 实现添加账目功能
- ✅ 实现账目列表和详情
- ✅ 实现分类筛选
- ✅ 实现统计功能
- ✅ 完善 UI 设计
- ✅ 编写文档

## 🛠️ 系统要求

- **iOS**: 26.0+
- **Xcode**: 16.0+
- **Swift**: 6.0+
- **设备**: 支持 FoundationModels 的设备

## 📖 相关文档

1. **README.md** - 项目介绍和功能说明
2. **SETUP.md** - 配置和部署指南
3. **USAGE_GUIDE.md** - 详细使用教程
4. **PROJECT_SUMMARY.md** - 本文件，技术总结

## 🎓 学习要点

通过这个项目可以学习：

1. **FoundationModels 使用**
   - 如何初始化 LanguageModelSession
   - 如何设计有效的提示词
   - 如何处理流式输出

2. **Vision 框架**
   - OCR 文字识别
   - 图像处理
   - 异步请求处理

3. **SwiftData**
   - 模型定义
   - 查询和排序
   - 数据持久化

4. **SwiftUI 进阶**
   - 复杂布局
   - 状态管理
   - 自定义组件
   - 动画效果

5. **架构设计**
   - 服务层设计
   - 依赖注入
   - 错误处理
   - 异步编程

## 🙏 致谢

感谢 Apple 提供的强大框架：
- FoundationModels - 设备端 AI 能力
- Vision - 强大的图像识别
- SwiftData - 现代化的数据持久化
- SwiftUI - 声明式 UI 框架

## 📄 许可证

MIT License

## 👨‍💻 开发者

Created by didi on 2025/10/28

---

**项目已完成！** 🎉

现在你可以：
1. 在 Xcode 中打开项目
2. 按照 SETUP.md 配置权限
3. 构建并运行应用
4. 参考 USAGE_GUIDE.md 使用应用

如有问题，请参考相关文档或联系开发者。

