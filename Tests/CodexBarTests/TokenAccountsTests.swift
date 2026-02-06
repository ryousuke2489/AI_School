import XCTest
@testable import CodexBarCore

final class TokenAccountsTests: XCTestCase {

    func testProviderTokenAccountData_emptyActiveAccount() {
        let data = ProviderTokenAccountData()
        XCTAssertNil(data.activeAccount)
    }

    func testProviderTokenAccountData_activeAccount() {
        let account = ProviderTokenAccount(
            label: "Test",
            token: "sk-123",
            provider: .claude
        )
        let data = ProviderTokenAccountData(accounts: [account], activeIndex: 0)

        XCTAssertNotNil(data.activeAccount)
        XCTAssertEqual(data.activeAccount?.label, "Test")
        XCTAssertEqual(data.activeAccount?.provider, .claude)
    }

    func testProviderTokenAccountData_clampedIndex() {
        let account = ProviderTokenAccount(
            label: "Test",
            token: "sk-123",
            provider: .claude
        )
        let data = ProviderTokenAccountData(accounts: [account], activeIndex: 999)

        XCTAssertEqual(data.clampedActiveIndex(), 0)
        XCTAssertNotNil(data.activeAccount)
    }

    func testProviderTokenAccountData_codable() throws {
        let account = ProviderTokenAccount(
            label: "My API Key",
            token: "sk-test-123",
            provider: .codex
        )
        let original = ProviderTokenAccountData(accounts: [account], activeIndex: 0, version: 1)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProviderTokenAccountData.self, from: encoded)

        XCTAssertEqual(decoded.accounts.count, 1)
        XCTAssertEqual(decoded.accounts[0].label, "My API Key")
        XCTAssertEqual(decoded.accounts[0].provider, .codex)
        XCTAssertEqual(decoded.activeIndex, 0)
        XCTAssertEqual(decoded.version, 1)
    }

    func testFileTokenAccountStore_roundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test-token-accounts-\(UUID().uuidString).json")

        let store = FileTokenAccountStore(fileURL: tempFile)

        let account = ProviderTokenAccount(
            label: "Test Account",
            token: "token-abc",
            provider: .gemini
        )
        let data = ProviderTokenAccountData(accounts: [account], activeIndex: 0, version: 1)

        try store.save(data)
        let loaded = try store.load()

        XCTAssertEqual(loaded.accounts.count, 1)
        XCTAssertEqual(loaded.accounts[0].label, "Test Account")
        XCTAssertEqual(loaded.accounts[0].provider, .gemini)

        // Cleanup
        try? FileManager.default.removeItem(at: tempFile)
    }
}
