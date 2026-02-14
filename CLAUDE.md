# CodexBar - AI Token Limit Monitor for macOS

## Project Overview

CodexBar is a Swift-based macOS menu bar application that monitors AI service token usage limits across multiple providers (Claude, Codex, Cursor, Gemini, Copilot).

## Tech Stack

- **Language**: Swift 5.9+
- **Platform**: macOS 14+ (Sonoma)
- **Build System**: Swift Package Manager (SPM)
- **Dependencies**: swift-log (1.5.0+), swift-argument-parser (1.3.0+)

## Project Structure

```
Sources/
├── CodexBarCore/     # Core library (cross-platform) - models, providers, formatting
├── CodexBar/         # macOS menu bar app - UI, preferences, status bar
└── CodexBarCLI/      # Command-line tool
Tests/
└── CodexBarTests/    # Unit tests
```

## Key Commands

```bash
swift build            # Build the project
swift build -c release # Build for release
swift test             # Run all tests
swift run CodexBar     # Run the macOS app
swift run codexbar-cli # Run the CLI tool
```

## Architecture Notes

- **Providers**: Each AI provider has a `ProviderDescriptor` in `Sources/CodexBarCore/Providers/`
- **Rate Windows**: Session-based (5-hour) and periodic (weekly/monthly/daily) tracking via `RateWindow.swift`
- **Registry**: `ProviderDescriptorRegistry.swift` manages all provider descriptors
- **Settings**: macOS UserDefaults via `SettingsStore.swift`, app config in `AppConfig.swift`
- **Strict Concurrency**: Enabled for main targets

## Agent Team Guidelines

When working as part of an agent team on this project:

- Each team member should own distinct files/modules to avoid edit conflicts
- Provider implementations are independent - safe to work on in parallel
- Core models (RateWindow, UsageSnapshot, etc.) are shared - coordinate changes
- Always run `swift test` after changes to verify nothing is broken
- The `CodexBarCore` module is cross-platform; avoid macOS-specific APIs there
