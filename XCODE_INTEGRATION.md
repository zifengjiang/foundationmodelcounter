# Xcode 项目集成指南

## 📦 添加新文件到 Xcode 项目

由于我们创建了新的 Swift 文件，你需要将它们添加到 Xcode 项目中。

### 方法 1：自动检测（推荐）

1. 在 Xcode 中打开项目
2. Xcode 可能会自动检测到新文件并提示添加
3. 如果出现提示，选择"Add"或"添加"

### 方法 2：手动添加文件

#### 步骤 1：添加 Models 文件夹和文件

1. 在 Xcode Project Navigator 中，右键点击 `FoundationModelCounter` 组
2. 选择 "Add Files to 'FoundationModelCounter'..."
3. 导航到 `/Users/didi/Documents/FoundationModelCounter/FoundationModelCounter/Models/`
4. 选择 `Expense.swift`
5. 确保勾选：
   - ✅ "Copy items if needed"（如果需要复制项目）
   - ✅ "Create groups"（创建组）
   - ✅ Target: FoundationModelCounter
6. 点击 "Add"

#### 步骤 2：添加 Services 文件夹和文件

1. 右键点击 `FoundationModelCounter` 组
2. 选择 "Add Files to 'FoundationModelCounter'..."
3. 导航到 `/Users/didi/Documents/FoundationModelCounter/FoundationModelCounter/Services/`
4. 选择以下文件（按住 Command 键多选）：
   - `OCRService.swift`
   - `AIExpenseAnalyzer.swift`
5. 确保勾选相同的选项
6. 点击 "Add"

#### 步骤 3：添加 Views 文件夹和文件

1. 右键点击 `FoundationModelCounter` 组
2. 选择 "Add Files to 'FoundationModelCounter'..."
3. 导航到 `/Users/didi/Documents/FoundationModelCounter/FoundationModelCounter/Views/`
4. 选择以下文件：
   - `AddExpenseView.swift`
   - `ExpenseDetailView.swift`
5. 确保勾选相同的选项
6. 点击 "Add"

### 方法 3：拖拽添加

1. 在 Finder 中打开项目文件夹
2. 将整个 `Models`、`Services`、`Views` 文件夹拖入 Xcode
3. 在弹出的对话框中确保：
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Target: FoundationModelCounter
4. 点击 "Finish"

## 🗑️ 删除旧文件

`Item.swift` 已经被删除，如果在 Xcode 中还能看到它：

1. 在 Project Navigator 中找到 `Item.swift`
2. 右键点击，选择 "Delete"
3. 在弹出的对话框中选择 "Move to Trash"

## ⚙️ 配置项目设置

### 1. 设置部署目标

1. 选择项目文件（最顶部的蓝色图标）
2. 选择 Target "FoundationModelCounter"
3. 在 "General" 标签页中
4. 找到 "Minimum Deployments"
5. 将 "iOS" 设置为 **26.0**

### 2. 添加权限说明

#### 选项 A：通过 Info 标签页

1. 选择 Target "FoundationModelCounter"
2. 点击 "Info" 标签页
3. 在 "Custom iOS Target Properties" 部分
4. 点击 "+" 添加新条目

添加以下两个键值对：

| Key | Type | Value |
|-----|------|-------|
| Privacy - Camera Usage Description | String | 需要访问相机来拍摄账单 |
| Privacy - Photo Library Usage Description | String | 需要访问相册来选择账单图片 |

#### 选项 B：编辑 Info.plist（如果存在）

如果项目中有 `Info.plist` 文件：

