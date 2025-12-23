//
//  DateRangePicker.swift
//  testapp
//
//  Better date range selection UI
//

import SwiftUI

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPreset: DatePreset? = nil
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    enum DatePreset: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case thisYear = "This Year"
        case lastYear = "Last Year"
        case custom = "Custom"
        
        func dates() -> (start: Date, end: Date)? {
            let calendar = Calendar.current
            let today = Date()
            
            switch self {
            case .today:
                return (today, today)
            case .yesterday:
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
                return (yesterday, yesterday)
            case .thisWeek:
                let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
                return (startOfWeek, today)
            case .lastWeek:
                let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today) ?? today
                let endOfLastWeek = calendar.date(byAdding: .day, value: 6, to: startOfLastWeek) ?? today
                return (startOfLastWeek, endOfLastWeek)
            case .thisMonth:
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
                return (startOfMonth, today)
            case .lastMonth:
                let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today) ?? today
                let endOfLastMonth = calendar.date(byAdding: .day, value: -1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today) ?? today
                return (startOfLastMonth, endOfLastMonth)
            case .thisYear:
                let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)) ?? today
                return (startOfYear, today)
            case .lastYear:
                let startOfLastYear = calendar.date(byAdding: .year, value: -1, to: calendar.date(from: calendar.dateComponents([.year], from: today)) ?? today) ?? today
                let endOfLastYear = calendar.date(byAdding: .day, value: -1, to: calendar.date(from: calendar.dateComponents([.year], from: today)) ?? today) ?? today
                return (startOfLastYear, endOfLastYear)
            case .custom:
                return nil
            }
        }
    }
    
    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
        _tempStartDate = State(initialValue: startDate.wrappedValue)
        _tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Quick Select") {
                    ForEach(DatePreset.allCases.filter { $0 != .custom }, id: \.self) { preset in
                        Button(action: {
                            if let dates = preset.dates() {
                                tempStartDate = dates.start
                                tempEndDate = dates.end
                                selectedPreset = preset
                            }
                        }) {
                            HStack {
                                Text(preset.rawValue)
                                Spacer()
                                if selectedPreset == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Custom Range") {
                    DatePicker("Start Date", selection: $tempStartDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $tempEndDate, displayedComponents: .date)
                }
                
                Section {
                    HStack {
                        Text("Selected Range")
                        Spacer()
                        Text("\(tempStartDate.toDisplayDate()) - \(tempEndDate.toDisplayDate())")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        dismiss()
                    }
                }
            }
        }
    }
}





