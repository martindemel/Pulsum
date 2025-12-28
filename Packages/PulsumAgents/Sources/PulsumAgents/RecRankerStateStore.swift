import Foundation
import os.log
import PulsumData
import PulsumML

public protocol RecRankerStateStoring: Sendable {
    func loadState() -> RecRankerState?
    func saveState(_ state: RecRankerState)
}

public final class RecRankerStateStore: RecRankerStateStoring, @unchecked Sendable {
    public static let schemaVersion = 1

    private let fileURL: URL
    private let fileManager: FileManager
    private let logger = Logger(subsystem: "ai.pulsum", category: "RecRankerStateStore")

    public init(baseDirectory: URL = PulsumData.applicationSupportDirectory,
                fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = baseDirectory.appendingPathComponent("RecRankerState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(Self.schemaVersion).json")
        prepareDirectory(at: directory)
    }

    public func loadState() -> RecRankerState? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(RecRankerState.self, from: data)
            guard state.version == Self.schemaVersion else {
                logger.warning("RecRanker state version mismatch. Expected \(Self.schemaVersion), found \(state.version).")
                return nil
            }
            return state
        } catch {
            logger.error("Failed to load RecRanker state: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    public func saveState(_ state: RecRankerState) {
        guard state.version == Self.schemaVersion else {
            logger.error("Refusing to persist RecRanker state: version mismatch (expected \(Self.schemaVersion), found \(state.version)).")
            return
        }
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
            applyFileProtection()
            excludeFromBackup()
        } catch {
            logger.error("Failed to persist RecRanker state: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func prepareDirectory(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            do {
#if os(iOS)
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
#else
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
#endif
            } catch {
                logger.error("Failed to prepare RecRanker state directory: \(error.localizedDescription, privacy: .public)")
            }
        } else {
#if os(iOS)
            do {
                try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
            } catch {
                logger.error("Failed to update RecRanker state directory protection: \(error.localizedDescription, privacy: .public)")
            }
#endif
        }
    }

    private func applyFileProtection() {
#if os(iOS)
        do {
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
        } catch {
            logger.error("Failed to set file protection on RecRanker state: \(error.localizedDescription, privacy: .public)")
        }
#endif
    }

    private func excludeFromBackup() {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = fileURL
        do {
            try mutableURL.setResourceValues(values)
        } catch {
            logger.error("Failed to mark RecRanker state as backup-excluded: \(error.localizedDescription, privacy: .public)")
        }
    }
}
