//
//  SettingsView.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var config = AIConfiguration.shared
    @Bindable var themeManager = ThemeManager.shared
    
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    
    @State private var showAPIKeyAlert = false
    @State private var tempAPIKey = ""
    @State private var showAPIKeyConfig = false
    @State private var showExportSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    
    @State private var showImportPicker = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var importResult: DataImportService.ImportResult?
    @State private var showImportResult = false
    
    @State private var progressMessage = ""
    @State private var progressValue: Double = 0.0
    @State private var showProgress = false
    
    @AppStorage("defaultCurrency") private var defaultCurrency = "CNY"
    
    var body: some View {
        NavigationView {
            Form {
                // AI 提供商选择
                Section {
                    ForEach(AIProvider.allCases) { provider in
                        Button {
                            config.currentProvider = provider
                        } label: {
                            HStack {
                                Image(systemName: provider.icon)
                                    .foregroundStyle(config.currentProvider == provider ? .blue : .secondary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(provider.rawValue)
                                        .foregroundStyle(.primary)
                                        .fontWeight(config.currentProvider == provider ? .semibold : .regular)
                                    
                                    Text(provider.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if config.currentProvider == provider {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("AI 提供商")
                } footer: {
                    Text("选择用于分析账单的 AI 服务")
                }
                
                // DeepSeek 配置
                if config.currentProvider == .deepseek {
                    Section {
                        NavigationLink {
                            APIKeyConfigView()
                        } label: {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 30)
                                Text("API Key")
                                Spacer()
                                if config.deepseekAPIKey.isEmpty {
                                    Text("未配置")
                                        .foregroundStyle(.secondary)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                        Text("已配置")
                                    }
                                    .foregroundStyle(.green)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } header: {
                        Text("DeepSeek 配置")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("需要 DeepSeek API Key 才能使用该服务")
                            Link("获取 API Key →", destination: URL(string: "https://platform.deepseek.com")!)
                                .font(.footnote)
                        }
                    }
                }
                
                // 常规设置
                Section {
                    // 默认货币
                    Picker("默认货币", selection: $defaultCurrency) {
                        ForEach(CurrencyCode.allCases, id: \.self) { currency in
                            Text("\(currency.name) (\(currency.rawValue))").tag(currency.rawValue)
                        }
                    }
                    
                    // 主题设置
                    Picker("外观主题", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                } header: {
                    Text("常规设置")
                } footer: {
                    Text("添加记账时，非默认货币会自动转换为默认货币进行存储")
                }
                
                // 数据管理
                Section {
                    // 导入数据
                    Button(action: { 
                        showImportPicker = true
                    }) {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .frame(width: 30)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 30)
                            }
                            Text("导入数据")
                                .foregroundStyle(.primary)
                            Spacer()
                            if !isImporting {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .disabled(isImporting)
                    
                    // 导出数据
                    Button(action: { 
                        Task {
                            await exportData()
                        }
                    }) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .frame(width: 30)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 30)
                            }
                            Text("导出数据")
                                .foregroundStyle(.primary)
                            Spacer()
                            if !isExporting {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .disabled(isExporting || expenses.isEmpty)
                    
                    if expenses.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("暂无数据可导出")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("数据管理")
                } footer: {
                    Text("导入或导出账目数据，当前共 \(expenses.count) 条记录")
                }
                
                // 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.zip],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleImportFile(result: result)
                }
            }
            .alert("导出失败", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("确定", role: .cancel) {
                    exportError = nil
                }
            } message: {
                if let error = exportError {
                    Text(error)
                }
            }
            .alert("导入失败", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("确定", role: .cancel) {
                    importError = nil
                }
            } message: {
                if let error = importError {
                    Text(error)
                }
            }
            .alert("导入完成", isPresented: $showImportResult) {
                Button("确定", role: .cancel) { }
            } message: {
                if let result = importResult {
                    Text("总计：\(result.totalCount) 条\n成功：\(result.importedCount) 条\n跳过：\(result.skippedCount) 条\n失败：\(result.failedCount) 条")
                }
            }
            .progressToast(
                isPresented: $showProgress,
                message: progressMessage,
                progress: progressValue
            )
        }
    }
    
    // MARK: - 导出数据
    
    private func exportData() async {
        isExporting = true
        exportError = nil
        
        await MainActor.run {
            showProgress = true
            progressMessage = "准备导出..."
            progressValue = 0.0
        }
        
        do {
            let url = try await DataExportService.shared.exportData(expenses: expenses) { message, progress in
                Task { @MainActor in
                    progressMessage = message
                    progressValue = progress
                }
            }
            
            await MainActor.run {
                showProgress = false
                exportedFileURL = url
                showExportSheet = true
                isExporting = false
                
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                showProgress = false
                exportError = "导出失败：\(error.localizedDescription)"
                isExporting = false
                
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.error)
            }
        }
    }
    
    // MARK: - 导入数据
    
    private func handleImportFile(result: Result<[URL], Error>) async {
        isImporting = true
        importError = nil
        
        await MainActor.run {
            showProgress = true
            progressMessage = "准备导入..."
            progressValue = 0.0
        }
        
        do {
            guard let fileURL = try result.get().first else {
                throw NSError(domain: "SettingsView", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "未选择文件"])
            }
            
            // 开始访问安全范围资源
            guard fileURL.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "SettingsView", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "无法访问文件"])
            }
            
            defer {
                fileURL.stopAccessingSecurityScopedResource()
            }
            
            let result = try await DataImportService.shared.importData(from: fileURL, context: modelContext) { message, progress in
                Task { @MainActor in
                    progressMessage = message
                    progressValue = progress
                }
            }
            
            await MainActor.run {
                showProgress = false
                importResult = result
                showImportResult = true
                isImporting = false
                
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                showProgress = false
                importError = "导入失败：\(error.localizedDescription)"
                isImporting = false
                
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.error)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - API Key Config View

struct APIKeyConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var config = AIConfiguration.shared
    @State private var apiKey: String = ""
    @State private var showDeleteAlert = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        if !config.deepseekAPIKey.isEmpty {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical)
                    
                    Text("API Key 配置")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("请输入您的 DeepSeek API Key 以启用 AI 账单分析功能")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                SecureField("sk-xxxxxxxxxxxxxxxx", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: apiKey) { _, newValue in
                        config.deepseekAPIKey = newValue
                    }
                    .onAppear {
                        apiKey = config.deepseekAPIKey
                    }
            } header: {
                Text("API Key")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("您的 API Key 将安全存储在设备本地，不会上传到任何服务器")
                        .font(.caption)
                    
                    Link("如何获取 API Key？", destination: URL(string: "https://platform.deepseek.com")!)
                        .font(.caption)
                }
            }
            
            if !config.deepseekAPIKey.isEmpty {
                Section {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除 API Key")
                        }
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "doc.text.viewfinder",
                        title: "智能识别",
                        description: "自动识别账单中的金额、商户、日期等信息"
                    )
                    
                    Divider()
                    
                    FeatureRow(
                        icon: "brain",
                        title: "智能分类",
                        description: "AI 自动为账目分配合适的类别"
                    )
                    
                    Divider()
                    
                    FeatureRow(
                        icon: "lock.shield",
                        title: "隐私保护",
                        description: "所有数据仅在设备本地处理"
                    )
                }
            } header: {
                Text("功能特性")
            }
        }
        .navigationTitle("API Key 配置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("清除 API Key", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                config.deepseekAPIKey = ""
                apiKey = ""
                dismiss()
            }
        } message: {
            Text("确定要清除已保存的 API Key 吗？")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}

