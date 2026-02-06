#if os(macOS)
import AppKit
import SwiftUI
import CodexBarCore
import Logging

/// Protocol defining the status item controller interface.
@MainActor
protocol StatusItemControlling: AnyObject {
    func attachMenus()
    func detachMenus()
    func refreshIcons()
}

/// Manages the macOS menu bar status item(s) for CodexBar.
@MainActor
final class StatusItemController: NSObject, StatusItemControlling, NSMenuDelegate {
    private let settingsStore: SettingsStore
    private let usageStore: UsageStore
    private let logger = Logger(label: "com.steipete.CodexBar.statusItem")

    /// The primary status item (combined mode).
    private var primaryStatusItem: NSStatusItem?

    /// Per-provider status items (individual mode).
    private var providerStatusItems: [UsageProvider: NSStatusItem] = [:]

    /// Per-provider menus.
    private var providerMenus: [UsageProvider: NSMenu] = [:]

    init(settingsStore: SettingsStore, usageStore: UsageStore) {
        self.settingsStore = settingsStore
        self.usageStore = usageStore
        super.init()
        attachMenus()
    }

    // MARK: - Menu Management

    func attachMenus() {
        detachMenus()

        if settingsStore.mergeIcons {
            attachMergedMenu()
        } else {
            attachIndividualMenus()
        }
    }

    func detachMenus() {
        if let item = primaryStatusItem {
            NSStatusBar.system.removeStatusItem(item)
            primaryStatusItem = nil
        }
        for (_, item) in providerStatusItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        providerStatusItems.removeAll()
        providerMenus.removeAll()
    }

    func refreshIcons() {
        if settingsStore.mergeIcons {
            updateMergedIcon()
        } else {
            for provider in settingsStore.orderedEnabledProviders {
                updateProviderIcon(provider)
            }
        }
    }

    // MARK: - Merged Mode

    private func attachMergedMenu() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = IconRenderer.makeIcon(
            style: .combined,
            sessionPercentage: 0,
            weeklyPercentage: 0,
            isStale: true
        )
        statusItem.button?.image?.isTemplate = true

