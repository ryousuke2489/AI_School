import Foundation

/// Pace indicator for usage consumption rate.
public enum UsagePace: String, Sendable {
    case onTrack = "on_track"
    case ahead = "ahead"
    case behind = "behind"
    case critical = "critical"
    case unknown = "unknown"

    /// Compute pace based on usage percentage and time elapsed in the window.
    public static func compute(usedPercentage: Double, elapsedFraction: Double) -> UsagePace {
        guard elapsedFraction > 0 else { return .unknown }

        let expectedUsage = elapsedFraction
        let ratio = usedPercentage / expectedUsage

        if usedPercentage >= 0.95 {
            return .critical
        } else if ratio > 1.5 {
            return .ahead
        } else if ratio < 0.5 {
            return .behind
        } else {
            return .onTrack
        }
    }

    /// Human-readable description.
    public var displayDescription: String {
        switch self {
        case .onTrack: return "On track"
        case .ahead: return "Using faster than expected"
        case .behind: return "Well below limit"
        case .critical: return "Near limit"
        case .unknown: return "Unknown"
        }
    }

    /// A simple emoji indicator.
    public var indicator: String {
        switch self {
        case .onTrack: return "●"
        case .ahead: return "▲"
        case .behind: return "▼"
        case .critical: return "!"
        case .unknown: return "?"
        }
    }
}
