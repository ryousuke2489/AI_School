import Foundation

/// Outcome of a provider fetch operation.
public enum ProviderFetchOutcome: Sendable {
    case success(UsageSnapshot)
    case notConfigured
    case error(String)
}

/// Result type for provider fetch with additional context.
public struct ProviderFetchResult: Sendable {
    public let provider: UsageProvider
    public let outcome: ProviderFetchOutcome
    public let duration: TimeInterval

    public init(provider: UsageProvider, outcome: ProviderFetchOutcome, duration: TimeInterval) {
        self.provider = provider
        self.outcome = outcome
        self.duration = duration
    }
}

/// Configuration for how a provider's token cost data is obtained.
public struct ProviderTokenCostConfig: Sendable {
    public let supportsTokenCost: Bool
    public let unavailableMessage: String?

    public init(supportsTokenCost: Bool = false, unavailableMessage: String? = nil) {
        self.supportsTokenCost = supportsTokenCost
        self.unavailableMessage = unavailableMessage
    }
}

/// A descriptor fully defining a provider's capabilities and fetch behavior.
public struct ProviderDescriptor: Sendable {
    public let provider: UsageProvider
    public let metadata: ProviderMetadata
    public let tokenCostConfig: ProviderTokenCostConfig
    public let fetchPlan: ProviderFetchPlan

    public init(
        provider: UsageProvider,
        metadata: ProviderMetadata,
        tokenCostConfig: ProviderTokenCostConfig = ProviderTokenCostConfig(),
        fetchPlan: ProviderFetchPlan
    ) {
        self.provider = provider
        self.metadata = metadata
        self.tokenCostConfig = tokenCostConfig
        self.fetchPlan = fetchPlan
    }

    /// Execute the fetch plan and return the outcome.
    public func fetchOutcome(context: ProviderFetchContext) async -> ProviderFetchOutcome {
        let start = Date()
        do {
            let snapshot = try await fetchPlan.execute(provider: provider, context: context)
            return .success(snapshot)
        } catch let error as ProviderFetchError {
            switch error {
            case .notConfigured:
                return .notConfigured
            case .fetchFailed(let message):
                return .error(message)
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }

    /// Fetch usage data and return a full result with timing.
    public func fetch(context: ProviderFetchContext) async -> ProviderFetchResult {
        let start = Date()
        let outcome = await fetchOutcome(context: context)
        let duration = Date().timeIntervalSince(start)
        return ProviderFetchResult(provider: provider, outcome: outcome, duration: duration)
    }
}

/// Errors that can occur during provider fetch.
public enum ProviderFetchError: Error, Sendable {
    case notConfigured
    case fetchFailed(String)
}

/// Context passed to fetch operations.
public struct ProviderFetchContext: Sendable {
    public let forceRefresh: Bool
    public let timeout: TimeInterval

    public init(forceRefresh: Bool = false, timeout: TimeInterval = 30) {
        self.forceRefresh = forceRefresh
        self.timeout = timeout
    }
}