        let menu = buildCombinedMenu()
        statusItem.menu = menu
        primaryStatusItem = statusItem
    }

    private func updateMergedIcon() {
        guard let button = primaryStatusItem?.button else { return }

        // Use the highest usage across all providers
        var maxSession: Double = 0
        var maxWeekly: Double = 0
        var anyStale = false

        for provider in settingsStore.orderedEnabledProviders {
            if let snapshot = usageStore.snapshot(for: provider) {
                if let session = snapshot.sessionWindow {
                    maxSession = max(maxSession, session.usedPercentage)
                }
                if let periodic = snapshot.periodicWindow {
                    maxWeekly = max(maxWeekly, periodic.usedPercentage)
                }
                if snapshot.isStale { anyStale = true }
            } else {
                anyStale = true
            }
        }

        button.image = IconRenderer.makeIcon(
            style: .combined,
            sessionPercentage: maxSession,
            weeklyPercentage: maxWeekly,
            isStale: anyStale
        )
        button.image?.isTemplate = true

        // Update the menu
        primaryStatusItem?.menu = buildCombinedMenu()
    }

    private func buildCombinedMenu() -> NSMenu {
        let menu = NSMenu(title: "CodexBar")
        menu.delegate = self

        for provider in settingsStore.orderedEnabledProviders {
            let metadata = settingsStore.metadata(for: provider)
            let title = metadata?.displayName ?? provider.rawValue.capitalized
            let summary = usageStore.summaryLine(for: provider)

            let headerItem = NSMenuItem(title: "\(title)", action: nil, keyEquivalent: "")
            headerItem.attributedTitle = makeAttributedTitle(title: title, isHeader: true)
            menu.addItem(headerItem)

            let summaryItem = NSMenuItem(title: "  \(summary)", action: nil, keyEquivalent: "")
            menu.addItem(summaryItem)

            addWindowMenuItems(for: provider, to: menu)
            menu.addItem(NSMenuItem.separator())
        }

        addCommonMenuItems(to: menu)
        return menu
    }

    // MARK: - Individual Mode

    private func attachIndividualMenus() {
        for provider in settingsStore.orderedEnabledProviders.reversed() {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            let iconStyle = settingsStore.metadata(for: provider)?.iconStyle ?? .combined

            statusItem.button?.image = IconRenderer.makeIcon(
                style: iconStyle,
                sessionPercentage: 0,
                weeklyPercentage: 0,
                isStale: true
            )
            statusItem.button?.image?.isTemplate = true

            let menu = buildProviderMenu(for: provider)
            statusItem.menu = menu

            providerStatusItems[provider] = statusItem
            providerMenus[provider] = menu
        }
    }

    private func updateProviderIcon(_ provider: UsageProvider) {
        guard let statusItem = providerStatusItems[provider] else { return }
        let snapshot = usageStore.snapshot(for: provider)
        let iconStyle = settingsStore.metadata(for: provider)?.iconStyle ?? .combined

        statusItem.button?.image = IconRenderer.makeIcon(
            style: iconStyle,
            sessionPercentage: snapshot?.sessionWindow?.usedPercentage ?? 0,
            weeklyPercentage: snapshot?.periodicWindow?.usedPercentage ?? 0,
            isStale: snapshot?.isStale ?? true
        )
        statusItem.button?.image?.isTemplate = true

        // Update menu
        let menu = buildProviderMenu(for: provider)
        statusItem.menu = menu
        providerMenus[provider] = menu
    }

    private func buildProviderMenu(for provider: UsageProvider) -> NSMenu {
        let metadata = settingsStore.metadata(for: provider)
        let title = metadata?.displayName ?? provider.rawValue.capitalized
        let menu = NSMenu(title: title)
        menu.delegate = self

        let headerItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        headerItem.attributedTitle = makeAttributedTitle(title: title, isHeader: true)
        menu.addItem(headerItem)

        let summary = usageStore.summaryLine(for: provider)
        menu.addItem(NSMenuItem(title: summary, action: nil, keyEquivalent: ""))

        addWindowMenuItems(for: provider, to: menu)
        menu.addItem(NSMenuItem.separator())
        addCommonMenuItems(to: menu)

        return menu
    }

    // MARK: - Menu Item Helpers

    private func addWindowMenuItems(for provider: UsageProvider, to menu: NSMenu) {
        guard let snapshot = usageStore.snapshot(for: provider) else { return }

        if let session = snapshot.sessionWindow {
            let pct = Int(session.usedPercentage * 100)
            let label = session.label ?? "Session"
            let item = NSMenuItem(
                title: "  \(label): \(pct)% used",
                action: nil,
                keyEquivalent: ""
            )
            menu.addItem(item)

            if let reset = session.resetsAt {
                let resetStr = UsageFormatter.resetCountdownDescription(until: reset)
                menu.addItem(NSMenuItem(title: "    Resets \(resetStr)", action: nil, keyEquivalent: ""))
            }

            if let remaining = session.remaining, let total = session.total {
                menu.addItem(NSMenuItem(title: "    \(remaining)/\(total) remaining", action: nil, keyEquivalent: ""))
            }
        }

        if let periodic = snapshot.periodicWindow {
            let pct = Int(periodic.usedPercentage * 100)
            let label = periodic.label ?? "Periodic"
            menu.addItem(NSMenuItem(title: "  \(label): \(pct)% used", action: nil, keyEquivalent: ""))

            if let reset = periodic.resetsAt {
                let resetStr = UsageFormatter.resetCountdownDescription(until: reset)
                menu.addItem(NSMenuItem(title: "    Resets \(resetStr)", action: nil, keyEquivalent: ""))
            }
        }

        if let identity = snapshot.identity {
            if let email = identity.email {
                menu.addItem(NSMenuItem(title: "  Account: \(email)", action: nil, keyEquivalent: ""))
            }
            if let plan = identity.plan {
                menu.addItem(NSMenuItem(title: "  Plan: \(UsageFormatter.cleanPlanName(plan))", action: nil, keyEquivalent: ""))
            }
        }
    }

    private func addCommonMenuItems(to menu: NSMenu) {
        let refreshItem = NSMenuItem(
            title: "Refresh Now",
            action: #selector(refreshAction),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        if let lastRefresh = usageStore.lastRefreshDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            menu.addItem(NSMenuItem(
                title: "Last updated: \(formatter.string(from: lastRefresh))",
                action: nil,
                keyEquivalent: ""
            ))
        }

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit CodexBar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Attributed Titles

    private func makeAttributedTitle(title: String, isHeader: Bool) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = isHeader
            ? [.font: NSFont.boldSystemFont(ofSize: 13)]
            : [.font: NSFont.systemFont(ofSize: 12)]
        return NSAttributedString(string: title, attributes: attributes)
    }

    // MARK: - Actions

    @objc private func refreshAction() {
        Task {
            await usageStore.refresh(force: true)
            refreshIcons()
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - NSMenuDelegate

    nonisolated func menuWillOpen(_ menu: NSMenu) {
        Task { @MainActor in
            refreshIcons()
        }
    }
}
#endif
