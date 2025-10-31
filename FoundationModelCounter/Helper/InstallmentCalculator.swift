//
//  InstallmentCalculator.swift
//  FoundationModelCounter
//
//  Created on 2025/10/31.
//

import Foundation

/// 分期计算器
struct InstallmentCalculator {
    
    /// 计算每期还款金额（等额本息）
    /// - Parameters:
    ///   - principal: 本金
    ///   - annualRate: 年化利率（百分比，如12.5表示12.5%）
    ///   - periods: 分期期数
    /// - Returns: 每期还款金额
    static func calculateMonthlyPayment(principal: Double, annualRate: Double, periods: Int) -> Double {
        guard periods > 0 else { return principal }
        
        // 如果利率为0，直接平均分配
        if annualRate == 0 {
            return principal / Double(periods)
        }
        
        // 月利率
        let monthlyRate = annualRate / 100.0 / 12.0
        
        // 等额本息计算公式：
        // 每月还款 = 本金 × [月利率 × (1 + 月利率)^期数] / [(1 + 月利率)^期数 - 1]
        let monthlyPayment = principal * monthlyRate * pow(1 + monthlyRate, Double(periods)) / (pow(1 + monthlyRate, Double(periods)) - 1)
        
        return monthlyPayment
    }
    
    /// 计算总利息
    /// - Parameters:
    ///   - principal: 本金
    ///   - annualRate: 年化利率（百分比）
    ///   - periods: 分期期数
    /// - Returns: 总利息
    static func calculateTotalInterest(principal: Double, annualRate: Double, periods: Int) -> Double {
        let monthlyPayment = calculateMonthlyPayment(principal: principal, annualRate: annualRate, periods: periods)
        let totalAmount = monthlyPayment * Double(periods)
        return totalAmount - principal
    }
    
    /// 计算每期的详细信息（本金、利息、剩余本金）
    /// - Parameters:
    ///   - principal: 本金
    ///   - annualRate: 年化利率（百分比）
    ///   - periods: 分期期数
    /// - Returns: 每期详细信息数组
    static func calculateInstallmentDetails(principal: Double, annualRate: Double, periods: Int) -> [InstallmentPeriodDetail] {
        guard periods > 0 else { return [] }
        
        let monthlyPayment = calculateMonthlyPayment(principal: principal, annualRate: annualRate, periods: periods)
        let monthlyRate = annualRate / 100.0 / 12.0
        
        var details: [InstallmentPeriodDetail] = []
        var remainingPrincipal = principal
        
        for period in 1...periods {
            let interestPayment: Double
            let principalPayment: Double
            
            if annualRate == 0 {
                // 无息分期
                interestPayment = 0
                principalPayment = monthlyPayment
            } else {
                // 当期利息 = 剩余本金 × 月利率
                interestPayment = remainingPrincipal * monthlyRate
                // 当期本金 = 每月还款 - 当期利息
                principalPayment = monthlyPayment - interestPayment
            }
            
            remainingPrincipal -= principalPayment
            
            // 最后一期可能有微小误差，调整为0
            if period == periods {
                remainingPrincipal = 0
            }
            
            details.append(InstallmentPeriodDetail(
                period: period,
                monthlyPayment: monthlyPayment,
                principalPayment: principalPayment,
                interestPayment: interestPayment,
                remainingPrincipal: max(0, remainingPrincipal)
            ))
        }
        
        return details
    }
}

/// 分期每期详细信息
struct InstallmentPeriodDetail {
    let period: Int  // 第几期
    let monthlyPayment: Double  // 每月还款
    let principalPayment: Double  // 本金部分
    let interestPayment: Double  // 利息部分
    let remainingPrincipal: Double  // 剩余本金
}


