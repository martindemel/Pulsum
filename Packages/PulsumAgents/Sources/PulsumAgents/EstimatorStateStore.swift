import Foundation
import os.log
import PulsumML

protocol EstimatorStateStoring: Sendable {
    func loadState() -> StateEstimatorState?
    func saveState(_ state: StateEstimatorState)
}

// SAFETY: All file I/O is serialized through `ioQueue`. Immutable properties
// (`fileURL`, `fileManager`, `logger`) are set once in init and never mutated.
final class EstimatorStateStore: EstimatorStateStoring, @unchecked Sendable {
    static let schemaVersion = 1

    private let fileURL: URL
    private let fileManager: FileManager
    private let ioQueue = DispatchQueue(label: "ai.pulsum.estimatorstate.io")
    private let logger = Logger(subsystem: "ai.pulsum", category: "EstimatorStateStore")
    private func logError(_ message: String, error: Error) {
        let nsError = error as NSError
        logger.error("\(message) domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
    }

    init(baseDirectory: URL,
         fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = baseDirectory.appendingPathComponent("EstimatorState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(Self.schemaVersion).json")
        prepareDirectory(at: directory)
    }

    func loadState() -> StateEstimatorState? {
        ioQueue.sync {
            guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
            do {
                let data = try Data(contentsOf: fileURL)
                let state = try JSONDecoder().decode(StateEstimatorState.self, from: data)
                guard state.version == Self.schemaVersion else {
                    logger.warning("Estimator state version mismatch. Expected \(Self.schemaVersion), found \(state.version). Ignoring persisted state.")
                    return nil
                }
                return state
            } catch {
                logError("Failed to load estimator state.", error: error)
                return nil
            }
        }
    }

    func saveState(_ state: StateEstimatorState) {
        ioQueue.sync {
            guard state.version == Self.schemaVersion else {
                logger.error("Refusing to persist estimator state: version mismatch (expected \(Self.schemaVersion), found \(state.version)).")
                return
            }
            do {
                let data = try JSONEncoder().encode(state)
                try data.write(to: fileURL, options: .atomic)
                applyFileProtection()
                excludeFromBackup()
            } catch {
                logError("Failed to persist estimator state.", error: error)
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
                logError("Failed to prepare estimator state directory.", error: error)
            }
        } else {
            #if os(iOS)
            do {
                try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
            } catch {
                logError("Failed to update estimator state directory protection.", error: error)
            }
            #endif
        }
    }

    private func applyFileProtection() {
        #if os(iOS)
        do {
            try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: fileURL.path)
        } catch {
            logError("Failed to set file protection on estimator state.", error: error)
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
            logError("Failed to mark estimator state as backup-excluded.", error: error)
        }
    }
}
