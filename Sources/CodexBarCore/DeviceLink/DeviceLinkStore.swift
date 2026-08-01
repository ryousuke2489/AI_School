import Foundation

/// Resolves and manages the shared folder used to link Macs (e.g. Mac mini + MacBook).
///
/// Privacy notes:
/// - Syncs usage snapshots and optional preference mirrors only.
/// - Does **not** sync API tokens / token accounts.
/// - Data stays in the user's chosen folder (iCloud Drive or custom), never a CodexBar server.
public final class DeviceLinkStore: @unchecked Sendable {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let defaults: UserDefaults
    private let deviceIdKey = "deviceLink.deviceId"

    public init(
        fileManager: FileManager = .default,
        defaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.defaults = defaults
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Identity

    /// Persistent device UUID for this installation.
    public var localDeviceId: UUID {
        if let raw = defaults.string(forKey: deviceIdKey),
           let id = UUID(uuidString: raw) {
            return id
        }
        let id = UUID()
        defaults.set(id.uuidString, forKey: deviceIdKey)
        return id
    }

    public func localIdentity() -> DeviceIdentity {
        DeviceIdentity.currentHost(persistedId: localDeviceId)
    }

    // MARK: - Directory resolution

    /// Resolve the sync root for the given mode.
    public func resolveSyncRoot(
        mode: DeviceLinkMode,
        customFolderPath: String?
    ) throws -> URL {
        switch mode {
        case .iCloudDrive:
            if let iCloud = iCloudDriveCodexBarDirectory() {
                try ensureDirectory(iCloud)
                try ensureDirectory(devicesDirectory(in: iCloud))
                return iCloud
            }
            // Fallback keeps linking usable without iCloud (e.g. tests / Linux CLI).
            let fallback = AppConfig.appSupportDirectory.appendingPathComponent("DeviceLink", isDirectory: true)
            try ensureDirectory(fallback)
            try ensureDirectory(devicesDirectory(in: fallback))
            return fallback

        case .customFolder:
            guard let path = customFolderPath?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !path.isEmpty else {
                throw DeviceLinkError.customFolderMissing
            }
            let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
            guard fileManager.fileExists(atPath: url.path) else {
                throw DeviceLinkError.customFolderMissing
            }
            try ensureDirectory(devicesDirectory(in: url))
            return url
        }
    }

    /// Whether iCloud Drive appears available for CodexBar sync.
    public var isICloudDriveAvailable: Bool {
        iCloudDriveRoot() != nil
    }

    public func iCloudDriveCodexBarDirectory() -> URL? {
        guard let root = iCloudDriveRoot() else { return nil }
        return root.appendingPathComponent("CodexBar", isDirectory: true)
    }

    private func iCloudDriveRoot() -> URL? {
        let home = fileManager.homeDirectoryForCurrentUser
        let mobileDocuments = home
            .appendingPathComponent("Library")
            .appendingPathComponent("Mobile Documents")
            .appendingPathComponent("com~apple~CloudDocs")
        if fileManager.fileExists(atPath: mobileDocuments.path) {
            return mobileDocuments
        }
        return nil
    }

    public func devicesDirectory(in syncRoot: URL) -> URL {
        syncRoot.appendingPathComponent("devices", isDirectory: true)
    }

    public func sharedSettingsURL(in syncRoot: URL) -> URL {
        syncRoot.appendingPathComponent("shared-settings.json")
    }

    public func devicePayloadURL(in syncRoot: URL, deviceId: UUID) -> URL {
        devicesDirectory(in: syncRoot)
            .appendingPathComponent("\(deviceId.uuidString.lowercased()).json")
    }

    // MARK: - Publish / load

    /// Publish this Mac's latest usage payload into the sync folder.
    public func publish(
        payload: DeviceLinkPayload,
        mode: DeviceLinkMode,
        customFolderPath: String?
    ) throws {
        let root = try resolveSyncRoot(mode: mode, customFolderPath: customFolderPath)
        let url = devicePayloadURL(in: root, deviceId: payload.identity.deviceId)
        let data: Data
        do {
            data = try encoder.encode(payload)
        } catch {
            throw DeviceLinkError.encodeFailed
        }
        do {
            try data.write(to: url, options: [.atomic])
            #if os(macOS) || os(Linux)
            try? fileManager.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
            #endif
        } catch {
            throw DeviceLinkError.ioFailed(error.localizedDescription)
        }
    }

    /// Load all device payloads from the sync folder.
    public func loadLinkedDevices(
        mode: DeviceLinkMode,
        customFolderPath: String?
    ) throws -> [LinkedDeviceStatus] {
        let root = try resolveSyncRoot(mode: mode, customFolderPath: customFolderPath)
        let devicesDir = devicesDirectory(in: root)
        let localId = localDeviceId

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: devicesDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw DeviceLinkError.ioFailed(error.localizedDescription)
        }

        var results: [LinkedDeviceStatus] = []
        for fileURL in contents where fileURL.pathExtension.lowercased() == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                let payload = try decoder.decode(DeviceLinkPayload.self, from: data)
                results.append(
                    LinkedDeviceStatus(
                        payload: payload,
                        isLocal: payload.identity.deviceId == localId
                    )
                )
            } catch {
                // Skip corrupt/partial files (common during iCloud hydration).
                continue
            }
        }

        return results.sorted { lhs, rhs in
            if lhs.isLocal != rhs.isLocal { return lhs.isLocal && !rhs.isLocal }
            return lhs.deviceName.localizedCaseInsensitiveCompare(rhs.deviceName) == .orderedAscending
        }
    }

    /// Convenience: remote peers only.
    public func loadRemoteDevices(
        mode: DeviceLinkMode,
        customFolderPath: String?
    ) throws -> [LinkedDeviceStatus] {
        try loadLinkedDevices(mode: mode, customFolderPath: customFolderPath)
            .filter { !$0.isLocal }
    }

    // MARK: - Shared settings

    public func publishSharedSettings(
        _ settings: SharedDeviceSettings,
        mode: DeviceLinkMode,
        customFolderPath: String?
    ) throws {
        let root = try resolveSyncRoot(mode: mode, customFolderPath: customFolderPath)
        let url = sharedSettingsURL(in: root)
        let data: Data
        do {
            data = try encoder.encode(settings)
        } catch {
            throw DeviceLinkError.encodeFailed
        }
        do {
            try data.write(to: url, options: [.atomic])
            #if os(macOS) || os(Linux)
            try? fileManager.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
            #endif
        } catch {
            throw DeviceLinkError.ioFailed(error.localizedDescription)
        }
    }

    public func loadSharedSettings(
        mode: DeviceLinkMode,
        customFolderPath: String?
    ) throws -> SharedDeviceSettings? {
        let root = try resolveSyncRoot(mode: mode, customFolderPath: customFolderPath)
        let url = sharedSettingsURL(in: root)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(SharedDeviceSettings.self, from: data)
        } catch {
            throw DeviceLinkError.decodeFailed(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func ensureDirectory(_ url: URL) throws {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw DeviceLinkError.ioFailed(error.localizedDescription)
        }
    }
}
