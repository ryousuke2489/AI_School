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

            PreferencesAboutPane()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(PreferencesTab.about)
        }
        .frame(width: 520, height: 400)
    }
}

enum PreferencesTab: Hashable {
    case general
    case providers
    case display
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
