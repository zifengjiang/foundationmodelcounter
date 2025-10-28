//
//  SettingsView.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var config = AIConfiguration.shared
    
    @State private var showAPIKeyAlert = false
    @State private var tempAPIKey = ""
    
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
                        HStack {
                            Text("API Key")
                            Spacer()
                            if config.deepseekAPIKey.isEmpty {
                                Text("未配置")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("已配置")
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        Button("配置 API Key") {
                            tempAPIKey = config.deepseekAPIKey
                            showAPIKeyAlert = true
                        }
                        
                        if !config.deepseekAPIKey.isEmpty {
                            Button("清除 API Key", role: .destructive) {
                                config.deepseekAPIKey = ""
                            }
                        }
                    } header: {
                        Text("DeepSeek 配置")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("需要 DeepSeek API Key 才能使用该服务")
                            Link("获取 API Key", destination: URL(string: "https://platform.deepseek.com")!)
                        }
                    }
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
            .alert("配置 DeepSeek API Key", isPresented: $showAPIKeyAlert) {
                TextField("输入 API Key", text: $tempAPIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button("取消", role: .cancel) {
                    tempAPIKey = ""
                }
                
                Button("保存") {
                    config.deepseekAPIKey = tempAPIKey
                    tempAPIKey = ""
                }
            } message: {
                Text("请输入你的 DeepSeek API Key")
            }
        }
    }
}

#Preview {
    SettingsView()
}

