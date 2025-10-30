//
//  DataExportService.swift
//  FoundationModelCounter
//
//  Created on 2025/10/30.
//

import Foundation
import SwiftUI
import SwiftData
import Compression

class DataExportService {
    static let shared = DataExportService()
    
    private init() {}
    
    // MARK: - 导出数据为压缩包
    
    func exportData(
        expenses: [Expense],
        progressHandler: (@Sendable (String, Double) -> Void)? = nil
    ) async throws -> URL {
        await progressHandler?("准备导出数据...", 0.0)
        // 创建临时目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // 创建images子目录
        let imagesDir = tempDir.appendingPathComponent("images")
        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        await progressHandler?("生成CSV文件...", 0.2)
        // 生成CSV文件
        try await generateCSV(expenses: expenses, imagesDir: imagesDir, outputDir: tempDir, progressHandler: progressHandler)
        
        await progressHandler?("创建压缩包...", 0.8)
        // 创建压缩包
        let zipURL = try await createZipArchive(sourceDir: tempDir)
        
        await progressHandler?("完成", 1.0)
        // 清理临时目录
        try? FileManager.default.removeItem(at: tempDir)
        
        return zipURL
    }
    
    // MARK: - 生成CSV文件
    
    @discardableResult private func generateCSV(
        expenses: [Expense],
        imagesDir: URL,
        outputDir: URL,
        progressHandler: (@Sendable (String, Double) -> Void)? = nil
    ) async throws -> URL {
        var csvContent = "日期,交易类型,金额,货币,大类,小类,商户,备注,图片文件名\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let totalCount = expenses.count
        for (index, expense) in expenses.enumerated() {
            // 更新进度 (20% - 80% 的范围)
            let progress = 0.2 + (Double(index) / Double(totalCount)) * 0.6
            await progressHandler?("导出中 \(index + 1)/\(totalCount)...", progress)
            let date = dateFormatter.string(from: expense.date)
            let type = expense.transactionType
            let amount = String(format: "%.2f", expense.amount)
            let currency = expense.currency
            let mainCategory = escapeCsvField(expense.mainCategory)
            let subCategory = escapeCsvField(expense.subCategory)
            let merchant = escapeCsvField(expense.merchant)
            let note = escapeCsvField(expense.note)
            
            // 处理图片
            var imageName = ""
            if let imageData = expense.imageData {
                imageName = try await saveImage(
                    imageData: imageData,
                    date: expense.date,
                    amount: expense.amount,
                    toDirectory: imagesDir
                )
            }
            
            let row = "\(date),\(type),\(amount),\(currency),\(mainCategory),\(subCategory),\(merchant),\(note),\(imageName)\n"
            csvContent += row
        }
        
        let csvURL = outputDir.appendingPathComponent("账目数据.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        
        return csvURL
    }
    
    // MARK: - 保存图片
    
    private func saveImage(imageData: Data, date: Date, amount: Double, toDirectory directory: URL) async throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: date)
        
        let amountString = String(format: "%.2f", amount).replacingOccurrences(of: ".", with: "_")
        let fileName = "\(dateString)_\(amountString).jpg"
        
        let fileURL = directory.appendingPathComponent(fileName)
        try imageData.write(to: fileURL)
        
        return fileName
    }
    
    // MARK: - 创建ZIP压缩包
    
    private func createZipArchive(sourceDir: URL) async throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let zipFileName = "账目导出_\(timestamp).zip"
        let finalZipURL = FileManager.default.temporaryDirectory.appendingPathComponent(zipFileName)
        
        // 如果已存在，先删除
        if FileManager.default.fileExists(atPath: finalZipURL.path) {
            try FileManager.default.removeItem(at: finalZipURL)
        }
        
        // 使用 NSFileCoordinator 的 .forUploading 选项自动创建 ZIP
        return try await withCheckedThrowingContinuation { continuation in
            var coordinatorError: NSError?
            var copyError: Error?
            
            NSFileCoordinator().coordinate(
                readingItemAt: sourceDir,
                options: [.forUploading],
                error: &coordinatorError
            ) { (zipURL) in
                // zipURL 就是系统自动创建的 ZIP 文件
                do {
                    // 复制到最终位置
                    try FileManager.default.copyItem(at: zipURL, to: finalZipURL)
                } catch {
                    // 保存到局部变量，避免访问冲突
                    copyError = error
                }
            }
            
            // 检查错误（先检查 coordinator 错误，再检查复制错误）
            if let error = coordinatorError {
                continuation.resume(throwing: error)
            } else if let error = copyError {
                continuation.resume(throwing: error)
            } else if FileManager.default.fileExists(atPath: finalZipURL.path) {
                continuation.resume(returning: finalZipURL)
            } else {
                continuation.resume(throwing: NSError(
                    domain: "DataExportService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "无法创建ZIP文件"]
                ))
            }
        }
    }
    
    // MARK: - CSV字段转义
    
    private func escapeCsvField(_ field: String) -> String {
        if field.isEmpty {
            return ""
        }
        
        // 如果包含逗号、引号或换行符，需要用引号包裹并转义引号
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        
        return field
    }
}

