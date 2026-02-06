import Foundation

/// A single rate-limit window representing usage within a time period.
public struct RateWindow: Sendable, Codable, Equatable {
    /// Percentage of the quota used (0.0 to 1.0).
    public let usedPercentage: Double

    /// When this window resets (absolute date).
    public let resetsAt: Date?

    /// Human-readable label for this window (e.g. "5-hour session").
    public let label: String?

    /// Optional description shown in UI.
    public let displayDescription: String?

    /// Remaining count (requests, tokens, etc.) if available.
    public let remaining: Int?

    /// Total count for this window if available.
    public let total: Int?

    public init(
        usedPercentage: Double,
        resetsAt: Date? = nil,
        label: String? = nil,
        displayDescription: String? = nil,
        remaining: Int? = nil,
        total: Int? = nil
    ) {
        self.usedPercentage = min(max(usedPercentage, 0.0), 1.0)
        self.resetsAt = resetsAt
        self.label = label
        self.displayDescription = displayDescription
        self.remaining = remaining
        self.total = total
    }

    /// Percentage of remaining quota (0.0 to 1.0).
    public var remainingPercentage: Double {
        1.0 - usedPercentage
    }
}
