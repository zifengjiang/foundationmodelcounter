# 智能记账应用 - FoundationModelCounter

一个使用 iOS 26 FoundationModels API 和 Vision 框架的智能记账应用。通过拍照或选择账单图片，应用会自动识别文字并使用 AI 提取结构化的账目信息。

## 功能特性

- 📸 **智能识别**：拍照或选择图片后自动识别账单信息
- 🤖 **双 AI 支持**：支持 Apple 端侧 AI 和 DeepSeek API 两种分析方式
  - **Apple 端侧 AI**：使用设备端 FoundationModels，保护隐私，无需联网
  - **DeepSeek API**：使用云端 API，需要配置 API Key
- 💰 **账目管理**：记录消费时间、金额、分类、商户等信息
- 📊 **分类统计**：按大类筛选和统计支出
- 🌍 **多币种支持**：支持 CNY、USD、EUR、JPY、GBP、HKD 等币种
- 💾 **本地存储**：使用 SwiftData 本地持久化存储
- ⚙️ **灵活配置**：可在设置中切换 AI 提供商
- ✏️ **完整编辑**：支持编辑账目和类目信息

## 支持的分类

应用采用**实际用途分类法**，使用生活类目而非支付渠道分类：

### 默认大类和小类

- **服饰**：上衣、裤子、裙子、鞋子、包包、配饰、内衣
- **餐饮**：早餐、午餐、晚餐、零食、咖啡、奶茶、外卖、水果
- **交通**：地铁、公交、打车、共享单车、火车、飞机、加油、停车
- **居家**：家具、厨具、清洁用品、收纳用品、床上用品、装饰品
- **数码**：手机、电脑、耳机、充电器、数据线、软件订阅、游戏
- **医疗**：药品、挂号、检查、治疗、保健品、医疗保险
- **娱乐**：电影、演出、旅游、运动、健身、音乐订阅、视频订阅
- **学习**：书籍、课程、培训、学费、文具、在线教育

### 动态类目系统

- ✅ AI 可以根据需要创建新类目
- ✅ 优先使用已有类目保持一致性
- ✅ 类目按使用频率自动排序
- ✅ 支持手动管理和删除类目
- ❌ 禁止使用"网购/消费/线上"等支付渠道做大类

## 技术栈

- **SwiftUI**：现代化的 UI 框架
- **SwiftData**：数据持久化（使用 @Model class）
- **Vision**：OCR 文字识别
- **FoundationModels**：设备端 AI 模型（iOS 26+）
  - 使用 `streamResponse` API 生成结构化输出
  - 使用 `@Generable` struct + `@Guide` 定义输出结构
- **DeepSeek API**：第三方云端 AI 服务
  - 支持通过 HTTP API 调用
  - JSON 格式的结构化输出
- **PhotosUI**：图片选择器

## 系统要求

- iOS 26.0 或更高版本
- Xcode 16.0 或更高版本
- 支持 FoundationModels 的设备

## 使用方法

1. **配置 AI 服务**（首次使用）

   - 点击左上角的设置图标
   - 选择 AI 提供商：
     - **Apple 端侧 AI**：无需配置，直接使用
     - **DeepSeek API**：需要配置 API Key
   - 如果选择 DeepSeek，点击"配置 API Key"输入你的密钥
   - 点击"完成"保存设置

2. **添加账目**

   - 点击右上角的 "+" 按钮
   - 选择"选择账单图片"
   - 从相册选择账单照片或拍摄新照片
   - 应用会自动识别文字并使用所选 AI 分析账单信息
   - 确认或修改提取的信息
   - 点击"保存"

3. **查看账目**

   - 主页面显示所有账目，按日期分组
   - 顶部显示总支出统计
   - 点击分类标签可以筛选不同类别的支出

4. **查看和编辑账目**

   - 点击任意账目查看详细信息
   - 可以查看原始账单图片和识别的文本
   - 点击右上角"编辑"按钮修改账目信息
   - 可以修改日期、金额、币种、类别、商户、备注等所有字段

5. **管理类目**

   - 点击左上角菜单，选择"类目管理"
   - 查看所有类目及其使用频率
   - 点击任意类目进行编辑
   - 添加新类目或删除不需要的类目
   - 搜索类目

6. **删除账目**

   - 在列表中左滑账目项
   - 点击"删除"按钮
   - 或在类目管理中左滑删除类目

## 项目结构

```
FoundationModelCounter/
├── Models/
│   ├── Expense.swift              # 账目数据模型 (@Model class)
│   ├── Category.swift             # 类目数据模型 (@Model class)
│   └── AIProvider.swift           # AI 提供商配置
├── Services/
│   ├── OCRService.swift           # OCR 文字识别服务
│   ├── AIExpenseAnalyzer.swift    # AI 账单分析服务（统一接口）
│   ├── DeepSeekService.swift      # DeepSeek API 服务
│   └── CategoryService.swift      # 类目管理服务
├── Views/
│   ├── AddExpenseView.swift       # 添加账目视图
│   ├── EditExpenseView.swift      # 编辑账目视图
│   ├── ExpenseDetailView.swift    # 账目详情视图
│   ├── SettingsView.swift         # AI 设置视图
│   └── CategoryManagerView.swift  # 类目管理视图（含编辑功能）
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
