//
//  OCRService.swift
//  FoundationModelCounter
//
//  Created by didi on 2025/10/28.
//

import Foundation
import Vision
import UIKit

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// 识别图片中的文字（自动裁剪状态栏）
    func recognizeText(from image: UIImage, isScreenShot:Bool = false) async throws -> String {
        // 裁剪掉顶部状态栏区域，避免时间、电量等信息干扰识别
        var image = image
        if isScreenShot {
            image = cropStatusBar(from: image)
        }
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // 设置识别语言（支持中文和英文）
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 裁剪掉图片顶部的状态栏区域
    /// - Parameter image: 原始截屏图片
    /// - Returns: 裁剪后的图片
    private func cropStatusBar(from image: UIImage) -> UIImage {
        // 获取图片尺寸
        let imageSize = image.size
        let scale = image.scale
        
        // 计算状态栏高度（根据设备类型）
        // iPhone with notch/Dynamic Island: ~54pt (~162px @3x)
        // iPhone without notch: ~44pt (~132px @3x)
        // 为了兼容性，我们使用一个保守的值：裁剪顶部60pt
        let statusBarHeight: CGFloat = 120.0  // 60pt * 2 (假设2x分辨率)
        
        // 如果图片太小，不裁剪
        guard imageSize.height > statusBarHeight * 2 else {
            return image
        }
        
        // 计算裁剪区域（去掉顶部状态栏）
        let cropRect = CGRect(
            x: 0,
            y: statusBarHeight * scale,  // 从状态栏下方开始
            width: imageSize.width * scale,
            height: (imageSize.height - statusBarHeight) * scale
        )
        
        // 执行裁剪
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            // 如果裁剪失败，返回原图
            return image
        }
        
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .noTextFound:
            return "未识别到文字"
        }
    }
}

