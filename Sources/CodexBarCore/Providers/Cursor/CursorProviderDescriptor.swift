import Foundation

/// Descriptor factory for the Cursor provider.
public enum CursorProviderDescriptor {
    public static func make() -> ProviderDescriptor {
        let metadata = ProviderDefaults.metadata[.cursor]!

        return ProviderDescriptor(
            provider: .cursor,
            metadata: metadata,
            tokenCostConfig: ProviderTokenCostConfig(
                supportsTokenCost: false,
                unavailableMessage: "Cursor does not expose token-level cost data"
            ),
            fetchPlan: .cliCache(
                cacheDirectory: {
                    cursorCacheDirectory()
                },
                parser: { data, provider in
                    try CursorUsageParser.parse(data: data, provider: provider)
                }
            )
        )
    }

    static func cursorCacheDirectory() -> URL? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        #if os(macOS)
        let defaultDir = homeDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Cursor")
        #else
        let defaultDir = homeDir
            .appendingPathComponent(".config")
            .appendingPathComponent("cursor")
        #endif

        if FileManager.default.fileExists(atPath: defaultDir.path) {
            return defaultDir
        }
        return nil
    }
}

/// Parser for Cursor usage data.
public enum CursorUsageParser {
    public static func parse(data: Data, provider: UsageProvider) throws -> UsageSnapshot {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw ProviderFetchError.fetchFailed("Invalid JSON data for Cursor")
        }

        var sessionWindow: RateWindow?
        var periodicWindow: RateWindow?

        if let usage = json["usage"] as? [String: Any] {
            let used = usage["requestsUsed"] as? Int ?? 0
            let limit = usage["requestsLimit"] as? Int ?? 500
            let percentage = limit > 0 ? Double(used) / Double(limit) : 0.0

            sessionWindow = RateWindow(
                usedPercentage: percentage,
                label: "Requests",
                remaining: max(0, limit - used),
                total: limit
            )
        }

        if let billing = json["billing"] as? [String: Any] {
            let used = billing["used"] as? Double ?? 0.0
            let limit = billing["limit"] as? Double ?? 1.0
            periodicWindow = RateWindow(
                usedPercentage: limit > 0 ? used / limit : 0.0,
                label: "Monthly"
            )
        }

        return UsageSnapshot(
            provider: provider,
            sessionWindow: sessionWindow,
            periodicWindow: periodicWindow,
            fetchedAt: Date()
        )
    }
}
