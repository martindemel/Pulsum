import Foundation
import HealthKit
import PulsumData

/// Persists HealthKit query anchors on-device with complete file protection.
public final class HealthKitAnchorStore {
    private let directory: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "ai.pulsum.healthkit.anchorstore")

    public init(directory: URL = PulsumData.healthAnchorsDirectory, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    public func anchor(for sampleTypeIdentifier: String) -> HKQueryAnchor? {
        queue.sync {
            let fileURL = url(for: sampleTypeIdentifier)
            guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        }
    }

    public func store(anchor: HKQueryAnchor, for sampleTypeIdentifier: String) {
        queue.async {
            let fileURL = self.url(for: sampleTypeIdentifier)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                try data.write(to: fileURL, options: .atomic)
                try self.applyFileProtection(to: fileURL)
            } catch {
                assertionFailure("Failed to persist HKQueryAnchor for \(sampleTypeIdentifier): \(error)")
            }
        }
    }

    public func removeAnchor(for sampleTypeIdentifier: String) {
        queue.async {
            let fileURL = self.url(for: sampleTypeIdentifier)
            guard self.fileManager.fileExists(atPath: fileURL.path) else { return }
            do {
                try self.fileManager.removeItem(at: fileURL)
            } catch {
                assertionFailure("Failed to remove HKQueryAnchor for \(sampleTypeIdentifier): \(error)")
            }
        }
    }

    private func url(for identifier: String) -> URL {
        directory.appendingPathComponent(identifier.safeFilenameComponent).appendingPathExtension("anchor")
    }

    private func applyFileProtection(to url: URL) throws {
        try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
}

private extension String {
    /// Sanitizes the identifier for safe filesystem usage.
    var safeFilenameComponent: String {
        let invalidCharacters = CharacterSet(charactersIn: ":/")
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

extension HealthKitAnchorStore: @unchecked Sendable {}
