//
//  SimpleDate.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/22/21.
//

import Foundation

class SimpleDate: DateFormatter {
    override init() {
        super.init()
        self.dateFormat = "yyyy-MM-dd"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    static func makeDate(year: UInt16, month: UInt8, day: UInt8,
                         hour: UInt8, minute: UInt8, second: UInt8) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: Int(year), month: Int(month), day: Int(day),
                                        hour: Int(hour), minute: Int(minute), second: Int(second))
        return calendar.date(from: components)!
    }

    static func makeComponent(date: Date) -> DateComponents {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    static func age(from: Date) -> UInt8 {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: from, to: now)
        return UInt8(ageComponents.year!)
    }

    static let date19700101: Date = SimpleDate().date(from: "1970-01-01")!
}


class SimpleDateTime: DateFormatter {
    override init() {
        super.init()
        self.dateStyle = .medium
        self.timeStyle = .short
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
