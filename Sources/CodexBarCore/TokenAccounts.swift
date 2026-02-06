import Foundation

/// A single provider token/account entry.
public struct ProviderTokenAccount: Sendable, Codable, Identifiable {
    public let id: UUID
    public let label: String
    public let token: String
    public let provider: UsageProvider
    public let createdAt: Date
    public var lastUsedAt: Date?

    public init(
        id: UUID = UUID(),
        label: String,
        token: String,
        provider: UsageProvider,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.label = label
        self.token = token
        self.provider = provider
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

/// Collection of token accounts with active index tracking.
public struct ProviderTokenAccountData: Sendable, Codable {
    public var accounts: [ProviderTokenAccount]
    public var activeIndex: Int
    public var version: Int

    public init(accounts: [ProviderTokenAccount] = [], activeIndex: Int = 0, version: Int = 1) {
        self.accounts = accounts
        self.activeIndex = activeIndex
        self.version = version
    }

    /// The currently active account, or nil if none.
    public var activeAccount: ProviderTokenAccount? {
        let idx = clampedActiveIndex()
        guard idx < accounts.count else { return nil }
        return accounts[idx]
    }

    /// Ensure the active index is within bounds.
    public func clampedActiveIndex() -> Int {
        guard !accounts.isEmpty else { return 0 }
        return min(max(activeIndex, 0), accounts.count - 1)
    }
}

/// Protocol for persisting token accounts.
public protocol ProviderTokenAccountStoring: Sendable {
    func load() throws -> ProviderTokenAccountData
    func save(_ data: ProviderTokenAccountData) throws
}

/// File-based token account storage.
public final class FileTokenAccountStore: ProviderTokenAccountStoring, @unchecked Sendable {
    private let fileURL: URL

    public init(fileURL: URL = AppConfig.tokenAccountsFile) {
        self.fileURL = fileURL
    }

    public func load() throws -> ProviderTokenAccountData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ProviderTokenAccountData()
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ProviderTokenAccountData.self, from: data)
    }

    public func save(_ data: ProviderTokenAccountData) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: fileURL, options: [.atomic])

        // Set secure permissions (owner read/write only)
        #if os(macOS) || os(Linux)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
        #endif
    }
}
