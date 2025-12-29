import Foundation
import CoreData
import os.log

public enum PulsumDataError: LocalizedError {
    case storeInitializationFailed(underlying: Error)
    case directoryCreationFailed(url: URL, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case let .storeInitializationFailed(underlying):
            return "Failed to initialize persistent stores: \(underlying.localizedDescription)"
        case let .directoryCreationFailed(url, underlying):
            return "Unable to create directory at \(url.path): \(underlying.localizedDescription)"
        }
    }
}

public struct BackupSecurityIssue: Equatable, Sendable {
    public let url: URL
    public let reason: String
}

public struct StoragePaths {
    public let applicationSupport: URL
    public let sqliteStoreURL: URL
    public let vectorIndexDirectory: URL
    public let healthAnchorsDirectory: URL

    public init(appGroup: String? = nil) throws {
        let fileManager = FileManager.default
        #if os(iOS)
        let baseURL: URL
        if let appGroup, let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            baseURL = containerURL
        } else {
            guard let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw PulsumDataError.directoryCreationFailed(url: URL(fileURLWithPath: "ApplicationSupport"), underlying: CocoaError(.fileNoSuchFile))
            }
            baseURL = url
        }
        #else
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw PulsumDataError.directoryCreationFailed(url: URL(fileURLWithPath: "ApplicationSupport"), underlying: CocoaError(.fileNoSuchFile))
        }
        #endif

        applicationSupport = baseURL.appendingPathComponent("Pulsum", isDirectory: true)
        sqliteStoreURL = applicationSupport.appendingPathComponent("Pulsum.sqlite")
        vectorIndexDirectory = applicationSupport.appendingPathComponent("VectorIndex", isDirectory: true)
        healthAnchorsDirectory = applicationSupport.appendingPathComponent("Anchors", isDirectory: true)
    }
}

public final class DataStack {
    public static let shared = DataStack()

    public let container: NSPersistentContainer
    public let storagePaths: StoragePaths
    public private(set) var backupSecurityIssue: BackupSecurityIssue?

    private let fileManager: FileManager
    private static let logger = Logger(subsystem: "ai.pulsum", category: "DataStack")

    public init(fileManager: FileManager = .default, appGroupIdentifier: String? = nil) {
        self.fileManager = fileManager
        do {
            storagePaths = try StoragePaths(appGroup: appGroupIdentifier)
        } catch {
            fatalError("Pulsum data directories could not be resolved: \(error)")
        }

        do {
            try DataStack.prepareDirectories(paths: storagePaths, fileManager: fileManager)
        } catch {
            fatalError("Pulsum data directories could not be created: \(error)")
        }

        let managedObjectModel = DataStack.loadManagedObjectModel()
        container = NSPersistentContainer(name: "Pulsum", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription(url: storagePaths.sqliteStoreURL)
        description.type = NSSQLiteStoreType
#if os(iOS)
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
#endif
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        // Exclude PHI from iCloud backups
        backupSecurityIssue = DataStack.applyBackupExclusion(to: [
            storagePaths.applicationSupport,
            storagePaths.vectorIndexDirectory,
            storagePaths.healthAnchorsDirectory
        ])

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.transactionAuthor = "PulsumApp"
    }

    public func newBackgroundContext(name: String = "Pulsum.Background") -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.name = name
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.transactionAuthor = name
        return context
    }

    public func performBackgroundTask(_ block: @Sendable @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    private static func prepareDirectories(paths: StoragePaths, fileManager: FileManager) throws {
        #if os(iOS)
        let protectionAttributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.complete
        ]
        #else
        let protectionAttributes: [FileAttributeKey: Any] = [:]
        #endif

        for directory in [paths.applicationSupport, paths.vectorIndexDirectory, paths.healthAnchorsDirectory] {
            if !fileManager.fileExists(atPath: directory.path) {
                do {
                    let attributes = protectionAttributes.isEmpty ? nil : protectionAttributes
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: attributes)
                } catch {
                    throw PulsumDataError.directoryCreationFailed(url: directory, underlying: error)
                }
            } else if !protectionAttributes.isEmpty {
                try fileManager.setAttributes(protectionAttributes, ofItemAtPath: directory.path)
            }
        }
    }

    private static func applyBackupExclusion(to urls: [URL]) -> BackupSecurityIssue? {
        var issue: BackupSecurityIssue?
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        for var url in urls {
            do {
                try url.setResourceValues(resourceValues)
            } catch {
                let nsError = error as NSError
                logger.error("Failed to exclude \(url.path, privacy: .public) from backup. domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
                if issue == nil {
                    issue = BackupSecurityIssue(url: url, reason: "domain=\(nsError.domain) code=\(nsError.code)")
                }
            }
        }
        return issue
    }

#if DEBUG
    static func debugApplyBackupExclusion(to urls: [URL]) -> BackupSecurityIssue? {
        applyBackupExclusion(to: urls)
    }
#endif

    private static func loadManagedObjectModel() -> NSManagedObjectModel {
        PulsumManagedObjectModel.shared
    }
}

extension DataStack: @unchecked Sendable {}
