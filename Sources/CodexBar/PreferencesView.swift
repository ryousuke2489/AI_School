#if os(macOS)
import SwiftUI
import CodexBarCore

/// The main preferences/settings window.
struct PreferencesView: View {
    let settingsStore: SettingsStore
    let usageStore: UsageStore

    @State private var selectedTab: PreferencesTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            PreferencesGeneralPane(settingsStore: settingsStore)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(PreferencesTab.general)

            PreferencesProvidersPane(
                settingsStore: settingsStore,
                usageStore: usageStore
            )
            .tabItem {
                Label("Providers", systemImage: "cpu")
            }
            .tag(PreferencesTab.providers)

            PreferencesDisplayPane(settingsStore: settingsStore)
                .tabItem {
                    Label("Display", systemImage: "menubar.rectangle")
                }
                .tag(PreferencesTab.display)

            PreferencesDevicesPane(
                settingsStore: settingsStore,
                usageStore: usageStore
            )
            .tabItem {
                Label("Devices", systemImage: "laptopcomputer.and.iphone")
            }
            .tag(PreferencesTab.devices)

            PreferencesAboutPane()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(PreferencesTab.about)
        }
        .frame(width: 520, height: 440)
    }
}

enum PreferencesTab: Hashable {
    case general
    case providers
    case display
    case devices
    case about
}

// MARK: - General Pane

struct PreferencesGeneralPane: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        Form {
            Section("Refresh") {
                Picker("Refresh frequency:", selection: $settingsStore.refreshFrequency) {
                    ForEach(RefreshFrequency.allCases) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $settingsStore.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Providers Pane

struct PreferencesProvidersPane: View {
    @Bindable var settingsStore: SettingsStore
    let usageStore: UsageStore

    var body: some View {
        List {
            ForEach(UsageProvider.allCases) { provider in
                let metadata = settingsStore.metadata(for: provider)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metadata?.displayName ?? provider.rawValue.capitalized)
                            .font(.headline)
                        Text(usageStore.summaryLine(for: provider))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { settingsStore.isProviderEnabled(provider) },
                        set: { _ in settingsStore.toggleProvider(provider) }
                    ))
                    .labelsHidden()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}

// MARK: - Display Pane

struct PreferencesDisplayPane: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        Form {
            Section("Menu Bar") {
                Toggle("Merge all providers into one icon", isOn: $settingsStore.mergeIcons)

                Picker("Show metric:", selection: $settingsStore.menuBarMetric) {
                    Text("Session %").tag(MenuBarMetricPreference.sessionPercentage)
                    Text("Weekly %").tag(MenuBarMetricPreference.weeklyPercentage)
                    Text("Both").tag(MenuBarMetricPreference.both)
                    Text("Icon only").tag(MenuBarMetricPreference.none)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Devices Pane

struct PreferencesDevicesPane: View {
    @Bindable var settingsStore: SettingsStore
    let usageStore: UsageStore

    private let deviceLinkStore = DeviceLinkStore()

    var body: some View {
        Form {
            Section {
                Toggle("Link Macs via shared folder", isOn: $settingsStore.deviceLinkEnabled)
                    .onChange(of: settingsStore.deviceLinkEnabled) { _, enabled in
                        if enabled {
                            usageStore.syncDeviceLink()
                        }
                    }

                Text("Share usage snapshots between Macs (e.g. Mac mini + MacBook) via iCloud Drive or a custom folder. API tokens are never synced.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if settingsStore.deviceLinkEnabled {
                Section("Sync location") {
                    Picker("Mode:", selection: $settingsStore.deviceLinkMode) {
                        ForEach(DeviceLinkMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .onChange(of: settingsStore.deviceLinkMode) { _, _ in
                        usageStore.syncDeviceLink()
                    }

                    if settingsStore.deviceLinkMode == .iCloudDrive {
                        HStack {
                            Text("iCloud Drive")
                            Spacer()
                            Text(deviceLinkStore.isICloudDriveAvailable ? "Available" : "Not found")
                                .foregroundStyle(deviceLinkStore.isICloudDriveAvailable ? .secondary : .orange)
                        }
                        if let path = deviceLinkStore.iCloudDriveCodexBarDirectory()?.path {
                            Text(path)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                    } else {
                        TextField(
                            "Folder path",
                            text: $settingsStore.deviceLinkCustomFolderPath,
                            prompt: Text("~/Dropbox/CodexBar or /Volumes/Shared/CodexBar")
                        )
                        .onSubmit {
                            usageStore.syncDeviceLink()
                        }
                    }
                }

                Section("What to sync") {
                    Toggle("Sync preferences (providers, refresh, display)", isOn: $settingsStore.deviceLinkSyncSettings)
                    Text("Usage snapshots are always published when linking is enabled. API tokens stay on each Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Linked devices") {
                    if let error = usageStore.deviceLinkError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }

                    if usageStore.linkedDevices.isEmpty {
                        Text("No devices found yet. Enable linking on each Mac and refresh.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(usageStore.linkedDevices) { device in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(device.deviceName)
                                        .font(.headline)
                                    if device.isLocal {
                                        Text("This Mac")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if device.isStale {
                                        Text("Stale")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Text(relativeUpdateText(device.updatedAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(providerSummary(for: device))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    Button("Sync Now") {
                        usageStore.syncDeviceLink()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            if settingsStore.deviceLinkEnabled {
                usageStore.syncDeviceLink()
            }
        }
    }

    private func relativeUpdateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private func providerSummary(for device: LinkedDeviceStatus) -> String {
        let names = device.payload.enabledProviders.map(\.rawValue)
        if names.isEmpty { return "No providers reported" }
        return names.joined(separator: ", ")
    }
}

// MARK: - About Pane

struct PreferencesAboutPane: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(.primary)

            Text("CodexBar")
                .font(.title)
                .bold()

            Text("AI Token Limit Monitor")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()

            Text("Track usage limits across multiple AI coding assistants from your menu bar.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Text("May your tokens never run out.")
                .font(.caption)
                .italic()
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}
#endif
