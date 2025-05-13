//
//  Date.swift
//  hairmax
//
//  Created by David Doswell on 11/8/24.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return "Today"
        }
        
        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }
        
        let components = calendar.dateComponents([.day, .weekOfYear, .month], from: self, to: now)
        
        if let days = components.day, days < 7 {
            return "\(days) days ago"
        }
        
        if let weeks = components.weekOfYear, weeks < 4 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        }
        
        if let months = components.month, months < 12 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: self)
    }
}
