import CoreData
import Foundation
import os.log

/// Canonical Pulsum Core Data model loader. Uses the packaged `.momd` from PulsumData resources
/// and exposes a singleton instance so tests and production share the same model pointer.
public enum PulsumManagedObjectModel {
    private static let logger = Logger(subsystem: "ai.pulsum", category: "ManagedObjectModel")

    // NSManagedObjectModel is immutable after loading; safe to reuse across threads for testing/production.
    public nonisolated(unsafe) static let shared: NSManagedObjectModel? = {
        let bundle = Bundle.pulsumDataResources
        let candidates = [
            bundle.url(forResource: "Pulsum", withExtension: "momd"),
            bundle.url(forResource: "Pulsum", withExtension: "mom"),
            bundle.url(forResource: "PulsumCompiled", withExtension: "momd"),
            bundle.url(forResource: "PulsumCompiled", withExtension: "mom"),
            Bundle.main.url(forResource: "Pulsum", withExtension: "momd"),
            Bundle.main.url(forResource: "Pulsum", withExtension: "mom"),
            Bundle.main.url(forResource: "PulsumCompiled", withExtension: "momd"),
            Bundle.main.url(forResource: "PulsumCompiled", withExtension: "mom")
        ].compactMap { $0 }

        for url in candidates {
            if let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
        }

        if let xcdatamodeld = bundle.url(forResource: "Pulsum", withExtension: "xcdatamodeld") {
            if let model = NSManagedObjectModel(contentsOf: xcdatamodeld) {
                return model
            }
            if let versioned = try? FileManager.default.contentsOfDirectory(at: xcdatamodeld,
                                                                            includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension == "xcdatamodel" }),
                let model = NSManagedObjectModel(contentsOf: versioned) {
                return model
            }
            if let versioned = try? FileManager.default.contentsOfDirectory(at: xcdatamodeld,
                                                                            includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension == "xcdatamodel" })?
                .appendingPathComponent("contents"),
                let model = NSManagedObjectModel(contentsOf: versioned) {
                return model
            }
        }

        if let merged = NSManagedObjectModel.mergedModel(from: [bundle]) {
            return merged
        }

        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            if let url = bundle.url(forResource: "Pulsum", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
            if let url = bundle.url(forResource: "Pulsum", withExtension: "mom"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
            if let url = bundle.url(forResource: "PulsumCompiled", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
            if let url = bundle.url(forResource: "PulsumCompiled", withExtension: "mom"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
            if let url = bundle.url(forResource: "Pulsum", withExtension: "xcdatamodeld") {
                if let model = NSManagedObjectModel(contentsOf: url) {
                    return model
                }
                if let versioned = try? FileManager.default.contentsOfDirectory(at: url,
                                                                                includingPropertiesForKeys: nil)
                    .first(where: { $0.pathExtension == "xcdatamodel" }),
                    let model = NSManagedObjectModel(contentsOf: versioned) {
                    return model
                }
                if let versioned = try? FileManager.default.contentsOfDirectory(at: url,
                                                                                includingPropertiesForKeys: nil)
                    .first(where: { $0.pathExtension == "xcdatamodel" })?
                    .appendingPathComponent("contents"),
                    let model = NSManagedObjectModel(contentsOf: versioned) {
                    return model
                }
            }
        }

        logger.critical("PulsumData: NSManagedObjectModel 'Pulsum' not found in bundle resources")
        return nil
    }()
}
