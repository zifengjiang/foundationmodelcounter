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
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var selectedCategory: String?
    @State private var showSettings = false
    @State private var showCategoryManager = false
    @State private var selectedMonth: Date = Date() // 默认选择当月
    
    // 当月的起止日期
    var currentMonthRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        let startOfMonth = calendar.date(from: components)!
        // 下个月第一天（作为结束边界）
        let nextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth)!
        return (startOfMonth, nextMonth)
    }
    
    // 当月的所有记录
    var currentMonthExpenses: [Expense] {
        let range = currentMonthRange
        return expenses.filter { expense in
            // 大于等于月初 且 小于下月初（这样可以包含整个月的所有时间）
            expense.date >= range.start && expense.date < range.end
        }
    }
    
    var filteredExpenses: [Expense] {
        // 先按月份过滤
        var result = currentMonthExpenses.filter { $0.transactionType == selectedTransactionType.rawValue }
        if let category = selectedCategory {
            result = result.filter { $0.mainCategory == category }
        }
        return result
    }
    
    var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 当月收入总额
    var totalIncome: Double {
        currentMonthExpenses
            .filter { $0.transactionType == TransactionType.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 当月支出总额
    var totalExpense: Double {
        currentMonthExpenses
            .filter { $0.transactionType == TransactionType.expense.rawValue }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 当月余额
    var balance: Double {
        totalIncome - totalExpense
    }
    
    // 格式化月份显示
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        let calendar = Calendar.current
        
        // 判断是否为当月
        if calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
            return "本月"
        } else {
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: selectedMonth)
        }
    }
    
    // 判断是否可以前进到下个月
    var canGoToNextMonth: Bool {
        let calendar = Calendar.current
        return !calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }
    
    var groupedExpenses: [(String, [Expense])] {
        // 按日期分组，使用中文格式
        let grouped = Dictionary(grouping: filteredExpenses) { expense -> String in
            // 创建中文日期格式化器
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            // 判断是否为今天、昨天、前天
            let calendar = Calendar.current
            if calendar.isDateInToday(expense.date) {
                return "今天"
            } else if calendar.isDateInYesterday(expense.date) {
                return "昨天"
            } else if let daysAgo = calendar.dateComponents([.day], from: expense.date, to: Date()).day,
                      daysAgo == 2 {
                return "前天"
            }
            
            return formatter.string(from: expense.date)
        }
        
        // 按日期倒序排序（最新的在前）
        return grouped.sorted { pair1, pair2 in
            // 获取每组中最新的日期进行比较
            let date1 = pair1.value.map { $0.date }.max() ?? Date.distantPast
            let date2 = pair2.value.map { $0.date }.max() ?? Date.distantPast
            return date1 > date2
        }
    }
    
    var availableMainCategories: [String] {
        let mainCats = Set(categories
            .filter { $0.transactionType == selectedTransactionType.rawValue }
            .map { $0.mainCategory })
        return Array(mainCats).sorted()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计卡片
                VStack(spacing: 12) {
                    // 月份选择器
                    HStack {
                        Button(action: goToPreviousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        Text(monthTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: goToNextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundStyle(canGoToNextMonth ? .primary : .secondary)
                        }
                        .disabled(!canGoToNextMonth)
                    }
                    .padding(.bottom, 12)
                    
                    // 总览统计（收入、支出、余额）
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("收入")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", totalIncome))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("支出")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", totalExpense))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("余额")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", balance))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(balance >= 0 ? .green : .red)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // 交易类型切换
                    HStack {
                        Picker("交易类型", selection: $selectedTransactionType) {
                            Text("支出").tag(TransactionType.expense)
                            Text("收入").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedTransactionType) { oldValue, newValue in
                            selectedCategory = nil // 切换类型时清除分类筛选
                        }
                        
                        if let category = selectedCategory {
                            Button(action: { selectedCategory = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 当前类型的金额
                    HStack(alignment: .firstTextBaseline) {
                        Text("¥")
                            .font(.title2)
                        Text(String(format: "%.2f", totalAmount))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Spacer()
                        Text(selectedTransactionType.rawValue)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 分类筛选
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableMainCategories, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    transactionType: selectedTransactionType
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
                        Image(systemName: selectedTransactionType == .expense ? "cart" : "banknote")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("暂无\(selectedTransactionType.rawValue)记录")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("点击右上角 + 按钮添加第一条记录")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.0) { date, expensesForDate in
                            Section {
                                ForEach(expensesForDate) { expense in
                                    NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                        ExpenseRow(expense: expense)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteExpenses(offsets: offsets, from: expensesForDate)
                                }
                            } header: {
                                DaySummaryHeader(
                                    date: date,
                                    expenses: expensesForDate,
                                    selectedType: selectedTransactionType
                                )
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
                        Label("添加记录", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(defaultTransactionType: selectedTransactionType)
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
    
    // 前往上个月
    private func goToPreviousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            withAnimation {
                selectedMonth = newDate
                selectedCategory = nil // 切换月份时清除分类筛选
            }
        }
    }
    
    // 前往下个月
    private func goToNextMonth() {
        guard canGoToNextMonth else { return }
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            withAnimation {
                selectedMonth = newDate
                selectedCategory = nil // 切换月份时清除分类筛选
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var transactionType: TransactionType {
        TransactionType(rawValue: expense.transactionType) ?? .expense
    }
    
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
                    Text("·")
                    Text(formatTime(expense.date))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 金额
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    Text(transactionType == .income ? "+" : "-")
                        .foregroundStyle(transactionType == .income ? .green : .red)
                    Text(String(format: "%.2f", expense.amount))
                        .foregroundStyle(transactionType == .income ? .green : .primary)
                }
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
        let colorName = CategoryService.getMainCategoryColor(for: expense.mainCategory, transactionType: transactionType)
        switch colorName {
        case "pink": return .pink
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        // 优先使用小类图标，提供更精确的视觉反馈
        return CategoryService.getSubCategoryIcon(
            for: expense.mainCategory,
            subCategory: expense.subCategory,
            transactionType: transactionType
        )
    }
    
    // 格式化时间显示
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Day Summary Header

struct DaySummaryHeader: View {
    let date: String
    let expenses: [Expense]
    let selectedType: TransactionType
    
    // 计算当天的收入和支出
    var dayIncome: Double {
        expenses
            .filter { $0.transactionType == TransactionType.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }
    
    var dayExpense: Double {
        expenses
            .filter { $0.transactionType == TransactionType.expense.rawValue }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // 日期
            Text(date)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // 显示当天的收支统计
            HStack(spacing: 12) {
                // 收入
                if dayIncome > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("收入")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", dayIncome))
                            .font(.subheadline)
                            .fontWeight(selectedType == .income ? .bold : .semibold)
                            .foregroundStyle(.green)
                    }
                }
                
                // 支出
                if dayExpense > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("支出")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", dayExpense))
                            .font(.subheadline)
                            .fontWeight(selectedType == .expense ? .bold : .semibold)
                            .foregroundStyle(.red)
                    }
                }
                
                // 净额（如果两种类型都有）
                if dayIncome > 0 && dayExpense > 0 {
                    let balance = dayIncome - dayExpense
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("净额")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%+.2f", balance))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(balance >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let transactionType: TransactionType
    let action: () -> Void
    
    var chipColor: Color {
        if isSelected {
            return Color.accentColor
        }
        let colorName = CategoryService.getMainCategoryColor(for: category, transactionType: transactionType)
        switch colorName {
        case "pink": return .pink.opacity(0.2)
        case "orange": return .orange.opacity(0.2)
        case "green": return .green.opacity(0.2)
        case "blue": return .blue.opacity(0.2)
        case "purple": return .purple.opacity(0.2)
        default: return Color(.systemGray5)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: CategoryService.getMainCategoryIcon(for: category, transactionType: transactionType))
                    .font(.caption)
                Text(category)
                    .font(.subheadline)
            }
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(chipColor)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
}
