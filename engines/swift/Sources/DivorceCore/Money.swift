import Foundation

public func almostEqual(_ a: Double, _ b: Double, tolerance: Double = moneyTolerance) -> Bool {
    abs(a - b) <= tolerance
}

func n(_ value: Double?) -> Double {
    value ?? 0
}

func roundFeeToRuble(_ amount: Double) -> Double {
    amount.rounded(.toNearestOrAwayFromZero)
}

enum ISODate {
    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    static func addMonths(_ iso: String, _ months: Int) -> String {
        shift(iso, years: 0, months: months, days: 0)
    }

    static func addYears(_ iso: String, _ years: Int) -> String {
        shift(iso, years: years, months: 0, days: 0)
    }

    static func daysBetween(_ from: String, _ to: String) -> Int {
        guard let a = parse(from), let b = parse(to) else { return 0 }
        let seconds = b.timeIntervalSince(a)
        return Int((seconds / 86_400).rounded())
    }

    static func isAfter(_ a: String, _ b: String) -> Bool {
        a > b
    }

    static func max(_ a: String?, _ b: String?) -> String? {
        switch (a, b) {
        case (nil, nil): return nil
        case (let x?, nil): return x
        case (nil, let y?): return y
        case (let x?, let y?): return x > y ? x : y
        }
    }

    private static func parse(_ iso: String) -> Date? {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return utc.date(from: components)
    }

    private static func format(_ date: Date) -> String {
        let c = utc.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Как `Date.UTC(y, m - 1 + months, d)` в JS: переполнение дня уходит в следующий месяц.
    private static func shift(_ iso: String, years: Int, months: Int, days: Int) -> String {
        guard let date = parse(iso) else { return iso }
        let parts = utc.dateComponents([.year, .month, .day], from: date)
        var components = DateComponents()
        components.year = (parts.year ?? 0) + years
        components.month = (parts.month ?? 0) + months
        components.day = (parts.day ?? 0) + days
        guard let shifted = utc.date(from: components) else { return iso }
        return format(shifted)
    }
}
