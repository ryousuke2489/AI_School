import XCTest
@testable import CodexBarCore

final class DeviceLinkTests: XCTestCase {

    private var tempRoot: URL!
    private var defaults: UserDefaults!
    private var store: DeviceLinkStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("codexbar-device-link-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

        defaults = UserDefaults(suiteName: "codexbar.tests.device-link.\(UUID().uuidString)")!
        store = DeviceLinkStore(defaults: defaults)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
        defaults.removePersistentDomain(forName: defaults.suiteName!)
        try super.tearDownWithError()
    }

    func testLocalDeviceIdPersists() {
        let first = store.localDeviceId
        let second = DeviceLinkStore(defaults: defaults).localDeviceId
        XCTAssertEqual(first, second)
    }

    func testPublishAndLoadRoundTrip() throws {
        let identity = DeviceIdentity(
            deviceId: store.localDeviceId,
            deviceName: "MacBook-Test"
        )
        let snapshot = UsageSnapshot(
            provider: .claude,
            sessionWindow: RateWindow(
                usedPercentage: 0.42,
                label: "Session"
            ),
            fetchedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let payload = DeviceLinkPayload(
            identity: identity,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
            enabledProviders: [.claude, .codex],
            snapshotMap: [.claude: snapshot]
        )

        try store.publish(
            payload: payload,
            mode: .customFolder,
            customFolderPath: tempRoot.path
        )

        let devices = try store.loadLinkedDevices(
            mode: .customFolder,
            customFolderPath: tempRoot.path
        )

        XCTAssertEqual(devices.count, 1)
        XCTAssertTrue(devices[0].isLocal)
        XCTAssertEqual(devices[0].deviceName, "MacBook-Test")
        XCTAssertEqual(devices[0].payload.enabledProviders, [.claude, .codex])
        XCTAssertEqual(
            devices[0].payload.snapshotMap[.claude]?.sessionWindow?.usedPercentage,
            0.42,
            accuracy: 0.0001
        )
    }

    func testRemoteDeviceIsNotMarkedLocal() throws {
        let remoteId = UUID()
        let remotePayload = DeviceLinkPayload(
            identity: DeviceIdentity(deviceId: remoteId, deviceName: "Mac-mini"),
            enabledProviders: [.cursor],
            snapshots: []
        )
        try store.publish(
            payload: remotePayload,
            mode: .customFolder,
            customFolderPath: tempRoot.path
        )

        let remotes = try store.loadRemoteDevices(
            mode: .customFolder,
            customFolderPath: tempRoot.path
        )
        XCTAssertEqual(remotes.count, 1)
        XCTAssertEqual(remotes[0].deviceName, "Mac-mini")
        XCTAssertFalse(remotes[0].isLocal)
    }

    func testSharedSettingsRoundTrip() throws {
        let settings = SharedDeviceSettings(
            updatedByDeviceId: store.localDeviceId,
            refreshFrequency: "5m",
            mergeIcons: true,
            menuBarMetric: "both",
            enabledProviders: ["claude", "codex"],
            providerOrder: ["codex", "claude"]
        )

        try store.publishSharedSettings(
            settings,
            mode: .customFolder,
            customFolderPath: tempRoot.path
        )

        let loaded = try store.loadSharedSettings(
            mode: .customFolder,
            customFolderPath: tempRoot.path
        )

        XCTAssertEqual(loaded, settings)
    }

    func testCustomFolderMissingThrows() {
        XCTAssertThrowsError(
            try store.resolveSyncRoot(
                mode: .customFolder,
                customFolderPath: "/tmp/does-not-exist-\(UUID().uuidString)"
            )
        ) { error in
            XCTAssertEqual(error as? DeviceLinkError, .customFolderMissing)
        }
    }

    func testDeviceIdentityCurrentHostUsesPersistedId() {
        let id = UUID()
        let identity = DeviceIdentity.currentHost(persistedId: id)
        XCTAssertEqual(identity.deviceId, id)
        XCTAssertFalse(identity.deviceName.isEmpty)
    }
}
