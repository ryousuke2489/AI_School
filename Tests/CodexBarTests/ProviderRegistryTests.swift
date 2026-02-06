import XCTest
@testable import CodexBarCore

final class ProviderRegistryTests: XCTestCase {

    func testRegistry_hasAllProviders() {
        let registry = ProviderDescriptorRegistry.shared
        let all = registry.all

        // We register 5 providers: claude, codex, cursor, gemini, copilot
        XCTAssertEqual(all.count, 5)
    }

    func testRegistry_lookupByProvider() {
        let registry = ProviderDescriptorRegistry.shared

        let claude = registry.descriptor(for: .claude)
        XCTAssertNotNil(claude)
        XCTAssertEqual(claude?.metadata.displayName, "Claude")
        XCTAssertEqual(claude?.metadata.cliName, "claude")
    }

    func testRegistry_cliNameMap() {
        let registry = ProviderDescriptorRegistry.shared
        let map = registry.cliNameMap

        XCTAssertEqual(map["claude"], .claude)
        XCTAssertEqual(map["codex"], .codex)
        XCTAssertEqual(map["cursor"], .cursor)
        XCTAssertEqual(map["gemini"], .gemini)
        XCTAssertEqual(map["copilot"], .copilot)
    }

    func testRegistry_metadata() {
        let registry = ProviderDescriptorRegistry.shared
        let metadata = registry.metadata

        XCTAssertEqual(metadata.count, 5)
        XCTAssertNotNil(metadata[.claude])
        XCTAssertNotNil(metadata[.codex])
    }
}
