//
//  DateFormatter+Extensions.swift
//  testapp
//
//  Date formatting utilities
//

import Foundation

extension DateFormatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter
    }()
    
    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let input: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension String {
    func toDate() -> Date? {
        return DateFormatter.iso8601.date(from: self)
    }
    
    func toDisplayDate() -> String {
        guard let date = toDate() else { return self }
        return DateFormatter.display.string(from: date)
    }
}

extension Date {
    func toISOString() -> String {
        return DateFormatter.iso8601.string(from: self)
    }
    
    func toInputString() -> String {
        return DateFormatter.input.string(from: self)
    }
    
    func toDisplayString() -> String {
        return DateFormatter.display.string(from: self)
    }
}

