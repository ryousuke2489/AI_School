import Foundation

/// Descriptor factory for the Claude provider.
public enum ClaudeProviderDescriptor {
    public static func make() -> ProviderDescriptor {
        let metadata = ProviderDefaults.metadata[.claude]!

        return ProviderDescriptor(
            provider: .claude,
            metadata: metadata,
            tokenCostConfig: ProviderTokenCostConfig(
                supportsTokenCost: true,
                unavailableMessage: nil
            ),
            fetchPlan: .cliCache(
                cacheDirectory: {
                    claudeCacheDirectory()
                },
                parser: { data, provider in
                    try ClaudeUsageParser.parse(data: data, provider: provider)
                }
            )
        )
    }

    /// Determine the Claude CLI cache directory.
    static func claudeCacheDirectory() -> URL? {
        // Check XDG_CONFIG_HOME first, then default locations
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            let dir = URL(fileURLWithPath: xdg).appendingPathComponent("claude")
            if FileManager.default.fileExists(atPath: dir.path) {
                return dir
            }
        }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        #if os(macOS)
        let defaultDir = homeDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("claude")
        #else
        let defaultDir = homeDir
            .appendingPathComponent(".config")
            .appendingPathComponent("claude")
        #endif

        if FileManager.default.fileExists(atPath: defaultDir.path) {
            return defaultDir
        }
        return nil
    }
}
