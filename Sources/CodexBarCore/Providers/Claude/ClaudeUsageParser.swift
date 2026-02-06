import Foundation

/// Parser for Claude CLI usage data.
public enum ClaudeUsageParser {

    /// Parse Claude usage data from JSON.
    public static func parse(data: Data, provider: UsageProvider) throws -> UsageSnapshot {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw ProviderFetchError.fetchFailed("Invalid JSON data for Claude")
        }

        var sessionWindow: RateWindow?
        var periodicWindow: RateWindow?
        var identity: ProviderIdentity?

        // Parse session rate limit
        if let session = json["session"] as? [String: Any] {
            sessionWindow = parseRateWindow(from: session, label: "5-hour session")
        }

        // Parse weekly/periodic rate limit
        if let weekly = json["weekly"] as? [String: Any] {
            periodicWindow = parseRateWindow(from: weekly, label: "Weekly")
        } else if let daily = json["daily"] as? [String: Any] {
            periodicWindow = parseRateWindow(from: daily, label: "Daily")
        }

        // Parse identity
        if let account = json["account"] as? [String: Any] {
            identity = ProviderIdentity(
                email: account["email"] as? String,
                organization: account["organization"] as? String,
                plan: account["plan"] as? String,
                loginMethod: account["loginMethod"] as? String
            )
        }

        return UsageSnapshot(
            provider: provider,
            sessionWindow: sessionWindow,
            periodicWindow: periodicWindow,
            fetchedAt: Date(),
            identity: identity
        )
    }

    private static func parseRateWindow(from dict: [String: Any], label: String) -> RateWindow {
        let usedPercentage = dict["usedPercentage"] as? Double ?? 0.0
        let remaining = dict["remaining"] as? Int
        let total = dict["total"] as? Int
        let description = dict["description"] as? String

        var resetsAt: Date?
        if let resetTimestamp = dict["resetsAt"] as? TimeInterval {
            resetsAt = Date(timeIntervalSince1970: resetTimestamp)
        } else if let resetString = dict["resetsAt"] as? String {
            let formatter = ISO8601DateFormatter()
            resetsAt = formatter.date(from: resetString)
        }

        return RateWindow(
            usedPercentage: usedPercentage,
            resetsAt: resetsAt,
            label: label,
            displayDescription: description,
            remaining: remaining,
            total: total
        )
    }
}
