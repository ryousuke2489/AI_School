#if os(macOS)
import Foundation
import Observation
import CodexBarCore
import Logging

/// Manages usage data fetching and caching for all providers.
@MainActor
@Observable
public final class UsageStore {
    private let logger = Logger(label: "com.steipete.CodexBar.usage")
    private let settingsStore: SettingsStore
    private let deviceLinkStore: DeviceLinkStore
    private var refreshTimer: Timer?

    // MARK: - Observable State

    /// Current usage snapshots per provider.
    public private(set) var snapshots: [UsageProvider: UsageSnapshot] = [:]

    /// Current credits snapshots per provider.
    public private(set) var credits: [UsageProvider: CreditsSnapshot] = [:]

    /// Current cost snapshots per provider.
    public private(set) var costs: [UsageProvider: ProviderCostSnapshot] = [:]

    /// Error messages per provider.
    public private(set) var errors: [UsageProvider: String] = [:]

    /// Whether a refresh is currently in progress.
    public private(set) var isRefreshing: Bool = false

    /// When the last successful refresh completed.
    public private(set) var lastRefreshDate: Date?

    /// Linked Macs discovered via the shared sync folder (includes this device).
    public private(set) var linkedDevices: [LinkedDeviceStatus] = []

    /// Last device-link error message, if any.
    public private(set) var deviceLinkError: String?

    // MARK: - Init

    public init(
        settingsStore: SettingsStore,
        deviceLinkStore: DeviceLinkStore = DeviceLinkStore()
    ) {
        self.settingsStore = settingsStore
        self.deviceLinkStore = deviceLinkStore
        setupRefreshTimer()
    }

    // MARK: - Refresh

    /// Refresh all enabled providers.
    public func refresh(force: Bool = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        logger.info("Starting usage refresh (force: \(force))")

        if settingsStore.deviceLinkEnabled {
            pullSharedSettingsIfNeeded()
        }

        let registry = ProviderDescriptorRegistry.shared
        let context = ProviderFetchContext(forceRefresh: force)

        await withTaskGroup(of: ProviderFetchResult.self) { group in
            for provider in settingsStore.orderedEnabledProviders {
                guard let descriptor = registry.descriptor(for: provider) else { continue }
                group.addTask {
                    await descriptor.fetch(context: context)
                }
            }

            for await result in group {
                switch result.outcome {
                case .success(let snapshot):
                    snapshots[result.provider] = snapshot
                    errors.removeValue(forKey: result.provider)
                    logger.info("Fetched \(result.provider.rawValue) in \(String(format: "%.1f", result.duration))s")

                case .notConfigured:
                    logger.debug("\(result.provider.rawValue) not configured")

                case .error(let message):
                    errors[result.provider] = message
                    logger.warning("Error fetching \(result.provider.rawValue): \(message)")
                }
            }
        }

        lastRefreshDate = Date()

        if settingsStore.deviceLinkEnabled {
            syncDeviceLink()
        } else {
            linkedDevices = []
            deviceLinkError = nil
        }

        logger.info("Usage refresh complete")
    }

    /// Refresh a single provider.
    public func refresh(provider: UsageProvider, force: Bool = false) async {
        let registry = ProviderDescriptorRegistry.shared
        guard let descriptor = registry.descriptor(for: provider) else { return }

        let context = ProviderFetchContext(forceRefresh: force)
        let result = await descriptor.fetch(context: context)

        switch result.outcome {
        case .success(let snapshot):
            snapshots[result.provider] = snapshot
            errors.removeValue(forKey: result.provider)
        case .notConfigured:
            break
        case .error(let message):
            errors[result.provider] = message
        }

        if settingsStore.deviceLinkEnabled {
            syncDeviceLink()
        }
    }

    // MARK: - Accessors

    /// Get the snapshot for a provider.
    public func snapshot(for provider: UsageProvider) -> UsageSnapshot? {
        snapshots[provider]
    }

    /// Check if data is stale for a provider.
    public func isStale(for provider: UsageProvider) -> Bool {
        guard let snapshot = snapshots[provider] else { return true }
        return snapshot.isStale
    }

    /// Get the error message for a provider.
    public func error(for provider: UsageProvider) -> String? {
        errors[provider]
    }

