import Foundation

/// Descriptor factory for the Gemini provider.
public enum GeminiProviderDescriptor {
    public static func make() -> ProviderDescriptor {
        let metadata = ProviderDefaults.metadata[.gemini]!

        return ProviderDescriptor(
            provider: .gemini,
            metadata: metadata,
            tokenCostConfig: ProviderTokenCostConfig(
                supportsTokenCost: true,
                unavailableMessage: nil
            ),
            fetchPlan: .cliCache(
                cacheDirectory: {
                    geminiCacheDirectory()
                },
                parser: { data, provider in
                    try GeminiUsageParser.parse(data: data, provider: provider)
                }
            )
        )
    }

    static func geminiCacheDirectory() -> URL? {
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            let dir = URL(fileURLWithPath: xdg).appendingPathComponent("gemini")
            if FileManager.default.fileExists(atPath: dir.path) {
                return dir
            }
        }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        #if os(macOS)
        let defaultDir = homeDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("gemini")
        #else
        let defaultDir = homeDir
            .appendingPathComponent(".config")
            .appendingPathComponent("gemini")
        #endif

        if FileManager.default.fileExists(atPath: defaultDir.path) {
            return defaultDir
        }
        return nil
    }
}

/// Parser for Gemini usage data.
public enum GeminiUsageParser {
    public static func parse(data: Data, provider: UsageProvider) throws -> UsageSnapshot {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw ProviderFetchError.fetchFailed("Invalid JSON data for Gemini")
        }

        var sessionWindow: RateWindow?
        var periodicWindow: RateWindow?

        if let limits = json["rateLimits"] as? [String: Any] {
            if let rpm = limits["requestsPerMinute"] as? [String: Any] {
                let used = rpm["used"] as? Int ?? 0
                let limit = rpm["limit"] as? Int ?? 60
                sessionWindow = RateWindow(
                    usedPercentage: limit > 0 ? Double(used) / Double(limit) : 0.0,
                    label: "RPM",
                    remaining: max(0, limit - used),
                    total: limit
                )
            }

            if let daily = limits["daily"] as? [String: Any] {
                let used = daily["used"] as? Double ?? 0.0
                let limit = daily["limit"] as? Double ?? 1.0
                var resetsAt: Date?
                if let resetStr = daily["resetsAt"] as? String {
                    resetsAt = ISO8601DateFormatter().date(from: resetStr)
                }
                periodicWindow = RateWindow(
                    usedPercentage: limit > 0 ? used / limit : 0.0,
                    resetsAt: resetsAt,
                    label: "Daily"
                )
            }
        }

        return UsageSnapshot(
            provider: provider,
            sessionWindow: sessionWindow,
            periodicWindow: periodicWindow,
            fetchedAt: Date()
        )
    }
}
