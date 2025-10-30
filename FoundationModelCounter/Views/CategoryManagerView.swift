//
//  CategoryManagerView.swift
//  FoundationModelCounter
//
//  Created on 2025/10/28.
//

import SwiftUI
import SwiftData

// MARK: - Main View

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
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var newMainCategory = ""
    @State private var newSubCategory = ""
    @State private var searchText = ""
    
    var filteredCategories: [Category] {
        categories.filter { $0.transactionType == selectedTransactionType.rawValue }
    }
    
    var groupedCategories: [(String, [Category])] {
        let filtered = searchText.isEmpty ? filteredCategories : filteredCategories.filter {
            $0.mainCategory.localizedCaseInsensitiveContains(searchText) ||
            $0.subCategory.localizedCaseInsensitiveContains(searchText)
        }
        
        let grouped = Dictionary(grouping: filtered) { $0.mainCategory }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 交易类型切换
                Picker("类型", selection: $selectedTransactionType) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    ForEach(groupedCategories, id: \.0) { mainCategory, subCategories in
                        Section(header: CategorySectionHeader(
                            mainCategory: mainCategory,
                            count: subCategories.count,
                            transactionType: selectedTransactionType
                        )) {
                            ForEach(subCategories) { category in
                                CategoryListItem(
                                    category: category,
                                    transactionType: selectedTransactionType,
                                    onTap: {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        editingCategory = category
                                        newMainCategory = category.mainCategory
                                        newSubCategory = category.subCategory
                                        showEditCategory = true
                                    }
                                )
                            }
                            .onDelete { indexSet in
                                deleteCategories(at: indexSet, from: subCategories)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("\(selectedTransactionType.rawValue)类目管理")
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
                transactionType: selectedTransactionType,
                mainCategory: $newMainCategory,
                subCategory: $newSubCategory,
                onSave: {
                    if !newMainCategory.isEmpty && !newSubCategory.isEmpty {
                        _ = CategoryService.shared.addOrUpdateCategory(
                            transactionType: selectedTransactionType,
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
                transactionType: selectedTransactionType,
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
            if filteredCategories.isEmpty {
                ContentUnavailableView(
                    "暂无\(selectedTransactionType.rawValue)类目",
                    systemImage: selectedTransactionType == .expense ? "cart" : "banknote",
                    description: Text("点击右上角 + 按钮添加\(selectedTransactionType.rawValue)类目")
                )
            }
        }
        
        
        
    }
    private func deleteCategories(at offsets: IndexSet, from categories: [Category]) {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        withAnimation {
            for index in offsets {
                let category = categories[index]
                modelContext.delete(category)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Helper Functions

func categoryColor(for mainCategory: String, transactionType: TransactionType) -> Color {
    let colorName = CategoryService.getMainCategoryColor(for: mainCategory, transactionType: transactionType)
    switch colorName {
    case "pink": return .pink
    case "orange": return .orange
    case "green": return .green
    case "blue": return .blue
    case "purple": return .purple
    default: return .gray
    }
}

// MARK: - Category Section Header

struct CategorySectionHeader: View {
    let mainCategory: String
    let count: Int
    let transactionType: TransactionType
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(categoryColor(for: mainCategory, transactionType: transactionType).opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: CategoryService.getMainCategoryIcon(for: mainCategory, transactionType: transactionType))
                    .foregroundStyle(categoryColor(for: mainCategory, transactionType: transactionType))
            }
            Text(mainCategory)
                .fontWeight(.semibold)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category List Item

struct CategoryListItem: View {
    let category: Category
    let transactionType: TransactionType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(categoryColor(for: category.mainCategory, transactionType: transactionType).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: CategoryService.getSubCategoryIcon(
                        for: category.mainCategory,
                        subCategory: category.subCategory,
                        transactionType: transactionType
                    ))
                    .foregroundStyle(categoryColor(for: category.mainCategory, transactionType: transactionType))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.subCategory)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if category.usageCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption2)
                            Text("使用 \(category.usageCount) 次")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // 使用次数徽章
                if category.usageCount > 0 {
                    Text("\(category.usageCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor(for: category.mainCategory, transactionType: transactionType).opacity(0.2))
                        .foregroundStyle(categoryColor(for: category.mainCategory, transactionType: transactionType))
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    let transactionType: TransactionType
    @Binding var mainCategory: String
    @Binding var subCategory: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var placeholderText: String {
        if transactionType == .expense {
            return "例如：衣、食、住、行"
        } else {
            return "例如：职薪、理财、经营"
        }
    }
    
    var footerText: String {
        if transactionType == .expense {
            return "支出大类建议：衣、食、住、行"
        } else {
            return "收入大类建议：职薪、理财、经营、其他"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(placeholderText, text: $mainCategory)
                } header: {
                    Text("大类")
                } footer: {
                    Text(footerText)
                }
                
                Section {
                    TextField(transactionType == .expense ? "例如：外卖、地铁、上衣" : "例如：工资薪金、投资收益", text: $subCategory)
                } header: {
                    Text("小类")
                } footer: {
                    Text(transactionType == .expense ? "输入具体的消费物品或用途" : "输入具体的收入来源")
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
            .navigationTitle("添加\(transactionType.rawValue)类目")
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
    let transactionType: TransactionType
    @Binding var mainCategory: String
    @Binding var subCategory: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var placeholderText: String {
        if transactionType == .expense {
            return "例如：衣、食、住、行"
        } else {
            return "例如：职薪、理财、经营"
        }
    }
    
    var footerText: String {
        if transactionType == .expense {
            return "支出大类建议：衣、食、住、行"
        } else {
            return "收入大类建议：职薪、理财、经营、其他"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(placeholderText, text: $mainCategory)
                } header: {
                    Text("大类")
                } footer: {
                    Text(footerText)
                }
                
                Section {
                    TextField(transactionType == .expense ? "例如：外卖、地铁、上衣" : "例如：工资薪金、投资收益", text: $subCategory)
                } header: {
                    Text("小类")
                } footer: {
                    Text(transactionType == .expense ? "输入具体的消费物品或用途" : "输入具体的收入来源")
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

