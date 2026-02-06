import Foundation

/// Branding information for provider display in the UI.
public struct ProviderBranding: Sendable {
    public let provider: UsageProvider
    public let primaryColor: ProviderColor
    public let secondaryColor: ProviderColor
    public let iconName: String

    public init(
        provider: UsageProvider,
        primaryColor: ProviderColor,
        secondaryColor: ProviderColor,
        iconName: String
    ) {
        self.provider = provider
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.iconName = iconName
    }
}

/// Platform-agnostic color representation.
public struct ProviderColor: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

/// Predefined branding for all providers.
public enum ProviderBrandings {
    public static let all: [UsageProvider: ProviderBranding] = [
        .codex: ProviderBranding(
            provider: .codex,
            primaryColor: ProviderColor(red: 0.0, green: 0.65, blue: 0.52),
            secondaryColor: ProviderColor(red: 0.0, green: 0.45, blue: 0.35),
            iconName: "codex"
        ),
        .claude: ProviderBranding(
            provider: .claude,
            primaryColor: ProviderColor(red: 0.82, green: 0.55, blue: 0.28),
            secondaryColor: ProviderColor(red: 0.65, green: 0.40, blue: 0.18),
            iconName: "claude"
        ),
        .cursor: ProviderBranding(
            provider: .cursor,
            primaryColor: ProviderColor(red: 0.30, green: 0.30, blue: 0.90),
            secondaryColor: ProviderColor(red: 0.20, green: 0.20, blue: 0.70),
            iconName: "cursor"
        ),
        .gemini: ProviderBranding(
            provider: .gemini,
            primaryColor: ProviderColor(red: 0.25, green: 0.52, blue: 0.96),
            secondaryColor: ProviderColor(red: 0.15, green: 0.40, blue: 0.80),
            iconName: "gemini"
        ),
        .copilot: ProviderBranding(
            provider: .copilot,
            primaryColor: ProviderColor(red: 0.20, green: 0.20, blue: 0.20),
            secondaryColor: ProviderColor(red: 0.40, green: 0.40, blue: 0.40),
            iconName: "copilot"
        ),
    ]
}
