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

    // MARK: - Device Link (Mac mini / MacBook sync)

    /// When enabled, publish local usage snapshots into a shared folder so other Macs can read them.
    public var deviceLinkEnabled: Bool {
        didSet { persistSetting("deviceLinkEnabled", deviceLinkEnabled) }
    }

    public var deviceLinkMode: DeviceLinkMode {
        didSet { persistSetting("deviceLinkMode", deviceLinkMode.rawValue) }
    }

    /// Absolute or tilde-expanded path used when `deviceLinkMode == .customFolder`.
    public var deviceLinkCustomFolderPath: String {
        didSet { persistSetting("deviceLinkCustomFolderPath", deviceLinkCustomFolderPath) }
    }

    /// Mirror refresh/display/provider toggles into the shared folder (last-write-wins).
    public var deviceLinkSyncSettings: Bool {
        didSet { persistSetting("deviceLinkSyncSettings", deviceLinkSyncSettings) }
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

        self.deviceLinkEnabled = defaults.bool(forKey: "deviceLinkEnabled")
        let linkModeStr = defaults.string(forKey: "deviceLinkMode") ?? DeviceLinkMode.iCloudDrive.rawValue
        self.deviceLinkMode = DeviceLinkMode(rawValue: linkModeStr) ?? .iCloudDrive
        self.deviceLinkCustomFolderPath = defaults.string(forKey: "deviceLinkCustomFolderPath") ?? ""
        // Default true so enabling device link also keeps preferences aligned across Macs.
        if defaults.object(forKey: "deviceLinkSyncSettings") == nil {
            self.deviceLinkSyncSettings = true
        } else {
            self.deviceLinkSyncSettings = defaults.bool(forKey: "deviceLinkSyncSettings")
        }

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

    // MARK: - Device Link Settings Bridge

    /// Build a shareable settings payload for the sync folder.
    public func makeSharedDeviceSettings(updatedBy deviceId: UUID) -> SharedDeviceSettings {
        SharedDeviceSettings(
            updatedAt: Date(),
            updatedByDeviceId: deviceId,
            refreshFrequency: refreshFrequency.rawValue,
            mergeIcons: mergeIcons,
            menuBarMetric: menuBarMetric.rawValue,
            enabledProviders: enabledProviders.map(\.rawValue).sorted(),
            providerOrder: providerOrder.map(\.rawValue)
        )
    }

    /// Apply shared settings from another Mac when they are newer than local values.
    /// Returns `true` when any value changed.
    @discardableResult
    public func applySharedDeviceSettingsIfNewer(
        _ shared: SharedDeviceSettings,
        localDeviceId: UUID
    ) -> Bool {
        // Ignore echoes written by this device.
        if shared.updatedByDeviceId == localDeviceId {
            return false
        }

        let localStamp = defaults.object(forKey: "deviceLink.sharedSettingsAppliedAt") as? Date
        if let localStamp, shared.updatedAt <= localStamp {
            return false
        }

        var changed = false

        if let freq = RefreshFrequency(rawValue: shared.refreshFrequency), freq != refreshFrequency {
            refreshFrequency = freq
            changed = true
        }
        if shared.mergeIcons != mergeIcons {
            mergeIcons = shared.mergeIcons
            changed = true
        }
        if let metric = MenuBarMetricPreference(rawValue: shared.menuBarMetric), metric != menuBarMetric {
            menuBarMetric = metric
            changed = true
        }

        let incomingEnabled = Set(shared.enabledProviders.compactMap { UsageProvider(rawValue: $0) })
        if !incomingEnabled.isEmpty, incomingEnabled != enabledProviders {
            enabledProviders = incomingEnabled
            changed = true
        }

        let incomingOrder = shared.providerOrder.compactMap { UsageProvider(rawValue: $0) }
        if !incomingOrder.isEmpty, incomingOrder != providerOrder {
            providerOrder = incomingOrder
            changed = true
        }

        defaults.set(shared.updatedAt, forKey: "deviceLink.sharedSettingsAppliedAt")
        return changed
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
