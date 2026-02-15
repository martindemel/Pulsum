import Foundation
import os.log
import PulsumML

public protocol RecRankerStateStoring: Sendable {
    func loadState() -> RecRankerState?
    func saveState(_ state: RecRankerState)
}

// SAFETY: All file I/O is serialized through `ioQueue`. Immutable properties
// (`fileURL`, `fileManager`, `logger`) are set once in init and never mutated.
public final class RecRankerStateStore: RecRankerStateStoring, @unchecked Sendable {
    public static let schemaVersion = 1

    private let fileURL: URL
    private let fileManager: FileManager
    private let ioQueue = DispatchQueue(label: "ai.pulsum.recranker-state")
    private let logger = Logger(subsystem: "ai.pulsum", category: "RecRankerStateStore")
    private func logError(_ message: String, error: Error) {
        let nsError = error as NSError
        logger.error("\(message) domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
    }

    public init(baseDirectory: URL,
                fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = baseDirectory.appendingPathComponent("RecRankerState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(Self.schemaVersion).json")
        prepareDirectory(at: directory)
    }

    public func loadState() -> RecRankerState? {
        ioQueue.sync {
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
                logError("Failed to load RecRanker state.", error: error)
                return nil
            }
        }
    }

    public func saveState(_ state: RecRankerState) {
        ioQueue.sync {
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
                logError("Failed to persist RecRanker state.", error: error)
            }
        }
    }

    private func prepareDirectory(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            do {
                #if os(iOS)
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])
                #else
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                #endif
            } catch {
                logError("Failed to prepare RecRanker state directory.", error: error)
            }
        } else {
            #if os(iOS)
            do {
                try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
            } catch {
                logError("Failed to update RecRanker state directory protection.", error: error)
            }
            #endif
        }
    }

    private func applyFileProtection() {
        #if os(iOS)
        do {
            try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: fileURL.path)
        } catch {
            logError("Failed to set file protection on RecRanker state.", error: error)
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
            logError("Failed to mark RecRanker state as backup-excluded.", error: error)
        }
    }
}
