# CodexBar

**AI Token Limit Monitor for macOS**

*May your tokens never run out.*

CodexBar is a lightweight macOS menu bar application that monitors usage limits across multiple AI coding assistants without requiring you to log into web dashboards.

## Features

- **Multi-provider monitoring** — Track usage across Codex, Claude, Cursor, Gemini, Copilot, and more
- **Menu bar integration** — Dual-bar icon showing session (top) and weekly (bottom) usage at a glance
- **Real-time tracking** — Session-based (5-hour) and weekly quota windows with countdown timers
- **CLI tool** — `codexbar` command for scripts and CI/CD pipelines
- **Privacy-first** — On-device parsing, no data leaves your machine
- **Device Link** — Connect Mac mini and MacBook via iCloud Drive or a custom shared folder (usage + prefs; tokens stay local)
- **Configurable** — Per-provider toggles, refresh intervals, merge/split icon modes

## Requirements

- macOS 14+ (Sonoma)
- Swift 5.9+

## Building from Source

```bash
swift build -c release
```

## Running

```bash
swift run CodexBar
```

## CLI Usage

```bash
# Show usage status for all providers
swift run codexbar-cli status

# Show status for a specific provider
swift run codexbar-cli status --provider claude

# List available providers
swift run codexbar-cli list

# Show cost estimate
swift run codexbar-cli cost --provider claude --days 30

# List Macs linked via the shared device-link folder
swift run codexbar-cli devices --mode custom --folder ~/Dropbox/CodexBar
```

## Device Link (Mac mini + MacBook)

CodexBar can publish each Mac's local usage snapshots into a shared folder so your other Macs can see them.

1. Open **Settings → Devices**
2. Enable **Link Macs via shared folder**
3. Choose **iCloud Drive** (same Apple ID on both Macs) or a **Custom folder** (Dropbox, NAS, `rsync`'d path, etc.)
4. Repeat on the other Mac

What syncs:

- Usage snapshots and enabled-provider lists per device
- Optional preference mirror (refresh interval, display, provider toggles)

What does **not** sync:

- API tokens / token accounts (remain local on each Mac)

CLI listing:

```bash
swift run codexbar-cli devices --mode icloud
```

## Architecture

```
Sources/
├── CodexBarCore/           # Core library (cross-platform)
│   ├── Config/             # App configuration
│   ├── DeviceLink/         # Multi-Mac shared-folder sync
│   ├── Providers/          # Provider implementations
│   │   ├── Claude/         # Claude provider
│   │   ├── Codex/          # OpenAI Codex provider
│   │   ├── Cursor/         # Cursor provider
│   │   ├── Gemini/         # Google Gemini provider
│   │   └── Copilot/        # GitHub Copilot provider
│   ├── RateWindow.swift    # Rate limit window model
│   ├── UsageSnapshot.swift # Point-in-time usage data
│   ├── UsageFormatter.swift# Display formatting utilities
│   ├── UsagePace.swift     # Usage pace computation
│   ├── TokenAccounts.swift # Token account storage
│   ├── CreditsModels.swift # Credit balance models
│   └── CostUsageModels.swift # Token cost models
├── CodexBar/               # macOS menu bar app
│   ├── CodexBarApp.swift   # App entry point
│   ├── StatusItemController.swift # Menu bar management
│   ├── IconRenderer.swift  # Menu bar icon rendering
│   ├── SettingsStore.swift # Preferences management
│   ├── UsageStore.swift    # Usage data management
│   ├── PreferencesView.swift # Settings UI
│   └── MenuContent.swift   # Menu item views
└── CodexBarCLI/            # Command-line tool
    └── CodexBarCLI.swift   # CLI entry point
```

## Supported Providers

| Provider | CLI Name | Session | Periodic | Credits |
|----------|----------|---------|----------|---------|
| OpenAI Codex | `codex` | 5-hour | Weekly | Yes |
| Claude | `claude` | 5-hour | Weekly | Yes |
| Cursor | `cursor` | Requests | Monthly | No |
| Gemini | `gemini` | RPM | Daily | Yes |
| Copilot | `copilot` | Completions | Monthly | No |

## Testing

```bash
swift test
```

## License

MIT

## Credits

Inspired by [CodexBar](https://github.com/steipete/CodexBar) by Peter Steinberger.
