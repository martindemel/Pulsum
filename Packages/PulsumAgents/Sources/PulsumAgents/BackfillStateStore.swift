import Foundation
import os.log
import PulsumData

protocol BackfillStateStoring: Sendable {
    func loadState() -> BackfillProgress?
    func saveState(_ state: BackfillProgress)
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

final class BackfillStateStore: BackfillStateStoring, @unchecked Sendable {
    private let fileURL: URL
    private let fileManager: FileManager
    private let logger = Logger(subsystem: "ai.pulsum", category: "BackfillStateStore")

    init(baseDirectory: URL = PulsumData.applicationSupportDirectory,
         fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = baseDirectory.appendingPathComponent("BackfillState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(BackfillProgress.schemaVersion).json")
        prepareDirectory(at: directory)
    }

    func loadState() -> BackfillProgress? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(BackfillProgress.self, from: data)
            guard state.version == BackfillProgress.schemaVersion else {
                logger.warning("Backfill state version mismatch. Expected \(BackfillProgress.schemaVersion), found \(state.version). Ignoring persisted state.")
                return nil
            }
            return state
        } catch {
            logger.error("Failed to load backfill state: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func saveState(_ state: BackfillProgress) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
            applyFileProtection()
            excludeFromBackup()
        } catch {
            logger.error("Failed to persist backfill state: \(error.localizedDescription, privacy: .public)")
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
                logger.error("Failed to prepare backfill state directory: \(error.localizedDescription, privacy: .public)")
            }
        } else {
#if os(iOS)
            do {
                try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
            } catch {
                logger.error("Failed to update backfill state directory protection: \(error.localizedDescription, privacy: .public)")
            }
#endif
        }
    }

    private func applyFileProtection() {
#if os(iOS)
        do {
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
        } catch {
            logger.error("Failed to set file protection on backfill state: \(error.localizedDescription, privacy: .public)")
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
            logger.error("Failed to mark backfill state as backup-excluded: \(error.localizedDescription, privacy: .public)")
        }
    }
}
