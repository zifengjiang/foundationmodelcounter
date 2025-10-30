# ZIP 解压依赖说明

## ⚠️ 重要提示

数据导入功能需要解压 ZIP 文件，但 iOS 没有提供原生的简单 ZIP 解压 API。我们需要添加一个 Swift Package 依赖。

## 📦 添加 ZIPFoundation 依赖

### 方法一：通过 Xcode 添加

1. 打开 `FoundationModelCounter.xcodeproj`
2. 选择项目文件（蓝色图标）
3. 选择 `FoundationModelCounter` target
4. 点击 "Package Dependencies" 标签页
5. 点击 "+" 按钮
6. 输入包 URL：
   ```
   https://github.com/weichsel/ZIPFoundation.git
   ```
7. 版本规则选择 "Up to Next Major Version"，输入 `0.9.0`
8. 点击 "Add Package"
9. 在弹出的对话框中，确保 `ZIPFoundation` 被添加到 `FoundationModelCounter` target
10. 点击 "Add Package"

### 方法二：手动编辑 project.pbxproj（高级）

如果您熟悉 Xcode 项目文件，可以直接添加 Swift Package 引用。

## 🔧 替代方案

### 如果不想添加依赖

如果您不想添加第三方依赖，有以下几种选择：

#### 1. 仅支持 macOS
在 iOS 上禁用导入功能，仅在 macOS 上使用 `Process` 调用 `unzip` 命令。

#### 2. 修改导出格式
不使用 ZIP 压缩，改为：
- 只导出 CSV（无图片）
- 使用 JSON 格式内嵌 Base64 图片

#### 3. 使用 Apple Archive 框架（iOS 14+）
手动实现解压逻辑（代码较复杂）。

## ✅ 推荐方案

**推荐使用 ZIPFoundation**，原因如下：

- ✅ 纯 Swift 实现
- ✅ 轻量级，无其他依赖
- ✅ 经过充分测试
- ✅ 被广泛使用
- ✅ MIT 许可证
- ✅ 积极维护

## 📚 ZIPFoundation 简介

ZIPFoundation 是一个轻量级的 Swift 库，用于创建、读取和解压 ZIP 归档文件。

### 基本用法

```swift
import ZIPFoundation

// 解压文件
try fileManager.unzipItem(at: sourceURL, to: destinationURL)

// 压缩文件
try fileManager.zipItem(at: sourceURL, to: destinationURL)
```

### 项目信息

- **GitHub**: https://github.com/weichsel/ZIPFoundation
- **Star**: 2.3k+
- **许可证**: MIT
- **最新版本**: 0.9.x

## 🚀 添加后的效果

添加依赖后，数据导入功能将完全可用：

- ✅ 解压导出的 ZIP 文件
- ✅ 读取 CSV 和图片
- ✅ 导入到数据库
- ✅ 去重处理
- ✅ 进度显示

## 🔍 故障排除

### 无法添加 Package

**问题**: Xcode 无法下载 Package  
**解决方案**: 
1. 检查网络连接
2. 确保 GitHub 访问正常
3. 尝试重启 Xcode
4. 清除 Package 缓存：`rm -rf ~/Library/Caches/org.swift.swiftpm`

### 编译错误

**问题**: 添加后编译失败  
**解决方案**:
1. 清理项目：Product → Clean Build Folder (Shift+Cmd+K)
2. 重新编译

## 📝 修改说明

已修改的文件：

- `DataImportService.swift` - 使用 ZIPFoundation 解压 ZIP 文件

关键代码：
```swift
import ZIPFoundation

try fileManager.unzipItem(at: url, to: destDir)
```

非常简洁！

