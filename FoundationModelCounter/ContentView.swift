//
//  ContentView.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: [SortDescriptor(\Category.usageCount, order: .reverse)]) private var categories: [Category]
    
    @State private var showAddExpense = false
    @State private var selectedCategory: String?
    @State private var showSettings = false
    @State private var showCategoryManager = false
    
    var filteredExpenses: [Expense] {
        if let category = selectedCategory {
            return expenses.filter { $0.mainCategory == category }
        }
        return expenses
    }
    
    var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var groupedExpenses: [(String, [Expense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            expense.date.formatted(date: .abbreviated, time: .omitted)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var availableMainCategories: [String] {
        let mainCats = Set(categories.map { $0.mainCategory })
        return Array(mainCats).sorted()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计卡片
                VStack(spacing: 12) {
                    HStack {
                        Text("总支出")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let category = selectedCategory {
                            Button(action: { selectedCategory = nil }) {
                                Label("显示全部", systemImage: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("¥")
                            .font(.title2)
                        Text(String(format: "%.2f", totalAmount))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    
                    // 分类筛选
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableMainCategories, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation {
                                        if selectedCategory == category {
                                            selectedCategory = nil
                                        } else {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                
                // 账目列表
                if filteredExpenses.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("暂无账目记录")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("点击右上角 + 按钮添加第一条账目")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.0) { date, expensesForDate in
                            Section(header: Text(date)) {
                                ForEach(expensesForDate) { expense in
                                    NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                        ExpenseRow(expense: expense)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteExpenses(offsets: offsets, from: expensesForDate)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("记账本")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showSettings = true }) {
                            Label("AI 设置", systemImage: "gearshape")
                        }
                        
                        Button(action: { showCategoryManager = true }) {
                            Label("类目管理", systemImage: "folder")
                        }
                    } label: {
                        Label("菜单", systemImage: "line.3.horizontal")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddExpense = true }) {
                        Label("添加账目", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showCategoryManager) {
                CategoryManagerView()
            }
            .onAppear {
                // 初始化默认类目
                CategoryService.shared.initializeDefaultCategories(context: modelContext)
            }
        }
    }

    private func deleteExpenses(offsets: IndexSet, from expenses: [Expense]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .foregroundStyle(categoryColor)
                    .font(.system(size: 20))
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.merchant.isEmpty ? expense.subCategory : expense.merchant)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(expense.mainCategory)
                    Text("·")
                    Text(expense.subCategory)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 金额
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", expense.amount))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                
                Text(expense.currency)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    var categoryColor: Color {
        switch expense.mainCategory {
        case "服饰": return .pink
        case "餐饮": return .orange
        case "交通": return .blue
        case "居家": return .green
        case "数码": return .purple
        case "医疗": return .red
        case "娱乐": return .cyan
        case "学习": return .indigo
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        switch expense.mainCategory {
        case "服饰": return "tshirt.fill"
        case "餐饮": return "fork.knife"
        case "交通": return "car.fill"
        case "居家": return "house.fill"
        case "数码": return "laptopcomputer"
        case "医疗": return "cross.case.fill"
        case "娱乐": return "gamecontroller.fill"
        case "学习": return "book.fill"
        default: return "ellipsis.circle.fill"
        }
    }
}

struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
}
