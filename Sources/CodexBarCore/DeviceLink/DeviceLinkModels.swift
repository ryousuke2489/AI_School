import Foundation

/// How device-link sync finds its shared folder.
public enum DeviceLinkMode: String, CaseIterable, Sendable, Codable, Identifiable {
    /// Prefer iCloud Drive (`Mobile Documents/.../CodexBar`), fall back to Application Support sync folder.
    case iCloudDrive = "icloud"
    /// User-selected folder (Dropbox, network share, USB, etc.).
    case customFolder = "custom"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .iCloudDrive: return "iCloud Drive"
        case .customFolder: return "Custom folder"
        }
    }
}

/// Stable identity for this Mac within a device-link sync group.
public struct DeviceIdentity: Sendable, Codable, Equatable, Identifiable {
    public let deviceId: UUID
    public var deviceName: String
    public var modelHint: String?

    public var id: UUID { deviceId }

    public init(
        deviceId: UUID = UUID(),
        deviceName: String,
        modelHint: String? = nil
    ) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.modelHint = modelHint
    }

    /// Build an identity for the current host.
    public static func currentHost(persistedId: UUID? = nil) -> DeviceIdentity {
        let name = ProcessInfo.processInfo.hostName
            .replacingOccurrences(of: ".local", with: "")
        #if os(macOS)
        let model = ProcessInfo.processInfo.environment["DEVICE_MODEL_HINT"]
        #else
        let model: String? = nil
        #endif
        return DeviceIdentity(
            deviceId: persistedId ?? UUID(),
            deviceName: name.isEmpty ? "Unknown Mac" : name,
            modelHint: model
        )
    }
}

/// One device's published usage + preference snapshot in the sync folder.
public struct DeviceLinkPayload: Sendable, Codable, Equatable {
    public var schemaVersion: Int
    public var identity: DeviceIdentity
    public var updatedAt: Date
    public var appVersion: String
    public var enabledProviders: [UsageProvider]
    /// Stored as an array so JSON encoding stays portable across Macs.
    public var snapshots: [UsageSnapshot]

    public init(
        schemaVersion: Int = 1,
        identity: DeviceIdentity,
        updatedAt: Date = Date(),
        appVersion: String = "1.0.0",
        enabledProviders: [UsageProvider] = [],
        snapshots: [UsageSnapshot] = []
    ) {
        self.schemaVersion = schemaVersion
        self.identity = identity
        self.updatedAt = updatedAt
        self.appVersion = appVersion
        self.enabledProviders = enabledProviders
        self.snapshots = snapshots
    }

    public init(
        schemaVersion: Int = 1,
        identity: DeviceIdentity,
        updatedAt: Date = Date(),
        appVersion: String = "1.0.0",
        enabledProviders: [UsageProvider] = [],
        snapshotMap: [UsageProvider: UsageSnapshot]
    ) {
        self.init(
            schemaVersion: schemaVersion,
            identity: identity,
            updatedAt: updatedAt,
            appVersion: appVersion,
            enabledProviders: enabledProviders,
            snapshots: UsageProvider.allCases.compactMap { snapshotMap[$0] }
        )
    }

    public var snapshotMap: [UsageProvider: UsageSnapshot] {
        Dictionary(uniqueKeysWithValues: snapshots.map { ($0.provider, $0) })
    }
}

/// Preference values that may be shared across linked Macs.
public struct SharedDeviceSettings: Sendable, Codable, Equatable {
    public var schemaVersion: Int
    public var updatedAt: Date
    public var updatedByDeviceId: UUID
    public var refreshFrequency: String
    public var mergeIcons: Bool
    public var menuBarMetric: String
    public var enabledProviders: [String]
    public var providerOrder: [String]

    public init(
        schemaVersion: Int = 1,
        updatedAt: Date = Date(),
        updatedByDeviceId: UUID,
        refreshFrequency: String,
        mergeIcons: Bool,
        menuBarMetric: String,
        enabledProviders: [String],
        providerOrder: [String]
    ) {
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.updatedByDeviceId = updatedByDeviceId
        self.refreshFrequency = refreshFrequency
        self.mergeIcons = mergeIcons
        self.menuBarMetric = menuBarMetric
        self.enabledProviders = enabledProviders
        self.providerOrder = providerOrder
    }
}

/// Runtime status for a linked peer device.
public struct LinkedDeviceStatus: Sendable, Identifiable, Equatable {
    public let payload: DeviceLinkPayload
    public let isLocal: Bool

    public var id: UUID { payload.identity.deviceId }
    public var deviceName: String { payload.identity.deviceName }
    public var updatedAt: Date { payload.updatedAt }
    public var isStale: Bool {
        Date().timeIntervalSince(payload.updatedAt) > 900
    }

    public init(payload: DeviceLinkPayload, isLocal: Bool) {
        self.payload = payload
        self.isLocal = isLocal
    }
}

/// Errors raised while reading/writing the device-link sync folder.
public enum DeviceLinkError: Error, LocalizedError, Sendable, Equatable {
    case syncDirectoryUnavailable
    case customFolderMissing
    case encodeFailed
    case decodeFailed(String)
    case ioFailed(String)

    public var errorDescription: String? {
        switch self {
        case .syncDirectoryUnavailable:
            return "Device link sync directory is unavailable"
        case .customFolderMissing:
            return "Custom sync folder does not exist"
        case .encodeFailed:
            return "Failed to encode device link payload"
        case .decodeFailed(let detail):
            return "Failed to decode device link payload: \(detail)"
        case .ioFailed(let detail):
            return "Device link I/O failed: \(detail)"
        }
    }
}
