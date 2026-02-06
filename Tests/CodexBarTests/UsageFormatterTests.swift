import XCTest
@testable import CodexBarCore

final class UsageFormatterTests: XCTestCase {

    // MARK: - Token Count

    func testTokenCountString_billions() {
        XCTAssertEqual(UsageFormatter.tokenCountString(1_500_000_000), "1.5B")
        XCTAssertEqual(UsageFormatter.tokenCountString(10_000_000_000), "10B")
    }

    func testTokenCountString_millions() {
        XCTAssertEqual(UsageFormatter.tokenCountString(1_500_000), "1.5M")
        XCTAssertEqual(UsageFormatter.tokenCountString(25_000_000), "25M")
    }

    func testTokenCountString_thousands() {
        XCTAssertEqual(UsageFormatter.tokenCountString(1_500), "1.5K")
        XCTAssertEqual(UsageFormatter.tokenCountString(50_000), "50K")
    }

    func testTokenCountString_small() {
        XCTAssertEqual(UsageFormatter.tokenCountString(500), "500")
        XCTAssertEqual(UsageFormatter.tokenCountString(0), "0")
    }

    // MARK: - Usage Line

    func testUsageLine_remaining() {
        XCTAssertEqual(UsageFormatter.usageLine(usedPercentage: 0.75, showRemaining: true), "25% remaining")
        XCTAssertEqual(UsageFormatter.usageLine(usedPercentage: 0.0, showRemaining: true), "100% remaining")
        XCTAssertEqual(UsageFormatter.usageLine(usedPercentage: 1.0, showRemaining: true), "0% remaining")
    }

    func testUsageLine_used() {
        XCTAssertEqual(UsageFormatter.usageLine(usedPercentage: 0.75, showRemaining: false), "75% used")
    }

    // MARK: - Credits

    func testCreditsString() {
        XCTAssertEqual(UsageFormatter.creditsString(100.0), "100.00")
        XCTAssertEqual(UsageFormatter.creditsString(1234.5), "1,234.50")
    }

    func testUsdString() {
        XCTAssertEqual(UsageFormatter.usdString(42.99), "$42.99")
    }

    // MARK: - Reset Countdown

    func testResetCountdownDescription() {
        let now = Date()
        let twoHoursLater = now.addingTimeInterval(2 * 3600 + 1800) // 2h 30m
        let result = UsageFormatter.resetCountdownDescription(until: twoHoursLater, from: now)
        XCTAssertEqual(result, "in 2h 30m")
    }

    func testResetCountdownDescription_minutesOnly() {
        let now = Date()
        let later = now.addingTimeInterval(600) // 10m
        let result = UsageFormatter.resetCountdownDescription(until: later, from: now)
        XCTAssertEqual(result, "in 10m")
    }

    func testResetCountdownDescription_past() {
        let now = Date()
        let past = now.addingTimeInterval(-100)
        XCTAssertEqual(UsageFormatter.resetCountdownDescription(until: past, from: now), "now")
    }

    // MARK: - Text Cleaning

    func testModelDisplayName_stripsDatePattern() {
        XCTAssertEqual(UsageFormatter.modelDisplayName("gpt-4o-20240101"), "gpt-4o")
        XCTAssertEqual(UsageFormatter.modelDisplayName("claude-3.5-sonnet"), "claude-3.5-sonnet")
    }

    func testCleanPlanName() {
        XCTAssertEqual(UsageFormatter.cleanPlanName("  pro  "), "Pro")
    }

    func testTruncatedSingleLine() {
        let long = String(repeating: "a", count: 100)
        let result = UsageFormatter.truncatedSingleLine(long, maxLength: 80)
        XCTAssertEqual(result.count, 80)
        XCTAssertTrue(result.hasSuffix("…"))
    }

    func testTruncatedSingleLine_short() {
        XCTAssertEqual(UsageFormatter.truncatedSingleLine("hello"), "hello")
    }

    func testTruncatedSingleLine_newlines() {
        XCTAssertEqual(UsageFormatter.truncatedSingleLine("hello\nworld"), "hello world")
    }
}
