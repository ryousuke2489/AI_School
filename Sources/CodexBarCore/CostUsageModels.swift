import Foundation

/// Token cost data for a provider.
public struct ProviderCostSnapshot: Sendable, Codable {
    public let provider: UsageProvider
    public let totalCostUSD: Double
    public let periodDays: Int
    public let breakdown: [ModelCostEntry]
    public let fetchedAt: Date

    public init(
        provider: UsageProvider,
        totalCostUSD: Double,
        periodDays: Int = 30,
        breakdown: [ModelCostEntry] = [],
        fetchedAt: Date = Date()
    ) {
        self.provider = provider
        self.totalCostUSD = totalCostUSD
        self.periodDays = periodDays
        self.breakdown = breakdown
        self.fetchedAt = fetchedAt
    }
}

/// Cost entry for a specific model.
public struct ModelCostEntry: Sendable, Codable {
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let costUSD: Double

    public init(model: String, inputTokens: Int, outputTokens: Int, costUSD: Double) {
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.costUSD = costUSD
    }
}
