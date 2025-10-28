# 项目配置指南

## 1. 添加权限说明

在 Xcode 项目中配置以下权限：

### 方法 A：通过 Xcode UI 配置

1. 在 Xcode 中打开项目
2. 选择项目根节点
3. 选择 Target "FoundationModelCounter"
4. 点击 "Info" 标签页
5. 添加以下键值对：

| Key | Type | Value |
|-----|------|-------|
| Privacy - Camera Usage Description | String | 需要访问相机来拍摄账单 |
| Privacy - Photo Library Usage Description | String | 需要访问相册来选择账单图片 |

### 方法 B：编辑 Info.plist

如果项目有 Info.plist 文件，添加以下内容：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机来拍摄账单</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择账单图片</string>
```

## 2. 启用 FoundationModels 功能

### 在 Xcode 中配置：

1. 选择 Target "FoundationModelCounter"
2. 点击 "Signing & Capabilities" 标签页
3. 点击 "+ Capability"
4. 搜索并添加 "Foundation Models"

注意：FoundationModels 需要 iOS 26.0+ 和支持的设备。

## 3. 确认部署目标

1. 在 Target 设置中，确保 "Deployment Target" 设置为 iOS 26.0 或更高
2. 在需要的设备或模拟器上测试（确保支持 iOS 26）

## 4. 构建项目

```bash
# 在终端中执行
cd /Users/didi/Documents/FoundationModelCounter
xcodebuild -scheme FoundationModelCounter -configuration Debug
```

或者在 Xcode 中按 ⌘+B 构建项目。

## 5. 运行项目

1. 选择目标设备或模拟器
2. 按 ⌘+R 运行项目

## 常见问题

### Q: 编译错误 "FoundationModels module not found"
A: 确保部署目标设置为 iOS 26.0+，并在支持的设备上测试。

### Q: 相机/相册权限弹窗不显示
A: 确保已添加权限说明到 Info.plist 或项目 Info 配置中。

### Q: OCR 识别不准确
A: 
- 确保图片清晰
- 光线充足
- 文字清晰可见
- 支持中英文混合识别

### Q: AI 分析结果不准确
A: 
- AI 提取的信息可以手动修改
- 识别准确性取决于账单格式和文字清晰度
- 建议在保存前检查并修正提取的信息

## 测试建议

1. **测试 OCR**：使用清晰的账单图片测试文字识别
2. **测试 AI 分析**：尝试不同类型的账单（餐饮、购物等）
3. **测试数据持久化**：添加账目后重启应用，确认数据已保存
4. **测试分类筛选**：添加多个不同类别的账目，测试筛选功能
5. **测试删除功能**：确认删除操作正常工作

## 开发注意事项

- FoundationModels 在设备端运行，不需要网络连接
- 首次运行可能需要下载模型到设备
- 处理大型图片时可能需要较长时间
- 建议在真机上测试以获得最佳性能

