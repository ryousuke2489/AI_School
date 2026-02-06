import Foundation

/// Thread-safe registry of all provider descriptors.
public final class ProviderDescriptorRegistry: @unchecked Sendable {
    public static let shared = ProviderDescriptorRegistry()

    private let lock = NSLock()
    private var descriptors: [ProviderDescriptor] = []
    private var descriptorsByID: [UsageProvider: ProviderDescriptor] = [:]

    private init() {
        bootstrap()
    }

    /// All registered provider descriptors in order.
    public var all: [ProviderDescriptor] {
        lock.lock()
        defer { lock.unlock() }
        return descriptors
    }

    /// Metadata for all providers.
    public var metadata: [UsageProvider: ProviderMetadata] {
        lock.lock()
        defer { lock.unlock() }
        return descriptorsByID.mapValues { $0.metadata }
    }

    /// Map of CLI names to providers.
    public var cliNameMap: [String: UsageProvider] {
        lock.lock()
        defer { lock.unlock() }
        var map: [String: UsageProvider] = [:]
        for descriptor in descriptors {
            map[descriptor.metadata.cliName] = descriptor.provider
        }
        return map
    }

    /// Look up a descriptor by provider.
    public func descriptor(for provider: UsageProvider) -> ProviderDescriptor? {
        lock.lock()
        defer { lock.unlock() }
        return descriptorsByID[provider]
    }

    /// Register a new provider descriptor.
    public func register(_ descriptor: ProviderDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        descriptors.append(descriptor)
        descriptorsByID[descriptor.provider] = descriptor
    }

    private func bootstrap() {
        let providers: [ProviderDescriptor] = [
            ClaudeProviderDescriptor.make(),
            CodexProviderDescriptor.make(),
            CursorProviderDescriptor.make(),
            GeminiProviderDescriptor.make(),
            CopilotProviderDescriptor.make(),
        ]
        for p in providers {
            descriptors.append(p)
            descriptorsByID[p.provider] = p
        }
    }
}
