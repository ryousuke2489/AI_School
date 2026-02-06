import XCTest
@testable import CodexBarCore

final class ClaudeUsageParserTests: XCTestCase {

    func testParse_validJSON() throws {
        let json: [String: Any] = [
            "session": [
                "usedPercentage": 0.6,
                "remaining": 40,
                "total": 100,
                "description": "Session limit"
            ],
            "weekly": [
                "usedPercentage": 0.3,
                "remaining": 700,
                "total": 1000,
                "resetsAt": "2025-01-15T00:00:00Z"
            ],
            "account": [
                "email": "user@example.com",
                "organization": "TestOrg",
                "plan": "pro",
                "loginMethod": "oauth"
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: json)
        let snapshot = try ClaudeUsageParser.parse(data: data, provider: .claude)

        XCTAssertEqual(snapshot.provider, .claude)
        XCTAssertEqual(snapshot.sessionWindow?.usedPercentage, 0.6, accuracy: 0.001)
        XCTAssertEqual(snapshot.sessionWindow?.remaining, 40)
        XCTAssertEqual(snapshot.sessionWindow?.total, 100)
        XCTAssertEqual(snapshot.periodicWindow?.usedPercentage, 0.3, accuracy: 0.001)
        XCTAssertEqual(snapshot.identity?.email, "user@example.com")
        XCTAssertEqual(snapshot.identity?.organization, "TestOrg")
        XCTAssertEqual(snapshot.identity?.plan, "pro")
    }

    func testParse_minimalJSON() throws {
        let json: [String: Any] = [:]
        let data = try JSONSerialization.data(withJSONObject: json)
        let snapshot = try ClaudeUsageParser.parse(data: data, provider: .claude)

        XCTAssertEqual(snapshot.provider, .claude)
        XCTAssertNil(snapshot.sessionWindow)
        XCTAssertNil(snapshot.periodicWindow)
        XCTAssertNil(snapshot.identity)
    }

    func testParse_dailyInsteadOfWeekly() throws {
        let json: [String: Any] = [
            "daily": [
                "usedPercentage": 0.4
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: json)
        let snapshot = try ClaudeUsageParser.parse(data: data, provider: .claude)

        XCTAssertEqual(snapshot.periodicWindow?.usedPercentage, 0.4, accuracy: 0.001)
        XCTAssertEqual(snapshot.periodicWindow?.label, "Daily")
    }

    func testParse_invalidData() {
        let data = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try ClaudeUsageParser.parse(data: data, provider: .claude))
    }
}
