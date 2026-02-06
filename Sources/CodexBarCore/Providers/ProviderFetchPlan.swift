import Foundation

/// A fetch plan defining how to retrieve usage data from a provider.
public struct ProviderFetchPlan: Sendable {
    /// The fetch function to execute.
    private let _execute: @Sendable (UsageProvider, ProviderFetchContext) async throws -> UsageSnapshot

    public init(execute: @escaping @Sendable (UsageProvider, ProviderFetchContext) async throws -> UsageSnapshot) {
        self._execute = execute
    }

    /// Execute the fetch plan.
    public func execute(provider: UsageProvider, context: ProviderFetchContext) async throws -> UsageSnapshot {
        try await _execute(provider, context)
    }
}

/// Factory methods for common fetch plan patterns.
extension ProviderFetchPlan {

    /// A fetch plan that reads usage from a local CLI tool's cache files.
    public static func cliCache(
        cacheDirectory: @escaping @Sendable () -> URL?,
        parser: @escaping @Sendable (Data, UsageProvider) throws -> UsageSnapshot
    ) -> ProviderFetchPlan {
        ProviderFetchPlan { provider, context in
            guard let cacheDir = cacheDirectory() else {
                throw ProviderFetchError.notConfigured
            }

            let cacheFile = cacheDir.appendingPathComponent("\(provider.rawValue)-usage.json")
            guard FileManager.default.fileExists(atPath: cacheFile.path) else {
                throw ProviderFetchError.notConfigured
            }

            let data = try Data(contentsOf: cacheFile)
            return try parser(data, provider)
        }
    }

    /// A fetch plan that queries an HTTP API endpoint.
    public static func httpAPI(
        urlBuilder: @escaping @Sendable (UsageProvider) -> URL?,
        headers: @escaping @Sendable (UsageProvider) -> [String: String],
        parser: @escaping @Sendable (Data, UsageProvider) throws -> UsageSnapshot
    ) -> ProviderFetchPlan {
        ProviderFetchPlan { provider, context in
            guard let url = urlBuilder(provider) else {
                throw ProviderFetchError.notConfigured
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = context.timeout
            for (key, value) in headers(provider) {
                request.setValue(value, forHTTPHeaderField: key)
            }

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw ProviderFetchError.fetchFailed("HTTP \(statusCode)")
            }

            return try parser(data, provider)
        }
    }

    /// A no-op fetch plan that always reports as not configured.
    public static var notConfigured: ProviderFetchPlan {
        ProviderFetchPlan { _, _ in
            throw ProviderFetchError.notConfigured
        }
    }
}
