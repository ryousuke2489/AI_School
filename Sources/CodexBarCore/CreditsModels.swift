import Foundation

/// Credit balance information for a provider.
public struct CreditsSnapshot: Sendable, Codable {
    /// The provider this snapshot belongs to.
    public let provider: UsageProvider

    /// Current credit balance.
    public let balance: Double

    /// Currency code (e.g. "USD").
    public let currency: String

    /// When this data was fetched.
    public let fetchedAt: Date

    /// Total credits purchased/granted.
    public let totalCredits: Double?

    /// Credits already used.
    public let usedCredits: Double?

    public init(
        provider: UsageProvider,
        balance: Double,
        currency: String = "USD",
        fetchedAt: Date = Date(),
        totalCredits: Double? = nil,
        usedCredits: Double? = nil
    ) {
        self.provider = provider
        self.balance = balance
        self.currency = currency
        self.fetchedAt = fetchedAt
        self.totalCredits = totalCredits
        self.usedCredits = usedCredits
    }
}

/// A single credit usage event.
public struct CreditEvent: Sendable, Codable {
    public let date: Date
    public let amount: Double
    public let service: String
    public let model: String?

    public init(date: Date, amount: Double, service: String, model: String? = nil) {
        self.date = date
        self.amount = amount
        self.service = service
        self.model = model
    }
}
