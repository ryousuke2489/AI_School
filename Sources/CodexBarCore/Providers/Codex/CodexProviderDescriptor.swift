import Foundation

/// Descriptor factory for the OpenAI Codex provider.
public enum CodexProviderDescriptor {
    public static func make() -> ProviderDescriptor {
        let metadata = ProviderDefaults.metadata[.codex]!

        return ProviderDescriptor(
            provider: .codex,
            metadata: metadata,
            tokenCostConfig: ProviderTokenCostConfig(
                supportsTokenCost: true,
                unavailableMessage: nil
            ),
            fetchPlan: .cliCache(
                cacheDirectory: {
                    codexCacheDirectory()
                },
                parser: { data, provider in
                    try CodexUsageParser.parse(data: data, provider: provider)
                }
            )
        )
    }

    static func codexCacheDirectory() -> URL? {
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            let dir = URL(fileURLWithPath: xdg).appendingPathComponent("codex")
            if FileManager.default.fileExists(atPath: dir.path) {
                return dir
            }
        }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        #if os(macOS)
        let defaultDir = homeDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("codex")
        #else
        let defaultDir = homeDir
            .appendingPathComponent(".config")
            .appendingPathComponent("codex")
        #endif

        if FileManager.default.fileExists(atPath: defaultDir.path) {
            return defaultDir
        }
        return nil
    }
}

/// Parser for Codex usage data.
public enum CodexUsageParser {
    public static func parse(data: Data, provider: UsageProvider) throws -> UsageSnapshot {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw ProviderFetchError.fetchFailed("Invalid JSON data for Codex")
        }

        var sessionWindow: RateWindow?
        var periodicWindow: RateWindow?

        if let rateLimit = json["rate_limit"] as? [String: Any] {
            if let session = rateLimit["session"] as? [String: Any] {
                sessionWindow = parseWindow(session, label: "5-hour session")
            }
            if let weekly = rateLimit["weekly"] as? [String: Any] {
                periodicWindow = parseWindow(weekly, label: "Weekly")
            }
        }

        var identity: ProviderIdentity?
        if let account = json["account"] as? [String: Any] {
            identity = ProviderIdentity(
                email: account["email"] as? String,
                organization: account["org"] as? String,
                plan: account["plan"] as? String
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

    private static func parseWindow(_ dict: [String: Any], label: String) -> RateWindow {
        let used = dict["used_percentage"] as? Double ?? dict["usedPercentage"] as? Double ?? 0.0
        let remaining = dict["remaining"] as? Int
        let total = dict["total"] as? Int

        var resetsAt: Date?
        if let ts = dict["resets_at"] as? TimeInterval {
            resetsAt = Date(timeIntervalSince1970: ts)
        } else if let s = dict["resets_at"] as? String {
            resetsAt = ISO8601DateFormatter().date(from: s)
        }

        return RateWindow(
            usedPercentage: used,
            resetsAt: resetsAt,
            label: label,
            remaining: remaining,
            total: total
        )
    }
}
