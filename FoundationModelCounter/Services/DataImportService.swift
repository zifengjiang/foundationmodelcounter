//
//  DataImportService.swift
//  FoundationModelCounter
//
//  Created on 2025/10/30.
//

import Foundation
import SwiftUI
import SwiftData
import ZIPFoundation

class DataImportService {
    static let shared = DataImportService()
    
    private init() {}
    
    // MARK: - 导入结果
    
    struct ImportResult {
        let totalCount: Int      // 总记录数
        let importedCount: Int   // 导入成功数
        let skippedCount: Int    // 跳过的重复记录数
        let failedCount: Int     // 失败数
    }
    
    // MARK: - 导入数据
    
    func importData(
        from zipURL: URL,
        context: ModelContext,
        progressHandler: (@Sendable (String, Double) -> Void)? = nil
    ) async throws -> ImportResult {
        progressHandler?("解压文件...", 0.0)
        // 创建临时目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // 清理临时文件
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // 解压文件
        try await unzipFile(at: zipURL, to: tempDir)
        
        progressHandler?("查找数据文件...", 0.2)
        // 查找CSV文件
        guard let csvURL = findCSVFile(in: tempDir) else {
            throw NSError(domain: "DataImportService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "未找到CSV文件"])
        }
        
        // 查找images目录
        let imagesDir = tempDir.appendingPathComponent("images")
        
        progressHandler?("导入数据...", 0.3)
        // 解析CSV并导入
        let result = try await parseAndImport(csvURL: csvURL, imagesDir: imagesDir, context: context, progressHandler: progressHandler)
        
        progressHandler?("完成", 1.0)
        return result
    }
    
    // MARK: - 解压ZIP文件
    
    private func unzipFile(at zipURL: URL, to destDir: URL) async throws {
        let fileManager = FileManager.default
        
        return try await withCheckedThrowingContinuation { continuation in
            var coordinatorError: NSError?
            var unzipError: Error?
            
            // 使用 NSFileCoordinator 安全访问文件
            NSFileCoordinator().coordinate(
                readingItemAt: zipURL,
                options: [.withoutChanges],
                error: &coordinatorError
            ) { url in
                do {
                    // 确保目标目录存在
                    if !fileManager.fileExists(atPath: destDir.path) {
                        try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
                    }
                    
                    // 使用 ZIPFoundation 解压
                    // ZIPFoundation 通过扩展 FileManager 添加了 unzipItem 方法
                    try fileManager.unzipItem(at: url, to: destDir)
                } catch {
                    unzipError = error
                }
            }
            
            if let error = coordinatorError {
                continuation.resume(throwing: error)
            } else if let error = unzipError {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: ())
            }
        }
    }
    
    // MARK: - 查找CSV文件
    
    private func findCSVFile(in directory: URL) -> URL? {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "csv" {
                return fileURL
            }
        }
        
        return nil
    }
    
    // MARK: - 解析CSV并导入
    
    private func parseAndImport(
        csvURL: URL,
        imagesDir: URL,
        context: ModelContext,
        progressHandler: (@Sendable (String, Double) -> Void)? = nil
    ) async throws -> ImportResult {
        // 读取CSV内容
        let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw NSError(domain: "DataImportService", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "CSV文件为空"])
        }
        
        // 获取现有的所有账目（用于去重）
        let existingExpenses = try context.fetch(FetchDescriptor<Expense>())
        
        var totalCount = 0
        var importedCount = 0
        var skippedCount = 0
        var failedCount = 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 跳过标题行，从第二行开始
        for i in 1..<lines.count {
            let line = lines[i]
            totalCount += 1
            
            // 更新进度 (30% - 90% 的范围)
            let progress = 0.3 + (Double(i) / Double(lines.count)) * 0.6
            progressHandler?("导入中 \(i)/\(lines.count - 1)...", progress)
            
            // 解析CSV行
            let fields = parseCSVLine(line)
            
            guard fields.count >= 9 else {
                failedCount += 1
                continue
            }
            
            // 提取字段
            guard let date = dateFormatter.date(from: fields[0]) else {
                failedCount += 1
                continue
            }
            
            let transactionType = fields[1]
            guard let amount = Double(fields[2]) else {
                failedCount += 1
                continue
            }
            
            let currency = fields[3]
            let mainCategory = fields[4]
            let subCategory = fields[5]
            let merchant = fields[6]
            let note = fields[7]
            let imageName = fields[8]
            
            // 检查是否重复（使用日期、金额、类别作为唯一标识）
            let isDuplicate = existingExpenses.contains { expense in
                abs(expense.date.timeIntervalSince(date)) < 1.0 && // 1秒内
                abs(expense.amount - amount) < 0.01 &&
                expense.mainCategory == mainCategory &&
                expense.subCategory == subCategory
            }
            
            if isDuplicate {
                skippedCount += 1
                continue
            }
            
            // 加载图片（失败不会中断导入）
            var imageData: Data?
            if !imageName.isEmpty {
                let imageURL = imagesDir.appendingPathComponent(imageName)
                imageData = try? Data(contentsOf: imageURL)
            }
            
            // 创建账目记录
            let expense = Expense(
                transactionType: transactionType,
                date: date,
                amount: amount,
                currency: currency,
                mainCategory: mainCategory,
                subCategory: subCategory,
                merchant: merchant,
                note: note,
                originalText: "",
                imageData: imageData
            )
            
            context.insert(expense)
            importedCount += 1
            
            // 更新或添加类目（忽略失败）
            if let type = TransactionType(rawValue: transactionType) {
                _ = CategoryService.shared.addOrUpdateCategory(
                    transactionType: type,
                    mainCategory: mainCategory,
                    subCategory: subCategory,
                    context: context
                )
            }
        }
        
        // 保存到数据库
        try context.save()
        
        return ImportResult(
            totalCount: totalCount,
            importedCount: importedCount,
            skippedCount: skippedCount,
            failedCount: failedCount
        )
    }
    
    // MARK: - 解析CSV行
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                // 检查是否是转义的引号
                let nextIndex = line.index(after: i)
                if nextIndex < line.endIndex && line[nextIndex] == "\"" {
                    currentField.append("\"")
                    i = line.index(after: nextIndex)
                    continue
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // 添加最后一个字段
        fields.append(currentField)
        
        return fields
    }
}
