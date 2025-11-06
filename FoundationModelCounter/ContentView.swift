    //
    //  ContentView.swift
    //  FoundationModelCounter
    //
    //  Created by didi on 2025/10/28.
    //

import SwiftUI
import SwiftData
import Photos

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
    @State private var dragOffset: CGFloat = 0
    @State private var searchText = ""
        // path - 使用显式的 Expense 数组类型，方便访问当前导航的 expense
    @State private var navigationPath: [Expense] = []
    @FocusState private var isKeyboardActive: Bool

        // 分期删除相关状态
    @State private var expenseToDelete: Expense?
    @State private var showInstallmentDeleteOptions = false
    @State private var showDeleteConfirmation = false

    @State private var showAddMenu = false
    @State private var showRightMenu = false
    @Namespace private var animation
    
    // 快速记账相关状态
    @State private var isQuickAddingExpense = false
    @AppStorage("defaultCurrency") private var defaultCurrency = "CNY"
    
    // ExpenseDetailView 的 ViewModel
    @State private var detailViewModel: ExpenseDetailViewModel?

        // 获取当前导航堆栈顶部的 expense（即当前详情页显示的 expense）
    var currentDetailExpense: Expense? {
        return navigationPath.last
    }

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

            // 按分类过滤
        if let category = selectedCategory {
            result = result.filter { $0.mainCategory == category }
        }

            // 按搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter { expense in
                expense.merchant.localizedCaseInsensitiveContains(searchText) ||
                expense.note.localizedCaseInsensitiveContains(searchText) ||
                expense.mainCategory.localizedCaseInsensitiveContains(searchText) ||
                expense.subCategory.localizedCaseInsensitiveContains(searchText)
            }
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

        // 判断是否为未来月份
    var isFutureMonth: Bool {
        let calendar = Calendar.current
        let today = Date()
        return selectedMonth > today
    }

        // 当前月份有多少分期账单
    var installmentCount: Int {
        currentMonthExpenses.filter { $0.isInstallment }.count
    }

        // 判断是否可以前进到下个月（允许查看未来月份，用于查看分期账单）
    var canGoToNextMonth: Bool {
        let calendar = Calendar.current
            // 允许查看未来12个月（方便查看分期账单）
        let maxFutureMonth = calendar.date(byAdding: .month, value: 12, to: Date())!
        return selectedMonth < maxFutureMonth
    }

        // 判断是否为当前月份
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
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
        NavigationStack(path: $navigationPath) {
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

                            // 显示月份，如果不是当月则添加"回到本月"按钮
                        if isCurrentMonth {
                            HStack(spacing: 6) {
                                Text(monthTitle)
                                    .font(.title3)
                                    .fontWeight(.bold)

                                    // 如果有分期账单，显示标识
                                if installmentCount > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "creditcard")
                                            .font(.system(size: 10))
                                        Text("\(installmentCount)")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                }
                            }
                        } else {
                            HStack(spacing: 6) {
                                Text(monthTitle)
                                    .font(.title3)
                                    .fontWeight(.bold)

                                    // 未来月份标识
                                if isFutureMonth {
                                    Text("未来")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }

                                    // 如果有分期账单，显示标识
                                if installmentCount > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "creditcard")
                                            .font(.system(size: 10))
                                        Text("\(installmentCount)")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                }
                                Button(action: goToCurrentMonth) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(.caption2)
                                        Text("回到本月")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.blue)
                                }
                            }

                        }

                        Spacer()

                        Button(action: goToNextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundStyle(canGoToNextMonth ? .primary : .secondary)
                        }
                        .disabled(!canGoToNextMonth)
                    }
                    .padding(.bottom, 12)

                        // 总览统计（收入、支出、余额）- 优化为网格布局
                    HStack(spacing: 0) {
                        StatCard(
                            title: "收入",
                            amount: totalIncome,
                            color: .green,
                            icon: "arrow.down.circle.fill"
                        )

                        Divider()
                            .frame(height: 50)

                        StatCard(
                            title: "支出",
                            amount: totalExpense,
                            color: .red,
                            icon: "arrow.up.circle.fill"
                        )

                        Divider()
                            .frame(height: 50)

                        StatCard(
                            title: "余额",
                            amount: balance,
                            color: balance >= 0 ? .green : .red,
                            icon: balance >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                        )
                    }
                    .padding(.bottom, 8)

                    Divider()

                        // 交易类型切换和搜索按钮
                    HStack {
                        Picker("交易类型", selection: $selectedTransactionType) {
                            Text("支出").tag(TransactionType.expense)
                            Text("收入").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedTransactionType) { oldValue, newValue in
                            selectedCategory = nil // 切换类型时清除分类筛选
                        }


                        if let _ = selectedCategory {
                            Button(action: { selectedCategory = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)


                        // 当前类型的金额
                    HStack(alignment: .bottom, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("¥")
                                .font(.title2)
                            Text(String(format: "%.2f", totalAmount))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                // 账单数量统计
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .font(.caption)
                                    Text("共 \(filteredExpenses.count) 笔")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(selectedTransactionType.rawValue)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                    }

                        // 分类筛选 - 添加渐变遮罩
                    if !availableMainCategories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableMainCategories, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        transactionType: selectedTransactionType
                                    ) {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        withAnimation(.spring(response: 0.3)) {
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
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.05),
                                    .init(color: .black, location: 0.95),
                                    .init(color: .clear, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width < -threshold {
                                    // 向左滑动，前往下个月
                                goToNextMonth()
                            } else if value.translation.width > threshold {
                                    // 向右滑动，前往上个月
                                goToPreviousMonth()
                            }
                            dragOffset = 0
                        }
                )

                    // 账目列表
                if filteredExpenses.isEmpty {
                    if !searchText.isEmpty {
                        SearchEmptyView(searchText: searchText)
                    } else {
                        EmptyStateView(transactionType: selectedTransactionType)
                    }
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.0) { date, expensesForDate in
                            Section {
                                ForEach(expensesForDate) { expense in
                                    NavigationLink(value: expense) {
                                        ExpenseRow(expense: expense)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button{
                                            expenseToDelete = expense
                                            if let expense = expenseToDelete {
                                                if expense.isInstallment {
                                                    showInstallmentDeleteOptions = true
                                                } else {
                                                    showDeleteConfirmation = true
                                                }
                                            }
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                        .foregroundStyle(.white)
                                        .background(.red)
                                    }
                                }

//                                .onDelete { offsets in
//                                    deleteExpenses(offsets: offsets, from: expensesForDate)
//                                }
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
                    .safeAreaBar(edge: .bottom, spacing: 0) {
                        Text(".")
                            .blendMode(.destinationOut)
                            .frame(height: 70)
                    }
                }
            }
            .navigationDestination(for: Expense.self) { expense in
                let viewModel = ExpenseDetailViewModel()
                
                ExpenseDetailView(expense: expense, viewModel: viewModel)
                    .onAppear {
                        viewModel.setup(with: expense)
                        detailViewModel = viewModel
                        
                    }
                    .onDisappear {
                        detailViewModel = nil
                    }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(defaultTransactionType: selectedTransactionType)
                    .navigationTransition(.zoom(sourceID: "filter", in: animation))
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .navigationTransition(.zoom(sourceID: "setting", in: animation))
            }
            .sheet(isPresented: $showCategoryManager) {
                CategoryManagerView()
            }

            .onAppear {
                    // 初始化默认类目
                CategoryService.shared.initializeDefaultCategories(context: modelContext)
            }
        }

        .overlay(alignment: .bottom) {
            CustomBottomBar(
                path: $navigationPath,
                searchText: $searchText,
                isKeyboardActive: $isKeyboardActive,
                leftMenuExpanded: $showAddMenu,
                rightMenuExpanded: $showAddMenu
            ) { isExpanded in

                Group {
                    ZStack {
                        // 设置按钮 - 在列表页显示
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                                .contentTransition(.symbolEffect)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(.circle)
                                .matchedTransitionSource(id: "setting", in: animation)
                        }
                        .foregroundStyle(.primary)
                        .blurFade(!isExpanded)
                        
                        Button(action: {
                            
                            if let viewModel = detailViewModel, let hasChanges = detailViewModel?.hasChanges, hasChanges {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                saveExpenseFromDetail(viewModel: viewModel)
                            }else{
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }
                        }) {
                            Image(systemName: detailViewModel?.hasChanges ?? false ? "checkmark" : "square.and.arrow.down.fill")
                                .font(.title2)
                                .contentTransition(.symbolEffect)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(.circle)
                                .transition(.symbolEffect(.drawOn.individually))
                        }
                        .foregroundStyle(.primary)
                        .blurFade(isExpanded)
//                        .disabled(detailViewModel?.amount.isEmpty ?? true)
                    }

                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()

                            // 移除当前详情页的账单
                        if let expense = currentDetailExpense {
                            expenseToDelete = expense
                                // 显示确认对话框
                            showDeleteConfirmation = true
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .contentTransition(.symbolEffect)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(.circle)
                    }
                    .foregroundStyle(.primary)
                    .blurFade(isExpanded)
                    .alert("确认删除", isPresented: $showDeleteConfirmation) {
                        if let expense = expenseToDelete {
                            Button("删除", role: .destructive) {
                                    // 如果是分期账单，显示删除选项
                                if expense.isInstallment {
                                    showInstallmentDeleteOptions = true
                                } else {
                                        // 直接删除非分期账单
                                    withAnimation {
                                        modelContext.delete(expense)
                                        try? modelContext.save()
                                    }
                                        // 返回到列表页
                                    if navigationPath.last?.id == expense.id {
                                        navigationPath.removeLast()
                                    }
                                    expenseToDelete = nil
                                }
                            }

                            Button("取消", role: .cancel) {
                                expenseToDelete = nil
                            }
                        }
                    } message: {
                        if let expense = expenseToDelete {
                            if expense.isInstallment {
                                Text("确定要删除这笔分期账单吗？")
                            } else {
                                Text("确定要删除这笔账单吗？此操作无法撤销。")
                            }
                        }
                    }


                }
                .font(.title2)
            } trailingContent: { isExpanded in
                if (!isExpanded){
                    Group {
                        if showAddMenu {
                            // 快速记账按钮（从相册获取最新图片）
                            Button(action: {
                                if !isQuickAddingExpense {
                                    quickAddExpense()
                                }
                            }) {
                                Group {
                                    if isQuickAddingExpense {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                    } else {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title2)
                                            .contentTransition(.symbolEffect)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(.circle)
                            }
                            .foregroundStyle(.primary)
                            .disabled(isQuickAddingExpense)
                            .accessibilityLabel("快速记账")
                            
                            // 普通添加按钮
                            Button(action: {
                                if isKeyboardActive {
                                    isKeyboardActive = false
                                } else {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    withAnimation(.spring(response: 0.3)) {
                                        showAddExpense = true
                                    }
                                }
                            }) {
                                Image(systemName: "pencil")
                                    .font(.title2)
                                    .contentTransition(.symbolEffect)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(.circle)
                                    .matchedTransitionSource(id: "filter", in: animation)
                            }
                            .foregroundStyle(.primary)
                        }
                        
                        // 菜单切换按钮
                        Button(action: {
                            if isKeyboardActive {
                                isKeyboardActive = false
                            } else {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                withAnimation(.spring(response: 0.3)) {
                                    showAddMenu.toggle()
                                }
                            }
                        }) {
                            Image(systemName: isKeyboardActive ? "xmark" : showAddMenu ? "xmark": "plus")
                                .font(.title2)
                                .contentTransition(.symbolEffect)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(.circle)
                                .matchedTransitionSource(id: "filter", in: animation)
                        }
                        .foregroundStyle(.primary)
                        .accessibilityLabel("添加\(selectedTransactionType.rawValue)记录")
                    }
                    .font(.title2)
                }
            }
            .padding(.bottom, 8)
        }
        .alert("删除分期账单", isPresented: $showInstallmentDeleteOptions) {
            if let expense = expenseToDelete {
                Button("仅删除当前这一期", role: .destructive) {
                    deleteCurrentInstallment()
                }

                Button("删除全部分期", role: .destructive) {
                    deleteAllInstallments()
                }

                    // 只有当前不是最后一期时，才显示提前还清选项
                if expense.installmentNumber < expense.installmentPeriods {
                    Button("提前还清（删除未来期数）", role: .destructive) {
                        earlyPayoff()
                    }
                }

                Button("取消", role: .cancel) {
                    expenseToDelete = nil
                }
            }
        } message: {
            if let expense = expenseToDelete {
                Text("这是第\(expense.installmentNumber)/\(expense.installmentPeriods)期分期账单，请选择删除方式")
            }
        }
    }

    private func deleteExpenses(offsets: IndexSet, from expenses: [Expense]) {
            // 检查是否包含分期账单
        let expensesToDelete = offsets.map { expenses[$0] }

            // 如果只有一个账单且是分期账单，显示选项对话框
        if expensesToDelete.count == 1, let expense = expensesToDelete.first {
            expenseToDelete = expense
            if expense.isInstallment {
                showInstallmentDeleteOptions = true
            } else {
                showDeleteConfirmation = true
            }
        }
    }

        // MARK: - 分期删除方法

        /// 仅删除当前这一期
    private func deleteCurrentInstallment() {
        guard let expense = expenseToDelete else { return }
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        withAnimation {
            modelContext.delete(expense)
            try? modelContext.save()
        }
            // 如果在详情页中删除，返回到列表页
        if navigationPath.last?.id == expense.id {
            navigationPath.removeLast()
        }
        expenseToDelete = nil
    }

        /// 删除全部分期
    private func deleteAllInstallments() {
        guard let expense = expenseToDelete else { return }
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

            // 获取所有相关的分期账单
        let relatedExpenses = getAllRelatedInstallments(for: expense)

        withAnimation {
                // 删除所有相关账单
            for relatedExpense in relatedExpenses {
                modelContext.delete(relatedExpense)
            }
            try? modelContext.save()
        }
            // 如果在详情页中删除，返回到列表页
        if navigationPath.last?.id == expense.id {
            navigationPath.removeLast()
        }
        expenseToDelete = nil
    }

        /// 提前还清（删除未来期数，将剩余金额合并到当前期）
    private func earlyPayoff() {
        guard let expense = expenseToDelete else { return }
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

            // 获取所有相关的分期账单
        let relatedExpenses = getAllRelatedInstallments(for: expense)

            // 筛选出未来的期数（大于当前期数的）
        let futureInstallments = relatedExpenses.filter { $0.installmentNumber > expense.installmentNumber }

            // 计算未来期数的总金额
        let futureAmount = futureInstallments.reduce(0.0) { $0 + $1.amount }

        withAnimation {
                // 将当前期的金额增加未来期数的金额
            expense.amount += futureAmount
            expense.note = expense.note.replacingOccurrences(of: "第\(expense.installmentNumber)/\(expense.installmentPeriods)期", with: "已提前还清")

                // 删除所有未来期数
            for futureExpense in futureInstallments {
                modelContext.delete(futureExpense)
            }
            try? modelContext.save()
        }
            // 提前还清后，当前账单仍然存在，不需要返回列表页
        expenseToDelete = nil
    }

        /// 获取所有相关的分期账单
    private func getAllRelatedInstallments(for expense: Expense) -> [Expense] {
            // 如果是第一期（父账单）
        if expense.parentExpenseId == nil && expense.installmentNumber == 1 {
                // 查找所有子账单
            return self.expenses.filter { $0.parentExpenseId == expense.id || $0.id == expense.id }
        } else {
                // 如果是子账单，通过 parentExpenseId 查找所有相关账单
            if let parentId = expense.parentExpenseId {
                return self.expenses.filter { $0.parentExpenseId == parentId || $0.id == parentId }
            }
        }

        return [expense]
    }

        // 前往上个月
    private func goToPreviousMonth() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            withAnimation(.spring(response: 0.3)) {
                selectedMonth = newDate
                selectedCategory = nil // 切换月份时清除分类筛选
            }
        }
    }

        // 前往下个月
    private func goToNextMonth() {
        guard canGoToNextMonth else { return }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            withAnimation(.spring(response: 0.3)) {
                selectedMonth = newDate
                selectedCategory = nil // 切换月份时清除分类筛选
            }
        }
    }

        // 回到当前月份
    private func goToCurrentMonth() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.3)) {
            selectedMonth = Date()
            selectedCategory = nil // 切换月份时清除分类筛选
        }
    }
    
    // MARK: - 详情页保存功能
    
    /// 从详情页保存账目
    private func saveExpenseFromDetail(viewModel: ExpenseDetailViewModel) {
        guard let expense = viewModel.expense else { return }
        guard let amountValue = Double(viewModel.amount) else {
            viewModel.errorMessage = "请输入有效的金额"
            return
        }
        
        // 更新或添加类目
        if !viewModel.mainCategory.isEmpty && !viewModel.subCategory.isEmpty {
            _ = CategoryService.shared.addOrUpdateCategory(
                transactionType: viewModel.transactionType,
                mainCategory: viewModel.mainCategory,
                subCategory: viewModel.subCategory,
                context: modelContext
            )
        }
        
        // 判断是否要将普通账单转换为分期账单
        if viewModel.enableInstallment && !expense.isInstallment && viewModel.transactionType == .expense && viewModel.installmentPeriods > 0 {
            // 删除原账单
            modelContext.delete(expense)
            
            // 创建分期账单
            createInstallmentExpensesFromDetail(
                viewModel: viewModel,
                totalAmount: amountValue
            )
        } else {
            // 更新账目信息
            expense.transactionType = viewModel.transactionType.rawValue
            expense.date = viewModel.date
            
            // 分期账单不允许修改金额
            if !expense.isInstallment {
                expense.amount = amountValue
            }
            
            expense.currency = viewModel.currency
            expense.mainCategory = viewModel.mainCategory
            expense.subCategory = viewModel.subCategory
            expense.merchant = viewModel.merchant
            expense.note = viewModel.note
        }
        
        // 保存到数据库
        try? modelContext.save()
        
//        // 返回列表页
//        if !navigationPath.isEmpty {
//            navigationPath.removeLast()
//        }
    }
    
    /// 从详情页创建分期账单
    private func createInstallmentExpensesFromDetail(viewModel: ExpenseDetailViewModel, totalAmount: Double) {
        guard let expense = viewModel.expense else { return }
        
        let parentId = UUID()
        let monthlyPayment = InstallmentCalculator.calculateMonthlyPayment(
            principal: totalAmount,
            annualRate: Double(viewModel.installmentAnnualRate) ?? 0.0,
            periods: viewModel.installmentPeriods
        )
        
        let calendar = Calendar.current
        
        for period in 1...viewModel.installmentPeriods {
            // 计算每期的日期
            let periodDate: Date
            if period == 1 {
                // 第一期使用原始日期
                periodDate = viewModel.date
            } else {
                // 后续期数使用对应月份的第一天
                if let nextMonth = calendar.date(byAdding: .month, value: period - 1, to: viewModel.date) {
                    let components = calendar.dateComponents([.year, .month], from: nextMonth)
                    periodDate = calendar.date(from: components) ?? nextMonth
                } else {
                    periodDate = viewModel.date
                }
            }
            
            // 创建每期的账单
            let installmentNote = viewModel.note.isEmpty ? "第\(period)/\(viewModel.installmentPeriods)期" : "\(viewModel.note) - 第\(period)/\(viewModel.installmentPeriods)期"
            
            let newExpense = Expense(
                transactionType: viewModel.transactionType.rawValue,
                date: periodDate,
                amount: monthlyPayment,
                currency: viewModel.currency,
                mainCategory: viewModel.mainCategory,
                subCategory: viewModel.subCategory,
                merchant: viewModel.merchant,
                note: installmentNote,
                originalText: expense.originalText,
                imageData: period == 1 ? expense.imageData : nil,
                isInstallment: true,
                parentExpenseId: period == 1 ? nil : parentId,
                installmentPeriods: viewModel.installmentPeriods,
                installmentAnnualRate: Double(viewModel.installmentAnnualRate) ?? 0.0,
                installmentNumber: period,
                totalInstallmentAmount: totalAmount
            )
            
            // 第一期使用 parentId 作为其 id，后续期作为子账单
            if period == 1 {
                newExpense.id = parentId
            }
            
            modelContext.insert(newExpense)
        }
    }
    
    // MARK: - 快速记账功能
    
    /// 获取相册最新一张照片
    private func fetchLatestPhoto() async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            guard let latestAsset = fetchResult.firstObject else {
                continuation.resume(returning: nil)
                return
            }
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestImage(
                for: latestAsset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    /// 快速记账处理
    private func quickAddExpense() {
        Task {
            isQuickAddingExpense = true
            
            do {
                // 步骤 1: 获取最新照片
                guard let image = await fetchLatestPhoto() else {
                    await MainActor.run {
                        isQuickAddingExpense = false
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.error)
                    }
                    return
                }
                
                // 步骤 2: OCR 识别文字
                let recognizedText = try await OCRService.shared.recognizeText(from: image)
                
                // 步骤 3: AI 分析账单信息
                let expenseInfo = try await AIExpenseAnalyzer.shared.analyzeExpense(
                    from: recognizedText,
                    context: modelContext,
                    preferredType: selectedTransactionType
                )
                
                // 步骤 4: 创建并保存账单
                await MainActor.run {
                    let transactionType = expenseInfo.transactionType.flatMap { TransactionType(rawValue: $0) } ?? selectedTransactionType
                    let date = expenseInfo.date.flatMap { parseDate(from: $0) } ?? Date()
                    let amount = expenseInfo.amount ?? 0.0
                    let currency = expenseInfo.currency ?? defaultCurrency
                    let mainCategory = expenseInfo.mainCategory ?? "其他"
                    let subCategory = expenseInfo.subCategory ?? "其他"
                    let merchant = expenseInfo.merchant ?? ""
                    let note = expenseInfo.note ?? ""
                    
                    let expense = Expense(
                        transactionType: transactionType.rawValue,
                        date: date,
                        amount: amount,
                        currency: defaultCurrency,
                        originalAmount: amount,
                        originalCurrency: currency,
                        exchangeRate: 1.0,
                        mainCategory: mainCategory,
                        subCategory: subCategory,
                        merchant: merchant,
                        note: note,
                        originalText: recognizedText,
                        imageData: image.jpegData(compressionQuality: 0.7)
                    )
                    
                    modelContext.insert(expense)
                    try? modelContext.save()
                    
                    isQuickAddingExpense = false
                    
                    // 成功反馈
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                }
                
            } catch {
                await MainActor.run {
                    isQuickAddingExpense = false
                    
                    // 错误反馈
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.error)
                    
                    print("快速记账失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 解析日期字符串（支持多种格式）
    private func parseDate(from dateString: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = [
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm",
                "yyyy-MM-dd",
                "yyyy/MM/dd HH:mm:ss",
                "yyyy/MM/dd HH:mm",
                "yyyy/MM/dd",
                "MM-dd HH:mm",
                "MM/dd HH:mm"
            ]
            
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "zh_CN")
                return formatter
            }
        }()
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
}
