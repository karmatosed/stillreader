import Foundation

enum StorageLocation: Equatable, Sendable {
    case iCloudDrive
    case appGroup
    case localFallback
}

enum SharedStorageRoot {
    static let appGroupID = "group.com.stillreader.app"
    static let iCloudContainerID = "iCloud.com.stillreader.app"

    /// Primary storage for the main app — app group is for the share extension only.
    static func resolvePrimary(fileManager: FileManager = .default) -> (url: URL, location: StorageLocation) {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return (appSupport.appendingPathComponent("Stillreader", isDirectory: true), .localFallback)
    }

    /// Share extension always writes here; main app imports into primary on sync.
    static func appGroupRoot(fileManager: FileManager = .default) -> URL? {
        #if os(iOS)
        return fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("Stillreader", isDirectory: true)
        #else
        return nil
        #endif
    }

    static func makeStorage(fileManager: FileManager = .default) -> (storage: LocalStorageAdapter, location: StorageLocation) {
        let resolved = resolvePrimary(fileManager: fileManager)
        return (LocalStorageAdapter(rootURL: resolved.url, fileManager: fileManager), resolved.location)
    }
}