    /// Remote linked Macs only.
    public var remoteLinkedDevices: [LinkedDeviceStatus] {
        linkedDevices.filter { !$0.isLocal }
    }

    /// Summary string for a provider's usage.
    public func summaryLine(for provider: UsageProvider) -> String {
        guard let snapshot = snapshots[provider] else {
            if let error = errors[provider] {
                return "Error: \(error)"
            }
            return "No data"
        }

        var parts: [String] = []

        if let session = snapshot.sessionWindow {
            let pct = Int(session.usedPercentage * 100)
            parts.append("Session: \(pct)%")
            if let reset = session.resetsAt {
                parts.append("resets \(UsageFormatter.resetCountdownDescription(until: reset))")
            }
        }

        if let periodic = snapshot.periodicWindow {
            let pct = Int(periodic.usedPercentage * 100)
            let label = periodic.label ?? "Periodic"
            parts.append("\(label): \(pct)%")
        }

        return parts.isEmpty ? "Connected" : parts.joined(separator: " | ")
    }

    // MARK: - Device Link

    /// Publish local data and reload peer devices from the shared folder.
    public func syncDeviceLink() {
        guard settingsStore.deviceLinkEnabled else {
            linkedDevices = []
            deviceLinkError = nil
            return
        }

        let mode = settingsStore.deviceLinkMode
        let customPath = settingsStore.deviceLinkCustomFolderPath
        let identity = deviceLinkStore.localIdentity()

        do {
            let payload = DeviceLinkPayload(
                identity: identity,
                updatedAt: Date(),
                enabledProviders: settingsStore.orderedEnabledProviders,
                snapshotMap: snapshots
            )
            try deviceLinkStore.publish(
                payload: payload,
                mode: mode,
                customFolderPath: customPath
            )

            if settingsStore.deviceLinkSyncSettings {
                let shared = settingsStore.makeSharedDeviceSettings(updatedBy: identity.deviceId)
                let existing = try? deviceLinkStore.loadSharedSettings(
                    mode: mode,
                    customFolderPath: customPath
                )
                // Avoid refresh ping-pong: only rewrite when preference values actually differ.
                if existing == nil || !Self.sharedSettingsValuesMatch(existing!, shared) {
                    try deviceLinkStore.publishSharedSettings(
                        shared,
                        mode: mode,
                        customFolderPath: customPath
                    )
                }
            }

            linkedDevices = try deviceLinkStore.loadLinkedDevices(
                mode: mode,
                customFolderPath: customPath
            )
            deviceLinkError = nil
            logger.info("Device link synced: \(linkedDevices.count) device(s)")
        } catch {
            deviceLinkError = error.localizedDescription
            logger.warning("Device link sync failed: \(error.localizedDescription)")
        }
    }

    private func pullSharedSettingsIfNeeded() {
        guard settingsStore.deviceLinkSyncSettings else { return }
        do {
            guard let shared = try deviceLinkStore.loadSharedSettings(
                mode: settingsStore.deviceLinkMode,
                customFolderPath: settingsStore.deviceLinkCustomFolderPath
            ) else { return }

            let changed = settingsStore.applySharedDeviceSettingsIfNewer(
                shared,
                localDeviceId: deviceLinkStore.localDeviceId
            )
            if changed {
                updateRefreshTimer()
                logger.info("Applied shared settings from linked Mac")
            }
        } catch {
            // Non-fatal: local refresh should continue even if shared settings are unavailable.
            logger.debug("Shared settings pull skipped: \(error.localizedDescription)")
        }
    }

    private static func sharedSettingsValuesMatch(
        _ lhs: SharedDeviceSettings,
        _ rhs: SharedDeviceSettings
    ) -> Bool {
        lhs.refreshFrequency == rhs.refreshFrequency
            && lhs.mergeIcons == rhs.mergeIcons
            && lhs.menuBarMetric == rhs.menuBarMetric
            && lhs.enabledProviders == rhs.enabledProviders
            && lhs.providerOrder == rhs.providerOrder
    }

    // MARK: - Timer

    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        guard let interval = settingsStore.refreshFrequency.interval else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.refresh()
            }
        }
    }

    /// Update the refresh timer when settings change.
    public func updateRefreshTimer() {
        setupRefreshTimer()
    }
}
#endif
