import Foundation

/// Descriptor factory for the GitHub Copilot provider.
public enum CopilotProviderDescriptor {
    public static func make() -> ProviderDescriptor {
        let metadata = ProviderDefaults.metadata[.copilot]!

        return ProviderDescriptor(
            provider: .copilot,
            metadata: metadata,
            tokenCostConfig: ProviderTokenCostConfig(
                supportsTokenCost: false,
                unavailableMessage: "Copilot usage data requires GitHub API token"
            ),
            fetchPlan: .cliCache(
                cacheDirectory: {
                    copilotCacheDirectory()
                },
                parser: { data, provider in
                    try CopilotUsageParser.parse(data: data, provider: provider)
                }
            )
        )
    }

    static func copilotCacheDirectory() -> URL? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        #if os(macOS)
        let defaultDir = homeDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("github-copilot")
        #else
        let defaultDir = homeDir
            .appendingPathComponent(".config")
            .appendingPathComponent("github-copilot")
        #endif

        if FileManager.default.fileExists(atPath: defaultDir.path) {
            return defaultDir
        }
        return nil
    }
}

/// Parser for Copilot usage data.
public enum CopilotUsageParser {
    public static func parse(data: Data, provider: UsageProvider) throws -> UsageSnapshot {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw ProviderFetchError.fetchFailed("Invalid JSON data for Copilot")
        }

        var sessionWindow: RateWindow?
        var periodicWindow: RateWindow?

        if let completions = json["completions"] as? [String: Any] {
            let accepted = completions["accepted"] as? Int ?? 0
            let total = completions["total"] as? Int ?? 0
            if total > 0 {
                sessionWindow = RateWindow(
                    usedPercentage: Double(accepted) / Double(total),
                    label: "Completions",
                    remaining: total - accepted,
                    total: total
                )
            }
        }

        if let chat = json["chat"] as? [String: Any] {
            let used = chat["messagesUsed"] as? Int ?? 0
            let limit = chat["messagesLimit"] as? Int ?? 0
            if limit > 0 {
                periodicWindow = RateWindow(
                    usedPercentage: Double(used) / Double(limit),
                    label: "Chat Monthly",
                    remaining: max(0, limit - used),
                    total: limit
                )
            }
        }

        var identity: ProviderIdentity?
        if let account = json["account"] as? [String: Any] {
            identity = ProviderIdentity(
                email: account["login"] as? String,
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
}
