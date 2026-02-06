#if os(macOS)
import Foundation
import Observation
import CodexBarCore
import Logging

/// Refresh frequency options for the usage polling timer.
public enum RefreshFrequency: String, CaseIterable, Sendable, Identifiable {
    case manual
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case tenMinutes = "10m"
    case fifteenMinutes = "15m"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .oneMinute: return "Every minute"
        case .fiveMinutes: return "Every 5 minutes"
        case .tenMinutes: return "Every 10 minutes"
        case .fifteenMinutes: return "Every 15 minutes"
        }
    }

    public var interval: TimeInterval? {
        switch self {
        case .manual: return nil
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .tenMinutes: return 600
        case .fifteenMinutes: return 900
        }
    }
}

/// Which metric to show prominently in the menu bar.
public enum MenuBarMetricPreference: String, CaseIterable, Sendable {
    case sessionPercentage
    case weeklyPercentage
    case both
    case none
}

/// Manages application preferences and provider configuration.
@MainActor
@Observable
public final class SettingsStore {
    private let logger = Logger(label: "com.steipete.CodexBar.settings")
    private let defaults = UserDefaults.standard

    // MARK: - General Settings

    public var refreshFrequency: RefreshFrequency {
        didSet { persistSetting("refreshFrequency", refreshFrequency.rawValue) }
    }

    public var launchAtLogin: Bool {
        didSet { persistSetting("launchAtLogin", launchAtLogin) }
    }

    public var mergeIcons: Bool {
        didSet { persistSetting("mergeIcons", mergeIcons) }
    }

    public var menuBarMetric: MenuBarMetricPreference {
        didSet { persistSetting("menuBarMetric", menuBarMetric.rawValue) }
    }

    // MARK: - Provider Settings

    public var enabledProviders: Set<UsageProvider> {
        didSet { persistEnabledProviders() }
    }

    public var providerOrder: [UsageProvider] {
        didSet { persistProviderOrder() }
    }

    // MARK: - Init

    public init() {
        // Load from UserDefaults or use defaults
        let freqStr = defaults.string(forKey: "refreshFrequency") ?? "5m"
        self.refreshFrequency = RefreshFrequency(rawValue: freqStr) ?? .fiveMinutes
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.mergeIcons = defaults.bool(forKey: "mergeIcons")

        let metricStr = defaults.string(forKey: "menuBarMetric") ?? "both"
        self.menuBarMetric = MenuBarMetricPreference(rawValue: metricStr) ?? .both

        // Load enabled providers
        if let savedProviders = defaults.stringArray(forKey: "enabledProviders") {
            self.enabledProviders = Set(savedProviders.compactMap { UsageProvider(rawValue: $0) })
        } else {
            // Default: enable providers marked as defaultEnabled
            self.enabledProviders = Set(
                ProviderDefaults.metadata.values
                    .filter { $0.defaultEnabled }
                    .map { $0.provider }
            )
        }

        // Load provider order
        if let savedOrder = defaults.stringArray(forKey: "providerOrder") {
            self.providerOrder = savedOrder.compactMap { UsageProvider(rawValue: $0) }
        } else {
            self.providerOrder = UsageProvider.allCases.map { $0 }
        }

        logger.info("Settings loaded: \(enabledProviders.count) providers enabled")
    }

    // MARK: - Provider Queries

    public func isProviderEnabled(_ provider: UsageProvider) -> Bool {
        enabledProviders.contains(provider)
    }

    public func toggleProvider(_ provider: UsageProvider) {
        if enabledProviders.contains(provider) {
            enabledProviders.remove(provider)
        } else {
            enabledProviders.insert(provider)
        }
    }

    public func metadata(for provider: UsageProvider) -> ProviderMetadata? {
        ProviderDefaults.metadata[provider]
    }

    /// Ordered list of enabled providers.
    public var orderedEnabledProviders: [UsageProvider] {
        providerOrder.filter { enabledProviders.contains($0) }
    }

    // MARK: - Persistence

    private func persistSetting(_ key: String, _ value: Any) {
        defaults.set(value, forKey: key)
    }

    private func persistEnabledProviders() {
        defaults.set(enabledProviders.map { $0.rawValue }, forKey: "enabledProviders")
    }

    private func persistProviderOrder() {
        defaults.set(providerOrder.map { $0.rawValue }, forKey: "providerOrder")
    }
}
#endif
