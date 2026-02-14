import Foundation
import SwiftData
import os.log

public enum DataStackError: LocalizedError {
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

public struct StoragePaths: Sendable {
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
                throw DataStackError.directoryCreationFailed(
                    url: URL(fileURLWithPath: "ApplicationSupport"),
                    underlying: CocoaError(.fileNoSuchFile)
                )
            }
            baseURL = url
        }
        #else
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw DataStackError.directoryCreationFailed(
                url: URL(fileURLWithPath: "ApplicationSupport"),
                underlying: CocoaError(.fileNoSuchFile)
            )
        }
        #endif

        applicationSupport = baseURL.appendingPathComponent("Pulsum", isDirectory: true)
        sqliteStoreURL = applicationSupport.appendingPathComponent("Pulsum.sqlite")
        vectorIndexDirectory = applicationSupport.appendingPathComponent("VectorIndex", isDirectory: true)
        healthAnchorsDirectory = applicationSupport.appendingPathComponent("Anchors", isDirectory: true)
    }
}

/// SwiftData-backed persistent storage for Pulsum.
///
/// Created at the App layer and injected into the view hierarchy
/// (via `.modelContainer()`) and into agents (via their init).
public final class DataStack: Sendable {
    public let container: ModelContainer
    public let storagePaths: StoragePaths
    public let backupSecurityIssue: BackupSecurityIssue?

    private static let logger = Logger(subsystem: "ai.pulsum", category: "DataStack")

    /// All SwiftData model types managed by Pulsum.
    public static let modelTypes: [any PersistentModel.Type] = [
        SDJournalEntry.self,
        SDDailyMetrics.self,
        SDBaseline.self,
        SDFeatureVector.self,
        SDMicroMoment.self,
        SDRecommendationEvent.self,
        SDLibraryIngest.self,
        SDUserPrefs.self,
        SDConsentState.self,
    ]

    public init(appGroupIdentifier: String? = nil) throws {
        let paths = try StoragePaths(appGroup: appGroupIdentifier)
        self.storagePaths = paths

        try DataStack.prepareDirectories(paths: paths)

        self.backupSecurityIssue = DataStack.applyBackupExclusion(to: [
            paths.applicationSupport,
            paths.vectorIndexDirectory,
            paths.healthAnchorsDirectory,
        ])

        let schema = Schema(DataStack.modelTypes)
        let config = ModelConfiguration("Pulsum", schema: schema, url: paths.sqliteStoreURL)

        do {
            self.container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            throw DataStackError.storeInitializationFailed(underlying: error)
        }
    }

    // MARK: - Directory Preparation

    private static func prepareDirectories(paths: StoragePaths) throws {
        let fileManager = FileManager.default
        #if os(iOS)
        let protectionAttributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUnlessOpen,
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
                    throw DataStackError.directoryCreationFailed(url: directory, underlying: error)
                }
            } else if !protectionAttributes.isEmpty {
                try fileManager.setAttributes(protectionAttributes, ofItemAtPath: directory.path)
            }
        }
    }

    // MARK: - Backup Exclusion

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
}
