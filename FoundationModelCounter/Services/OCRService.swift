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
    
    func recognizeText(from image: UIImage) async throws -> String {
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

