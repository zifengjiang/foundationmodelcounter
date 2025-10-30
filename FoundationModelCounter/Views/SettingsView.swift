//
//  SettingsView.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var config = AIConfiguration.shared
    @Bindable var themeManager = ThemeManager.shared
    
    @State private var showAPIKeyAlert = false
    @State private var tempAPIKey = ""
    @State private var showAPIKeyConfig = false
    @State private var showExportOptions = false
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
                        Text("人民币 (CNY)").tag("CNY")
                        Text("美元 (USD)").tag("USD")
                        Text("欧元 (EUR)").tag("EUR")
                        Text("日元 (JPY)").tag("JPY")
                        Text("英镑 (GBP)").tag("GBP")
                        Text("港币 (HKD)").tag("HKD")
                    }
                    
                    // 主题设置
                    Picker("外观主题", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                } header: {
                    Text("常规设置")
                }
                
                // 数据管理
                Section {
                    Button(action: { showExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 30)
                            Text("导出数据")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("数据管理")
                } footer: {
                    Text("导出您的账目数据为 CSV 或 JSON 格式")
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
            .confirmationDialog("导出数据", isPresented: $showExportOptions) {
                Button("导出为 CSV") {
                    exportAsCSV()
                }
                Button("导出为 JSON") {
                    exportAsJSON()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("选择导出格式")
            }
        }
    }
    
    private func exportAsCSV() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        // TODO: 实现 CSV 导出功能
        print("导出 CSV")
    }
    
    private func exportAsJSON() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        // TODO: 实现 JSON 导出功能
        print("导出 JSON")
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

