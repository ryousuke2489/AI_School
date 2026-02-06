import Foundation

/// A point-in-time snapshot of usage data for a single provider.
public struct UsageSnapshot: Sendable, Codable {
    /// The provider this snapshot belongs to.
    public let provider: UsageProvider

    /// Session-level rate window (e.g. 5-hour sliding window).
    public let sessionWindow: RateWindow?

    /// Longer-term rate window (e.g. weekly or monthly).
    public let periodicWindow: RateWindow?

    /// When this snapshot was captured.
    public let fetchedAt: Date

    /// Account identity info (email, org, plan).
    public let identity: ProviderIdentity?

    /// Optional error message from the last fetch attempt.
    public let errorMessage: String?

    /// Whether this data should be considered stale.
    public var isStale: Bool {
        Date().timeIntervalSince(fetchedAt) > 600  // 10 minutes
    }

    public init(
        provider: UsageProvider,
        sessionWindow: RateWindow? = nil,
        periodicWindow: RateWindow? = nil,
        fetchedAt: Date = Date(),
        identity: ProviderIdentity? = nil,
        errorMessage: String? = nil
    ) {
        self.provider = provider
        self.sessionWindow = sessionWindow
        self.periodicWindow = periodicWindow
        self.fetchedAt = fetchedAt
        self.identity = identity
        self.errorMessage = errorMessage
    }
}

/// Identity information for a provider account.
public struct ProviderIdentity: Sendable, Codable {
    public let email: String?
    public let organization: String?
    public let plan: String?
    public let loginMethod: String?

    public init(
        email: String? = nil,
        organization: String? = nil,
        plan: String? = nil,
        loginMethod: String? = nil
    ) {
        self.email = email
        self.organization = organization
        self.plan = plan
        self.loginMethod = loginMethod
    }
}
