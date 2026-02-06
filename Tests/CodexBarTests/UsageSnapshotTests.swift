import XCTest
@testable import CodexBarCore

final class UsageSnapshotTests: XCTestCase {

    func testUsageSnapshot_isStale() {
        // Fresh snapshot
        let fresh = UsageSnapshot(provider: .claude, fetchedAt: Date())
        XCTAssertFalse(fresh.isStale)

        // Stale snapshot (fetched 15 minutes ago)
        let stale = UsageSnapshot(
            provider: .claude,
            fetchedAt: Date().addingTimeInterval(-900)
        )
        XCTAssertTrue(stale.isStale)
    }

    func testUsageSnapshot_withWindows() {
        let session = RateWindow(usedPercentage: 0.6, label: "Session")
        let weekly = RateWindow(usedPercentage: 0.3, label: "Weekly")
        let identity = ProviderIdentity(email: "test@example.com", plan: "Pro")

        let snapshot = UsageSnapshot(
            provider: .codex,
            sessionWindow: session,
            periodicWindow: weekly,
            identity: identity
        )

        XCTAssertEqual(snapshot.provider, .codex)
        XCTAssertEqual(snapshot.sessionWindow?.usedPercentage, 0.6)
        XCTAssertEqual(snapshot.periodicWindow?.usedPercentage, 0.3)
        XCTAssertEqual(snapshot.identity?.email, "test@example.com")
        XCTAssertEqual(snapshot.identity?.plan, "Pro")
        XCTAssertNil(snapshot.errorMessage)
    }

    func testUsageSnapshot_codable() throws {
        let snapshot = UsageSnapshot(
            provider: .claude,
            sessionWindow: RateWindow(usedPercentage: 0.5, label: "Session"),
            periodicWindow: RateWindow(usedPercentage: 0.2, label: "Weekly"),
            fetchedAt: Date(),
            identity: ProviderIdentity(email: "test@test.com"),
            errorMessage: nil
        )

        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(UsageSnapshot.self, from: encoded)

        XCTAssertEqual(decoded.provider, snapshot.provider)
        XCTAssertEqual(decoded.sessionWindow?.usedPercentage, snapshot.sessionWindow?.usedPercentage)
        XCTAssertEqual(decoded.identity?.email, snapshot.identity?.email)
    }
}
