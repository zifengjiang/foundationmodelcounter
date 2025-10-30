//
//  ProgressToast.swift
//  FoundationModelCounter
//
//  Created on 2025/10/30.
//

import SwiftUI

// MARK: - Progress Toast View

struct ProgressToast: View {
    let message: String
    let progress: Double?
    
    var body: some View {
        VStack(spacing: 12) {
            if let progress = progress {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.white)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let progress: Double?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressToast(message: message, progress: progress)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isPresented)
    }
}

extension View {
    func progressToast(
        isPresented: Binding<Bool>,
        message: String,
        progress: Double? = nil
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            progress: progress
        ))
    }
}

