import Foundation

enum SharedStorageRoot {
    static let appGroupID = "group.com.stillreader.app"
    static let iCloudContainerID = "iCloud.com.stillreader.app"

    static func resolve(fileManager: FileManager = .default) -> (url: URL, usesICloud: Bool) {
        #if os(iOS)
        if let group = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let root = group.appendingPathComponent("Stillreader", isDirectory: true)
            let hasICloud = fileManager.url(forUbiquityContainerIdentifier: iCloudContainerID) != nil
            return (root, hasICloud)
        }
        #endif

        if let container = fileManager.url(forUbiquityContainerIdentifier: iCloudContainerID) {
            let root = container.appendingPathComponent("Documents/Stillreader", isDirectory: true)
            return (root, true)
        }

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return (appSupport.appendingPathComponent("Stillreader", isDirectory: true), false)
    }

    static func makeStorage(fileManager: FileManager = .default) -> (storage: LocalStorageAdapter, usesICloud: Bool) {
        let resolved = resolve(fileManager: fileManager)
        return (LocalStorageAdapter(rootURL: resolved.url, fileManager: fileManager), resolved.usesICloud)
    }
}
