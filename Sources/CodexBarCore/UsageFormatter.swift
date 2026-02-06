import Foundation

/// Formatting utilities for usage display.
public enum UsageFormatter {

    // MARK: - Reset Time

    /// Human-readable countdown until a reset time.
    public static func resetCountdownDescription(until date: Date, from now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)
        guard interval > 0 else { return "now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "in <1m"
        }
    }

    /// Human-readable reset description (e.g. "today at 3:00 PM", "tomorrow").
    public static func resetDescription(for date: Date, from now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - Usage Lines

    /// Format a usage percentage line (e.g. "75% used" or "25% remaining").
    public static func usageLine(usedPercentage: Double, showRemaining: Bool = true) -> String {
        let pct = Int(usedPercentage * 100)
        if showRemaining {
            return "\(100 - pct)% remaining"
        } else {
            return "\(pct)% used"
        }
    }

    // MARK: - Credits & Currency

    /// Format a credit balance.
    public static func creditsString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    /// Format a USD amount.
    public static func usdString(_ value: Double) -> String {
        return "$\(creditsString(value))"
    }

    /// Format with a currency code.
    public static func currencyString(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: value)) ?? "\(code) \(String(format: "%.2f", value))"
    }

    // MARK: - Token Counts

    /// Abbreviate token counts (e.g. 1500000 -> "1.5M").
    public static func tokenCountString(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            let value = Double(count) / 1_000_000_000
            return value >= 10 ? "\(Int(value))B" : String(format: "%.1fB", value).replacingOccurrences(of: ".0B", with: "B")
        } else if count >= 1_000_000 {
            let value = Double(count) / 1_000_000
            return value >= 10 ? "\(Int(value))M" : String(format: "%.1fM", value).replacingOccurrences(of: ".0M", with: "M")
        } else if count >= 1_000 {
            let value = Double(count) / 1_000
            return value >= 10 ? "\(Int(value))K" : String(format: "%.1fK", value).replacingOccurrences(of: ".0K", with: "K")
        } else {
            return "\(count)"
        }
    }

    // MARK: - Text Cleaning

    /// Clean model display names by stripping date patterns and trailing whitespace.
    public static func modelDisplayName(_ raw: String) -> String {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip trailing date patterns like "-20240101"
        if let range = name.range(of: #"-\d{8}$"#, options: .regularExpression) {
            name.removeSubrange(range)
        }
        return name
    }

    /// Clean plan names by removing ANSI codes and boilerplate.
    public static func cleanPlanName(_ raw: String) -> String {
        // Remove ANSI escape codes
        var name = raw.replacingOccurrences(
            of: #"\x1B\[[0-9;]*m"#,
            with: "",
            options: .regularExpression
        )
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Capitalize first letter
        if let first = name.first {
            name = first.uppercased() + name.dropFirst()
        }
        return name
    }

    /// Truncate to a single line with max length.
    public static func truncatedSingleLine(_ text: String, maxLength: Int = 80) -> String {
        let singleLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if singleLine.count > maxLength {
            return String(singleLine.prefix(maxLength - 1)) + "…"
        }
        return singleLine
    }
}
