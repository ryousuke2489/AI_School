import Foundation

/// All supported AI usage providers.
public enum UsageProvider: String, CaseIterable, Sendable, Codable, Identifiable {
    case codex
    case claude
    case cursor
    case gemini
    case copilot

    public var id: String { rawValue }
}

/// Visual icon style for a provider in the menu bar.
public enum IconStyle: String, CaseIterable, Sendable {
    case codex
    case claude
    case cursor
    case gemini
    case copilot
    case combined
}

/// Metadata describing a provider's display and behavioral configuration.
public struct ProviderMetadata: Sendable {
    public let provider: UsageProvider
    public let displayName: String
    public let cliName: String
    public let iconStyle: IconStyle
    public let sessionLabel: String
    public let weeklyLabel: String
    public let dashboardURL: URL?
    public let statusURL: URL?
    public let supportsCredits: Bool
    public let defaultEnabled: Bool
    public let isPrimaryProvider: Bool

    public init(
        provider: UsageProvider,
        displayName: String,
        cliName: String,
        iconStyle: IconStyle,
        sessionLabel: String = "Session",
        weeklyLabel: String = "Weekly",
        dashboardURL: URL? = nil,
        statusURL: URL? = nil,
        supportsCredits: Bool = false,
        defaultEnabled: Bool = false,
        isPrimaryProvider: Bool = false
    ) {
        self.provider = provider
        self.displayName = displayName
        self.cliName = cliName
        self.iconStyle = iconStyle
        self.sessionLabel = sessionLabel
        self.weeklyLabel = weeklyLabel
        self.dashboardURL = dashboardURL
        self.statusURL = statusURL
        self.supportsCredits = supportsCredits
        self.defaultEnabled = defaultEnabled
        self.isPrimaryProvider = isPrimaryProvider
    }
}

/// Static provider defaults.
public enum ProviderDefaults {
    public static let metadata: [UsageProvider: ProviderMetadata] = [
        .codex: ProviderMetadata(
            provider: .codex,
            displayName: "Codex",
            cliName: "codex",
            iconStyle: .codex,
            sessionLabel: "5-hour session",
            weeklyLabel: "Weekly",
            dashboardURL: URL(string: "https://chatgpt.com/admin/usage"),
            statusURL: URL(string: "https://status.openai.com"),
            supportsCredits: true,
            defaultEnabled: true,
            isPrimaryProvider: true
        ),
        .claude: ProviderMetadata(
            provider: .claude,
            displayName: "Claude",
            cliName: "claude",
            iconStyle: .claude,
            sessionLabel: "5-hour session",
            weeklyLabel: "Weekly",
            dashboardURL: URL(string: "https://console.anthropic.com/settings/usage"),
            statusURL: URL(string: "https://status.anthropic.com"),
            supportsCredits: true,
            defaultEnabled: true,
            isPrimaryProvider: true
        ),
        .cursor: ProviderMetadata(
            provider: .cursor,
            displayName: "Cursor",
            cliName: "cursor",
            iconStyle: .cursor,
            sessionLabel: "Session",
            weeklyLabel: "Monthly",
            dashboardURL: URL(string: "https://www.cursor.com/settings"),
            statusURL: nil,
            defaultEnabled: true,
            isPrimaryProvider: false
        ),
        .gemini: ProviderMetadata(
            provider: .gemini,
            displayName: "Gemini",
            cliName: "gemini",
            iconStyle: .gemini,
            sessionLabel: "Session",
            weeklyLabel: "Daily",
            dashboardURL: URL(string: "https://aistudio.google.com"),
            statusURL: URL(string: "https://status.cloud.google.com"),
            defaultEnabled: false,
            isPrimaryProvider: false
        ),
        .copilot: ProviderMetadata(
            provider: .copilot,
            displayName: "Copilot",
            cliName: "copilot",
            iconStyle: .copilot,
            sessionLabel: "Session",
            weeklyLabel: "Monthly",
            dashboardURL: URL(string: "https://github.com/settings/copilot"),
            statusURL: URL(string: "https://www.githubstatus.com"),
            defaultEnabled: false,
            isPrimaryProvider: false
        ),
    ]
}
