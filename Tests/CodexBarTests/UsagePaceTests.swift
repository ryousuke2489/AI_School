import XCTest
@testable import CodexBarCore

final class UsagePaceTests: XCTestCase {

    func testPace_critical() {
        let pace = UsagePace.compute(usedPercentage: 0.96, elapsedFraction: 0.5)
        XCTAssertEqual(pace, .critical)
    }

    func testPace_ahead() {
        let pace = UsagePace.compute(usedPercentage: 0.8, elapsedFraction: 0.3)
        XCTAssertEqual(pace, .ahead)
    }

    func testPace_behind() {
        let pace = UsagePace.compute(usedPercentage: 0.1, elapsedFraction: 0.5)
        XCTAssertEqual(pace, .behind)
    }

    func testPace_onTrack() {
        let pace = UsagePace.compute(usedPercentage: 0.5, elapsedFraction: 0.5)
        XCTAssertEqual(pace, .onTrack)
    }

    func testPace_unknown() {
        let pace = UsagePace.compute(usedPercentage: 0.5, elapsedFraction: 0.0)
        XCTAssertEqual(pace, .unknown)
    }

    func testPace_displayDescription() {
        XCTAssertEqual(UsagePace.onTrack.displayDescription, "On track")
        XCTAssertEqual(UsagePace.critical.displayDescription, "Near limit")
    }

    func testPace_indicator() {
        XCTAssertEqual(UsagePace.onTrack.indicator, "●")
        XCTAssertEqual(UsagePace.critical.indicator, "!")
    }
}
