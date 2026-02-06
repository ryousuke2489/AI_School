import ArgumentParser
import Foundation
import CodexBarCore

@main
struct CodexBarCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "codexbar",
        abstract: "CodexBar CLI - AI Token Limit Monitor",
        version: "1.0.0",
        subcommands: [
            StatusCommand.self,
            ListCommand.self,
            CostCommand.self,
        ],
        defaultSubcommand: StatusCommand.self
    )
}

// MARK: - Status Command

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show current usage status for all configured providers"
    )

    @Option(name: .shortAndLong, help: "Filter by provider name")
    var provider: String?

    @Flag(name: .shortAndLong, help: "Show detailed output")
    var verbose: Bool = false

    func run() async throws {
        let registry = ProviderDescriptorRegistry.shared
        let context = ProviderFetchContext(forceRefresh: true, timeout: 15)

        let providers: [ProviderDescriptor]
        if let providerName = provider {
            guard let p = registry.cliNameMap[providerName],
                  let desc = registry.descriptor(for: p) else {
                print("Unknown provider: \(providerName)")
                print("Available providers: \(registry.cliNameMap.keys.sorted().joined(separator: ", "))")
                throw ExitCode.failure
            }
            providers = [desc]
        } else {
            providers = registry.all
        }

        print("CodexBar - AI Usage Status")
        print(String(repeating: "=", count: 40))
        print()

        for descriptor in providers {
            let result = await descriptor.fetch(context: context)
            let name = descriptor.metadata.displayName

            switch result.outcome {
            case .success(let snapshot):
                printSnapshot(name: name, snapshot: snapshot, verbose: verbose)
            case .notConfigured:
                print("\(name): Not configured")
            case .error(let message):
                print("\(name): Error - \(message)")
            }
            print()
        }
    }

    private func printSnapshot(name: String, snapshot: UsageSnapshot, verbose: Bool) {
        print("\(name)")
        print(String(repeating: "-", count: name.count))

        if let session = snapshot.sessionWindow {
            let pct = Int(session.usedPercentage * 100)
            let label = session.label ?? "Session"
            print("  \(label): \(pct)% used (\(UsageFormatter.usageLine(usedPercentage: session.usedPercentage)))")

            if let reset = session.resetsAt {
                print("    Resets: \(UsageFormatter.resetDescription(for: reset))")
            }

            if verbose, let remaining = session.remaining, let total = session.total {
                print("    Remaining: \(remaining)/\(total)")
            }
        }

        if let periodic = snapshot.periodicWindow {
            let pct = Int(periodic.usedPercentage * 100)
            let label = periodic.label ?? "Periodic"
            print("  \(label): \(pct)% used (\(UsageFormatter.usageLine(usedPercentage: periodic.usedPercentage)))")

            if let reset = periodic.resetsAt {
                print("    Resets: \(UsageFormatter.resetDescription(for: reset))")
            }
        }

        if verbose, let identity = snapshot.identity {
            if let email = identity.email {
                print("  Account: \(email)")
            }
            if let org = identity.organization {
                print("  Organization: \(org)")
            }
            if let plan = identity.plan {
                print("  Plan: \(UsageFormatter.cleanPlanName(plan))")
            }
        }

        if snapshot.isStale {
            print("  (stale data)")
        }
    }
}

// MARK: - List Command

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available providers"
    )

    func run() {
        let registry = ProviderDescriptorRegistry.shared
        print("Available Providers:")
        print(String(repeating: "=", count: 40))
        print()

        for descriptor in registry.all {
            let meta = descriptor.metadata
            let primary = meta.isPrimaryProvider ? " [primary]" : ""
            let credits = meta.supportsCredits ? " [credits]" : ""
            print("  \(meta.cliName.padding(toLength: 12, withPad: " ", startingAt: 0)) \(meta.displayName)\(primary)\(credits)")

            if let url = meta.dashboardURL {
                print("    Dashboard: \(url.absoluteString)")
            }
        }
    }
}

// MARK: - Cost Command

struct CostCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cost",
        abstract: "Show estimated token costs for a provider"
    )

    @Option(name: .shortAndLong, help: "Provider name (e.g., codex, claude)")
    var provider: String = "claude"

    @Option(name: .shortAndLong, help: "Number of days to look back")
    var days: Int = 30

    func run() async throws {
        let registry = ProviderDescriptorRegistry.shared
        guard let p = registry.cliNameMap[provider],
              let desc = registry.descriptor(for: p) else {
            print("Unknown provider: \(provider)")
            print("Available providers: \(registry.cliNameMap.keys.sorted().joined(separator: ", "))")
            throw ExitCode.failure
        }

        let meta = desc.metadata
        if !desc.tokenCostConfig.supportsTokenCost {
            print("\(meta.displayName): Token cost tracking not supported")
            if let msg = desc.tokenCostConfig.unavailableMessage {
                print("  \(msg)")
            }
            return
        }

        print("\(meta.displayName) - Cost Estimate (last \(days) days)")
        print(String(repeating: "=", count: 40))
        print()
        print("  Token cost data requires provider-specific log parsing.")
        print("  Configure local JSONL log paths in settings to enable.")
    }
}
