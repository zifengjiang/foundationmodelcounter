# 智能记账应用 - FoundationModelCounter

一个使用 iOS 26 FoundationModels API 和 Vision 框架的智能记账应用。通过拍照或选择账单图片，应用会自动识别文字并使用 AI 提取结构化的账目信息。

## 功能特性

- 📸 **智能识别**：拍照或选择图片后自动识别账单信息
- 🤖 **AI 分析**：使用设备端 FoundationModels 提取结构化数据
- 💰 **账目管理**：记录消费时间、金额、分类、商户等信息
- 📊 **分类统计**：按大类筛选和统计支出
- 🌍 **多币种支持**：支持 CNY、USD、EUR、JPY、GBP、HKD 等币种
- 💾 **本地存储**：使用 SwiftData 本地持久化存储

## 支持的分类

### 大类
- 餐饮：早餐、午餐、晚餐、零食、咖啡、外卖
- 交通：打车、公交、地铁、加油、停车
- 购物：服装、日用品、电子产品、书籍、化妆品
- 娱乐：电影、游戏、旅游、运动、订阅
- 住房：房租、水费、电费、网费、物业费
- 医疗：药品、挂号、检查、保险
- 教育：学费、培训、书籍、课程
- 其他：其他支出

## 技术栈

- **SwiftUI**：现代化的 UI 框架
- **SwiftData**：数据持久化（使用 @Model class）
- **Vision**：OCR 文字识别
- **FoundationModels**：设备端 AI 模型（iOS 26+）
  - 使用 `streamResponse` API 生成结构化输出
  - 使用 `@Generable` struct + `@Guide` 定义输出结构
- **PhotosUI**：图片选择器

## 系统要求

- iOS 26.0 或更高版本
- Xcode 16.0 或更高版本
- 支持 FoundationModels 的设备

## 使用方法

1. **添加账目**
   - 点击右上角的 "+" 按钮
   - 选择"选择账单图片"
   - 从相册选择账单照片或拍摄新照片
   - 应用会自动识别文字并分析账单信息
   - 确认或修改提取的信息
   - 点击"保存"

2. **查看账目**
   - 主页面显示所有账目，按日期分组
   - 顶部显示总支出统计
   - 点击分类标签可以筛选不同类别的支出

3. **查看详情**
   - 点击任意账目查看详细信息
   - 可以查看原始账单图片和识别的文本

4. **删除账目**
   - 在列表中左滑账目项
   - 点击"删除"按钮

## 项目结构

```
FoundationModelCounter/
├── Models/
│   └── Expense.swift              # 账目数据模型 (@Model class)
├── Services/
│   ├── OCRService.swift           # OCR 文字识别服务
│   └── AIExpenseAnalyzer.swift    # AI 账单分析服务
│                                  # - ExpenseInfo (@Generable struct)
│                                  # - streamResponse API
├── Views/
│   ├── AddExpenseView.swift       # 添加账目视图
│   └── ExpenseDetailView.swift    # 账目详情视图
├── ContentView.swift              # 主视图
└── FoundationModelCounterApp.swift # 应用入口
```

### 架构说明

项目采用**分离架构**解决 `@Generable` 和 `@Model` 的冲突：

```
AI 生成层                     持久化层
@Generable struct     →      @Model class
ExpenseInfo                  Expense
(FoundationModels)          (SwiftData)
```

详见：[FOUNDATION_MODELS_GUIDE.md](FOUNDATION_MODELS_GUIDE.md)

## 配置说明

### Info.plist 权限

需要在 Info.plist 中添加以下权限说明：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机来拍摄账单</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择账单图片</string>
```

## AI 结构化输出

应用使用 FoundationModels 的 `streamResponse` API 生成结构化账单信息：

### @Generable 定义
```swift
@Generable
struct ExpenseInfo: Identifiable {
    @Guide(description: "消费日期，ISO8601 格式")
    var date: String?
    
    @Guide(description: "消费金额，数字类型")
    var amount: Double?
    
    // ... 其他字段
}
```

### 使用 streamResponse
```swift
let responseStream = try session.streamResponse(
    to: userPrompt,
    generating: [ExpenseInfo].self
)

for try await partialResult in responseStream {
    result = partialResult.output.first
}
```

详细说明请参考：[FOUNDATION_MODELS_GUIDE.md](FOUNDATION_MODELS_GUIDE.md)

## 注意事项

1. **隐私保护**：所有 AI 处理都在设备端完成，无需联网
2. **识别准确性**：识别结果依赖于图片质量和 OCR 准确性
3. **手动修改**：AI 提取的信息可以手动修改
4. **图片存储**：账单图片会被压缩存储以节省空间

## 未来改进

- [ ] 添加月度/年度统计报表
- [ ] 支持导出数据为 CSV/Excel
- [ ] 添加预算管理功能
- [ ] 支持收入记录
- [ ] 添加图表可视化
- [ ] 支持多账户管理

## 开发者

Created by didi on 2025/10/28

## 许可证

MIT License

## 参考资料

- [Apple FoundationModels Documentation](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init(model:tools:instructions:))
- [Vision Framework Documentation](https://developer.apple.com/documentation/vision)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