1. 在 Project Navigator 中找到 `Info.plist`
2. 右键点击，选择 "Open As" > "Source Code"
3. 在 `<dict>` 标签内添加：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机来拍摄账单</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择账单图片</string>
```

### 3. 添加 Foundation Models Capability

1. 选择 Target "FoundationModelCounter"
2. 点击 "Signing & Capabilities" 标签页
3. 点击左上角的 "+ Capability" 按钮
4. 搜索 "Foundation Models"
5. 双击添加

**注意**：如果找不到 "Foundation Models" capability：
- 确保 Xcode 版本为 16.0+
- 确保部署目标为 iOS 26.0+
- 这是 iOS 26 的新功能

## 🔍 验证项目结构

添加文件后，你的 Project Navigator 应该类似这样：

```
FoundationModelCounter
├── FoundationModelCounterApp.swift
├── ContentView.swift
├── Models
│   └── Expense.swift
├── Services
│   ├── OCRService.swift
│   └── AIExpenseAnalyzer.swift
├── Views
│   ├── AddExpenseView.swift
│   └── ExpenseDetailView.swift
├── Assets.xcassets
└── Helper
```

## 🔨 构建项目

### 1. 清理构建缓存

在添加新文件后，建议清理构建缓存：

1. 菜单栏：Product > Clean Build Folder
2. 或按快捷键：⇧⌘K (Shift + Command + K)

### 2. 构建项目

1. 选择模拟器或真机作为目标设备
2. 菜单栏：Product > Build
3. 或按快捷键：⌘B (Command + B)

### 3. 解决编译问题

如果遇到编译错误：

#### 错误："Cannot find type 'Expense' in scope"

**原因**：Expense.swift 文件未正确添加到 Target

**解决方案**：
1. 在 Project Navigator 中选择 `Expense.swift`
2. 在右侧的 File Inspector 中
3. 确保 "Target Membership" 中勾选了 ✅ FoundationModelCounter

对其他文件重复此操作。

#### 错误："Module 'FoundationModels' not found"

**原因**：
- 部署目标低于 iOS 26.0
- 未添加 Foundation Models capability
- Xcode 版本过低

**解决方案**：
1. 确认部署目标为 iOS 26.0+
2. 添加 Foundation Models capability（见上文）
3. 更新到 Xcode 16.0+

#### 错误："Missing privacy usage description"

**原因**：未添加相机或相册权限说明

**解决方案**：
按照上文"添加权限说明"部分操作

## 🚀 运行项目

### 在模拟器上运行

1. 选择一个 iOS 26+ 的模拟器
2. 菜单栏：Product > Run
3. 或按快捷键：⌘R (Command + R)

**注意**：
- 模拟器可能不支持相机功能
- 可以使用相册选择图片功能
- FoundationModels 在模拟器上可能性能较慢

### 在真机上运行（推荐）

1. 连接 iOS 26+ 的设备
2. 选择该设备作为运行目标
3. 确保已配置代码签名：
   - Target > Signing & Capabilities
   - 勾选 "Automatically manage signing"
   - 选择你的 Team
4. 运行项目

**优势**：
- 可以使用相机拍照
- FoundationModels 性能更好
- 真实的用户体验

## 🧪 测试建议

### 1. 首次运行

- 确认应用成功启动
- 检查主界面显示正常
- 点击"+"按钮进入添加页面

### 2. 权限测试

- 首次点击"选择账单图片"会请求权限
- 确认权限提示文字正确显示
- 授予权限后能正常访问相册

### 3. OCR 测试

- 选择一张清晰的账单图片
- 等待识别完成
- 检查识别的文本是否准确

### 4. AI 分析测试

- 确认 AI 分析过程显示加载状态
- 检查自动填充的信息是否合理
- 测试手动修改功能

### 5. 数据持久化测试

- 添加几条账目
- 完全关闭应用
- 重新打开应用
- 确认数据仍然存在

## 📊 性能优化建议

### 在真机上测试性能

1. 菜单栏：Product > Profile (⌘I)
2. 选择 "Time Profiler"
3. 运行并使用应用
4. 检查性能瓶颈

### 监控内存使用

1. 运行应用
2. 打开 Debug Navigator (⌘7)
3. 查看 Memory 使用情况
4. 添加多张图片后检查是否有内存泄漏

## ❓ 常见问题

### Q: Xcode 显示"Uncommitted changes"

A: 这是正常的，因为我们添加了新文件。你可以：
- 提交更改到 Git
- 或继续开发

### Q: 编译时间很长

A: 首次编译会较慢，后续编译会快很多。可以：
- 使用增量编译
- 关闭不必要的 Preview

### Q: Preview 不工作

A: SwiftUI Preview 可能不支持 FoundationModels：
- 在真机或模拟器上测试
- 使用 Live Preview 功能

### Q: 找不到 Foundation Models capability

A: 确保：
- Xcode 16.0+
- iOS 26.0+
- 使用最新的 SDK

## 📚 下一步

完成集成后：

1. ✅ 阅读 [USAGE_GUIDE.md](USAGE_GUIDE.md) 了解如何使用
2. ✅ 查看 [README.md](README.md) 了解功能详情
3. ✅ 参考 [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) 理解技术实现
4. ✅ 开始使用应用进行记账！

## 🆘 需要帮助？

如果遇到问题：
1. 检查本文档的"常见问题"部分
2. 确认所有步骤都已正确完成
3. 查看 Xcode 的错误消息
4. 联系开发者

---

祝你集成顺利！🎉

