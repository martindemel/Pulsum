import Foundation
import HealthKit
import PulsumData
import PulsumTypes

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
        queue.sync {
            let fileURL = self.url(for: sampleTypeIdentifier)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                try data.write(to: fileURL, options: .atomic)
                self.applyFileProtectionIfAvailable(to: fileURL)
            } catch {
                Diagnostics.log(level: .warn,
                                category: .healthkit,
                                name: "healthkit.anchor.persist.failed",
                                fields: ["type": .safeString(.metadata(sampleTypeIdentifier))],
                                error: error)
            }
        }
    }

    public func removeAnchor(for sampleTypeIdentifier: String) {
        queue.sync {
            let fileURL = self.url(for: sampleTypeIdentifier)
            guard self.fileManager.fileExists(atPath: fileURL.path) else { return }
            do {
                try self.fileManager.removeItem(at: fileURL)
            } catch {
                Diagnostics.log(level: .warn,
                                category: .healthkit,
                                name: "healthkit.anchor.remove.failed",
                                fields: ["type": .safeString(.metadata(sampleTypeIdentifier))],
                                error: error)
            }
        }
    }

    private func url(for identifier: String) -> URL {
        directory.appendingPathComponent(identifier.safeFilenameComponent).appendingPathExtension("anchor")
    }

    private func applyFileProtectionIfAvailable(to url: URL) {
        #if os(iOS)
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
        #endif
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
