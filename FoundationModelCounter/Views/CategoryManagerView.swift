//
//  CategoryManagerView.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\Category.usageCount, order: .reverse),
        SortDescriptor(\Category.mainCategory),
        SortDescriptor(\Category.subCategory)
    ]) private var categories: [Category]
    
    @State private var showAddCategory = false
    @State private var showEditCategory = false
    @State private var editingCategory: Category?
    @State private var newMainCategory = ""
    @State private var newSubCategory = ""
    @State private var searchText = ""
    
    var groupedCategories: [(String, [Category])] {
        let filtered = searchText.isEmpty ? categories : categories.filter {
            $0.mainCategory.localizedCaseInsensitiveContains(searchText) ||
            $0.subCategory.localizedCaseInsensitiveContains(searchText)
        }
        
        let grouped = Dictionary(grouping: filtered) { $0.mainCategory }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedCategories, id: \.0) { mainCategory, subCategories in
                    Section(header: 
                        HStack {
                            Text(mainCategory)
                            Spacer()
                            Text("\(subCategories.count) 个小类")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    ) {
                        ForEach(subCategories) { category in
                            Button {
                                editingCategory = category
                                newMainCategory = category.mainCategory
                                newSubCategory = category.subCategory
                                showEditCategory = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category.subCategory)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        
                                        if category.usageCount > 0 {
                                            Text("使用 \(category.usageCount) 次")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteCategories(at: indexSet, from: subCategories)
                        }
                    }
                }
            }
            .navigationTitle("类目管理")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索类目")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddCategory = true }) {
                        Label("添加类目", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet(
                    mainCategory: $newMainCategory,
                    subCategory: $newSubCategory,
                    onSave: {
                        if !newMainCategory.isEmpty && !newSubCategory.isEmpty {
                            _ = CategoryService.shared.addOrUpdateCategory(
                                mainCategory: newMainCategory,
                                subCategory: newSubCategory,
                                context: modelContext
                            )
                            try? modelContext.save()
                            newMainCategory = ""
                            newSubCategory = ""
                        }
                        showAddCategory = false
                    },
                    onCancel: {
                        newMainCategory = ""
                        newSubCategory = ""
                        showAddCategory = false
                    }
                )
            }
            .sheet(isPresented: $showEditCategory) {
                EditCategorySheet(
                    category: editingCategory,
                    mainCategory: $newMainCategory,
                    subCategory: $newSubCategory,
                    onSave: {
                        if let category = editingCategory,
                           !newMainCategory.isEmpty && !newSubCategory.isEmpty {
                            category.mainCategory = newMainCategory
                            category.subCategory = newSubCategory
                            try? modelContext.save()
                            newMainCategory = ""
                            newSubCategory = ""
                            editingCategory = nil
                        }
                        showEditCategory = false
                    },
                    onCancel: {
                        newMainCategory = ""
                        newSubCategory = ""
                        editingCategory = nil
                        showEditCategory = false
                    }
                )
            }
            .overlay {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "暂无类目",
                        systemImage: "folder",
                        description: Text("点击右上角 + 按钮添加类目")
                    )
                }
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet, from categories: [Category]) {
        withAnimation {
            for index in offsets {
                let category = categories[index]
                modelContext.delete(category)
            }
            try? modelContext.save()
        }
    }
}

struct AddCategorySheet: View {
    @Binding var mainCategory: String
    @Binding var subCategory: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("例如：餐饮、交通、服饰", text: $mainCategory)
                } header: {
                    Text("大类")
                } footer: {
                    Text("输入生活类目，如：服饰、餐饮、交通等")
                }
                
                Section {
                    TextField("例如：外卖、地铁、上衣", text: $subCategory)
                } header: {
                    Text("小类")
                } footer: {
                    Text("输入具体的物品或用途")
                }
                
                Section {
                    Text("分类规则")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("使用实际用途分类", systemImage: "checkmark.circle.fill")
                        Label("禁止使用支付渠道做大类", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("添加类目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: onSave)
                        .disabled(mainCategory.isEmpty || subCategory.isEmpty)
                }
            }
        }
    }
}

struct EditCategorySheet: View {
    let category: Category?
    @Binding var mainCategory: String
    @Binding var subCategory: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("例如：餐饮、交通、服饰", text: $mainCategory)
                } header: {
                    Text("大类")
                } footer: {
                    Text("输入生活类目，如：服饰、餐饮、交通等")
                }
                
                Section {
                    TextField("例如：外卖、地铁、上衣", text: $subCategory)
                } header: {
                    Text("小类")
                } footer: {
                    Text("输入具体的物品或用途")
                }
                
                if let category = category, category.usageCount > 0 {
                    Section {
                        HStack {
                            Text("使用次数")
                            Spacer()
                            Text("\(category.usageCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Text("分类规则")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("使用实际用途分类", systemImage: "checkmark.circle.fill")
                        Label("禁止使用支付渠道做大类", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("编辑类目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: onSave)
                        .disabled(mainCategory.isEmpty || subCategory.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CategoryManagerView()
        .modelContainer(for: Category.self, inMemory: true)
}

