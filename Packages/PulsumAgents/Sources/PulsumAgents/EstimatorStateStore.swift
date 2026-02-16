import Foundation
import os.log
import PulsumML

protocol EstimatorStateStoring: Sendable {
    func loadState() async -> StateEstimatorState?
    func saveState(_ state: StateEstimatorState) async
}

actor EstimatorStateStore: EstimatorStateStoring {
    static let schemaVersion = 1

    private let fileURL: URL
    private let fileManager: FileManager
    private nonisolated let logger = Logger(subsystem: "ai.pulsum", category: "EstimatorStateStore")
    private nonisolated func logError(_ message: String, error: Error) {
        let nsError = error as NSError
        logger.error("\(message) domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
    }

    init(baseDirectory: URL,
         fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = baseDirectory.appendingPathComponent("EstimatorState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(Self.schemaVersion).json")
        Self.prepareDirectory(at: directory, fileManager: fileManager, logger: logger)
    }

    func loadState() -> StateEstimatorState? {
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

    func saveState(_ state: StateEstimatorState) {
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

    private static func prepareDirectory(at url: URL, fileManager: FileManager, logger: Logger) {
        if !fileManager.fileExists(atPath: url.path) {
            do {
                #if os(iOS)
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])
                #else
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                #endif
            } catch {
                let nsError = error as NSError
                logger.error("Failed to prepare estimator state directory. domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
            }
        } else {
            #if os(iOS)
            do {
                try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
            } catch {
                let nsError = error as NSError
                logger.error("Failed to update estimator state directory protection. domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
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
