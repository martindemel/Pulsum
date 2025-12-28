import Foundation
import os.log
import PulsumData
import PulsumML

protocol EstimatorStateStoring: Sendable {
    func loadState() -> StateEstimatorState?
    func saveState(_ state: StateEstimatorState)
}

final class EstimatorStateStore: EstimatorStateStoring, @unchecked Sendable {
    static let schemaVersion = 1

    private let fileURL: URL
    private let fileManager: FileManager
    private let logger = Logger(subsystem: "ai.pulsum", category: "EstimatorStateStore")

    init(baseDirectory: URL = PulsumData.applicationSupportDirectory,
         fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = baseDirectory.appendingPathComponent("EstimatorState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(Self.schemaVersion).json")
        prepareDirectory(at: directory)
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
            logger.error("Failed to load estimator state: \(error.localizedDescription, privacy: .public)")
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
            logger.error("Failed to persist estimator state: \(error.localizedDescription, privacy: .public)")
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
                logger.error("Failed to prepare estimator state directory: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            #if os(iOS)
            do {
                try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
            } catch {
                logger.error("Failed to update estimator state directory protection: \(error.localizedDescription, privacy: .public)")
            }
            #endif
        }
    }

    private func applyFileProtection() {
        #if os(iOS)
        do {
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
        } catch {
            logger.error("Failed to set file protection on estimator state: \(error.localizedDescription, privacy: .public)")
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
            logger.error("Failed to mark estimator state as backup-excluded: \(error.localizedDescription, privacy: .public)")
        }
    }
}
