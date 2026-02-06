import Foundation

/// Application-wide configuration constants.
public enum AppConfig {
    /// Application identifier.
    public static let bundleIdentifier = "com.steipete.CodexBar"

    /// Application support directory.
    public static var appSupportDirectory: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CodexBar")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Token accounts storage file.
    public static var tokenAccountsFile: URL {
        appSupportDirectory.appendingPathComponent("token-accounts.json")
    }

    /// Settings file.
    public static var settingsFile: URL {
        appSupportDirectory.appendingPathComponent("settings.json")
    }

    /// Cache directory.
    public static var cacheDirectory: URL {
        let dir = appSupportDirectory.appendingPathComponent("cache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Default refresh interval in seconds.
    public static let defaultRefreshInterval: TimeInterval = 300  // 5 minutes

    /// Stale data threshold in seconds.
    public static let staleDataThreshold: TimeInterval = 600  // 10 minutes

    /// User-Agent string for HTTP requests.
    public static let userAgent = "CodexBar/1.0"
}
