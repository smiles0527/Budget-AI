//
//  CurrencyFormatter.swift
//  testapp
//
//  Currency formatting utilities
//

import Foundation

class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    
    private let formatter: NumberFormatter
    
    private init() {
        formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
    }
    
    func format(cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
    
    func format(dollars: Double) -> String {
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
    
    func parseToCents(_ string: String) -> Int? {
        let cleaned = string.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        guard let dollars = Double(cleaned) else { return nil }
        return Int(dollars * 100)
    }
}

