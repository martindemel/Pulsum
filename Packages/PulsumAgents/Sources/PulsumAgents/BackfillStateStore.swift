import Foundation
import os.log

protocol BackfillStateStoring: Sendable {
    func loadState() -> BackfillProgress?
    func saveState(_ state: BackfillProgress)
}

// SAFETY: FileManager is not formally Sendable. Wrapping in a struct allows passing to
// Sendable-constrained contexts. FileManager.default is documented as thread-safe.
private struct SendableFileManager: @unchecked Sendable {
    let value: FileManager
}

struct BackfillProgress: Codable, Sendable {
    static let schemaVersion = 1

    var version: Int = BackfillProgress.schemaVersion
    var warmStartCompletedTypes: Set<String> = []
    var fullBackfillCompletedTypes: Set<String> = []
    var earliestProcessedByType: [String: Date] = [:]

    mutating func recordWarmStart(for typeIdentifier: String, earliestDate: Date, calendar: Calendar) {
        let normalized = calendar.startOfDay(for: earliestDate)
        warmStartCompletedTypes.insert(typeIdentifier)
        earliestProcessedByType[typeIdentifier] = minDate(normalized, earliestProcessedByType[typeIdentifier], calendar: calendar)
    }

    mutating func recordProcessedRange(for typeIdentifier: String, startDate: Date, targetStartDate: Date, calendar: Calendar) {
        let normalized = calendar.startOfDay(for: startDate)
        earliestProcessedByType[typeIdentifier] = minDate(normalized, earliestProcessedByType[typeIdentifier], calendar: calendar)
        if normalized <= calendar.startOfDay(for: targetStartDate) {
            fullBackfillCompletedTypes.insert(typeIdentifier)
        }
    }

    mutating func markFullBackfillComplete(for typeIdentifier: String) {
        fullBackfillCompletedTypes.insert(typeIdentifier)
    }

    mutating func removeProgress(for typeIdentifier: String) {
        warmStartCompletedTypes.remove(typeIdentifier)
        fullBackfillCompletedTypes.remove(typeIdentifier)
        earliestProcessedByType.removeValue(forKey: typeIdentifier)
    }

    func earliestProcessedDate(for typeIdentifier: String, calendar: Calendar) -> Date? {
        earliestProcessedByType[typeIdentifier].map { calendar.startOfDay(for: $0) }
    }

    private func minDate(_ lhs: Date, _ rhs: Date?, calendar: Calendar) -> Date {
        guard let rhs else { return lhs }
        return calendar.startOfDay(for: min(lhs, rhs))
    }
}

final class BackfillStateStore: BackfillStateStoring, Sendable {
    private let queue = DispatchQueue(label: "ai.pulsum.backfillStateStore", qos: .utility)
    private let fileURL: URL
    private let fileManager: SendableFileManager
    private var fm: FileManager { fileManager.value }
    private let logger = Logger(subsystem: "ai.pulsum", category: "BackfillStateStore")
    private func logError(_ message: String, error: Error) {
        let nsError = error as NSError
        logger.error("\(message) domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
    }

    init(baseDirectory: URL,
         fileManager: FileManager = .default) {
        self.fileManager = SendableFileManager(value: fileManager)
        let directory = baseDirectory.appendingPathComponent("BackfillState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(BackfillProgress.schemaVersion).json")
        queue.sync {
            prepareDirectory(at: directory)
        }
    }

    func loadState() -> BackfillProgress? {
        queue.sync {
            guard fm.fileExists(atPath: fileURL.path) else { return nil }
            do {
                let data = try Data(contentsOf: fileURL)
                let state = try JSONDecoder().decode(BackfillProgress.self, from: data)
                guard state.version == BackfillProgress.schemaVersion else {
                    logger.warning("Backfill state version mismatch. Expected \(BackfillProgress.schemaVersion), found \(state.version). Ignoring persisted state.")
                    return nil
                }
                return state
            } catch {
                logError("Failed to load backfill state.", error: error)
                return nil
            }
        }
    }

    func saveState(_ state: BackfillProgress) {
        queue.sync {
            do {
                let data = try JSONEncoder().encode(state)
                try data.write(to: fileURL, options: .atomic)
                applyFileProtection()
                excludeFromBackup()
            } catch {
                logError("Failed to persist backfill state.", error: error)
            }
        }
    }

    private func prepareDirectory(at url: URL) {
        if !fm.fileExists(atPath: url.path) {
            do {
                #if os(iOS)
                try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])
                #else
                try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                #endif
            } catch {
                logError("Failed to prepare backfill state directory.", error: error)
            }
        } else {
            #if os(iOS)
            do {
                try fm.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
            } catch {
                logError("Failed to update backfill state directory protection.", error: error)
            }
            #endif
        }
    }

    private func applyFileProtection() {
        #if os(iOS)
        do {
            try fm.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: fileURL.path)
        } catch {
            logError("Failed to set file protection on backfill state.", error: error)
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
            logError("Failed to mark backfill state as backup-excluded.", error: error)
        }
    }
}
