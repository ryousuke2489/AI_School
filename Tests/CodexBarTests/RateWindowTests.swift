import XCTest
@testable import CodexBarCore

final class RateWindowTests: XCTestCase {

    func testRateWindow_clampsPercentage() {
        let window = RateWindow(usedPercentage: 1.5)
        XCTAssertEqual(window.usedPercentage, 1.0)

        let window2 = RateWindow(usedPercentage: -0.5)
        XCTAssertEqual(window2.usedPercentage, 0.0)
    }

    func testRateWindow_remainingPercentage() {
        let window = RateWindow(usedPercentage: 0.75)
        XCTAssertEqual(window.remainingPercentage, 0.25, accuracy: 0.001)
    }

    func testRateWindow_fullInitializer() {
        let reset = Date().addingTimeInterval(3600)
        let window = RateWindow(
            usedPercentage: 0.5,
            resetsAt: reset,
            label: "Session",
            displayDescription: "50% used",
            remaining: 50,
            total: 100
        )

        XCTAssertEqual(window.usedPercentage, 0.5)
        XCTAssertEqual(window.label, "Session")
        XCTAssertEqual(window.remaining, 50)
        XCTAssertEqual(window.total, 100)
        XCTAssertEqual(window.displayDescription, "50% used")
        XCTAssertNotNil(window.resetsAt)
    }

    func testRateWindow_codable() throws {
        let original = RateWindow(
            usedPercentage: 0.42,
            label: "Test",
            remaining: 58,
            total: 100
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RateWindow.self, from: encoded)

        XCTAssertEqual(decoded.usedPercentage, original.usedPercentage, accuracy: 0.001)
        XCTAssertEqual(decoded.label, original.label)
        XCTAssertEqual(decoded.remaining, original.remaining)
        XCTAssertEqual(decoded.total, original.total)
    }
}
