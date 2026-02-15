import Foundation
import SwiftData
import CryptoKit
import PulsumML
import PulsumTypes

public struct LibraryImporterConfiguration {
    public let bundle: Bundle
    public let subdirectory: String?
    public let fileExtension: String

    public init(bundle: Bundle = .main, subdirectory: String? = "json database", fileExtension: String = "json") {
        self.bundle = bundle
        self.subdirectory = subdirectory
        self.fileExtension = fileExtension
    }
}

public enum LibraryImporterError: LocalizedError {
    case missingResources
    case decodingFailed(underlying: Error)
    case indexingFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .missingResources:
            return "No recommendation library resources were found in the application bundle."
        case let .decodingFailed(underlying):
            return "Unable to parse recommendation library: \(underlying.localizedDescription)"
        case let .indexingFailed(underlying):
            return "Unable to index recommendation library: \(underlying.localizedDescription)"
        }
    }
}

public final class LibraryImporter {
    private let configuration: LibraryImporterConfiguration
    private let vectorIndex: VectorIndexProviding
    private let modelContainer: ModelContainer
    private let stateLock = NSLock()
    private var _lastImportHadDeferredEmbeddings = false
    public var lastImportHadDeferredEmbeddings: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _lastImportHadDeferredEmbeddings
    }

    private func setLastImportHadDeferredEmbeddings(_ value: Bool) {
        stateLock.lock()
        _lastImportHadDeferredEmbeddings = value
        stateLock.unlock()
    }

    public init(configuration: LibraryImporterConfiguration = LibraryImporterConfiguration(),
                vectorIndex: VectorIndexProviding,
                modelContainer: ModelContainer) {
        self.configuration = configuration
        self.vectorIndex = vectorIndex
        self.modelContainer = modelContainer
    }

    public func ingestIfNeeded() async throws {
        setLastImportHadDeferredEmbeddings(false)
        let urls = discoverLibraryURLs()
        guard !urls.isEmpty else {
            Diagnostics.log(level: .info,
                            category: .library,
                            name: "library.import.skip",
                            fields: ["reason": .safeString(.stage("missing_resources", allowed: ["missing_resources"]))])
            return
        }

        var decodedCount = 0
        var indexedCount = 0
        var payloadCount = 0
        let span = Diagnostics.span(category: .library,
                                    name: "library.import",
                                    fields: ["resource_count": .int(urls.count)],
                                    level: .info)
        let monitor = DiagnosticsStallMonitor(category: .library,
                                              name: "library.import",
                                              traceId: nil,
                                              thresholdSeconds: 20,
                                              initialFields: ["resource_count": .int(urls.count)])
        await monitor.start()

        do {
            let resources = try await Self.loadResourcesAsync(from: urls)
            decodedCount = resources.count
            await monitor.heartbeat(progressFields: ["decoded_count": .int(decodedCount)])
            guard !resources.isEmpty else {
                await monitor.stop(finalFields: ["decoded_count": .int(decodedCount)])
                span.end(additionalFields: [
                    "decoded_count": .int(decodedCount),
                    "inserted_count": .int(0),
                    "indexed_count": .int(0)
                ], error: nil)
                return
            }

            let context = ModelContext(modelContainer)

            var payloads: [MicroMomentIndexPayload] = []
            var updates: [LibraryIngestUpdate] = []
            for resource in resources {
                let outcome = try self.process(resource: resource, context: context)
                payloads.append(contentsOf: outcome.payloads)
                if let update = outcome.ingestUpdate {
                    updates.append(update)
                }
            }

            payloadCount = payloads.count
            await monitor.heartbeat(progressFields: ["payload_count": .int(payloadCount)])

            if !payloads.isEmpty {
                do {
                    try await upsertIndexEntries(payloads)
                    indexedCount = payloadCount
                } catch {
                    if let embeddingError = error as? EmbeddingError, case .generatorUnavailable = embeddingError {
                        setLastImportHadDeferredEmbeddings(true)
                        // Save MicroMoments without ingest records so they're re-indexed on next launch
                        if context.hasChanges { try context.save() }
                        Diagnostics.log(level: .warn,
                                        category: .library,
                                        name: "library.import.deferred",
                                        fields: [
                                            "reason": .safeString(.stage("embeddings_unavailable", allowed: ["embeddings_unavailable"])),
                                            "decoded_count": .int(decodedCount),
                                            "payload_count": .int(payloadCount)
                                        ])
                        await monitor.stop(finalFields: [
                            "payload_count": .int(payloadCount),
                            "indexed_count": .int(0)
                        ])
                        span.end(additionalFields: [
                            "decoded_count": .int(decodedCount),
                            "inserted_count": .int(payloadCount),
                            "indexed_count": .int(0),
                            "deferred": .bool(true)
                        ], error: nil)
                        return
                    }
                    await monitor.stop(finalFields: ["payload_count": .int(payloadCount)])
                    span.end(additionalFields: [
                        "decoded_count": .int(decodedCount),
                        "inserted_count": .int(payloadCount),
                        "indexed_count": .int(indexedCount)
                    ], error: error)
                    throw LibraryImporterError.indexingFailed(underlying: error)
                }
            }

            // Atomic save: MicroMoments + LibraryIngest records in a single transaction
            if !updates.isEmpty {
                for update in updates {
                    let targetSource = update.source
                    var descriptor = FetchDescriptor<LibraryIngest>(predicate: #Predicate { $0.source == targetSource })
                    descriptor.fetchLimit = 1
                    let ingest: LibraryIngest
                    if let existing = try context.fetch(descriptor).first {
                        ingest = existing
                    } else {
                        ingest = LibraryIngest(source: update.source)
                        context.insert(ingest)
                    }
                    ingest.checksum = update.checksum
                    ingest.version = "1"
                    ingest.ingestedAt = Date()
                }
            }
            if context.hasChanges {
                try context.save()
            }

            let stats = await vectorIndex.stats()
            Diagnostics.log(level: .info,
                            category: .vectorIndex,
                            name: "vectorIndex.stats",
                            fields: [
                                "shards": .int(stats.shards),
                                "items": .int(stats.items)
                            ])
            await monitor.stop(finalFields: [
                "decoded_count": .int(decodedCount),
                "indexed_count": .int(indexedCount)
            ])
            span.end(additionalFields: [
                "decoded_count": .int(decodedCount),
                "inserted_count": .int(payloadCount),
                "indexed_count": .int(indexedCount)
            ], error: nil)
        } catch {
            await monitor.stop(finalFields: [
                "decoded_count": .int(decodedCount),
                "indexed_count": .int(indexedCount)
            ])
            span.end(additionalFields: [
                "decoded_count": .int(decodedCount),
                "inserted_count": .int(payloadCount),
                "indexed_count": .int(indexedCount)
            ], error: error)
            throw error
        }
    }

    private func process(resource: LibraryResourcePayload, context: ModelContext) throws -> LibraryProcessOutcome {
        let targetSource = resource.filename
        var descriptor = FetchDescriptor<LibraryIngest>(predicate: #Predicate { $0.source == targetSource })
        descriptor.fetchLimit = 1

        let existing = try context.fetch(descriptor).first
        if let existing, existing.checksum == resource.checksum {
            return LibraryProcessOutcome(payloads: [], ingestUpdate: nil)
        }

        var payloads: [MicroMomentIndexPayload] = []
        for episode in resource.episodes {
            for recommendation in episode.recommendations {
                let payload = try upsertMicroMoment(episode: episode,
                                                    recommendation: recommendation,
                                                    context: context)
                payloads.append(payload)
            }
        }

        return LibraryProcessOutcome(payloads: payloads,
                                     ingestUpdate: LibraryIngestUpdate(source: resource.filename,
                                                                       checksum: resource.checksum))
    }

    private func upsertMicroMoment(episode: PodcastEpisode,
                                   recommendation: PodcastRecommendation,
                                   context: ModelContext) throws -> MicroMomentIndexPayload {
        let identifier = recommendationIdentifier(episode: episode, recommendation: recommendation)
        var descriptor = FetchDescriptor<MicroMoment>(predicate: #Predicate { $0.id == identifier })
        descriptor.fetchLimit = 1

        let microMoment: MicroMoment
        if let existing = try context.fetch(descriptor).first {
            microMoment = existing
        } else {
            microMoment = MicroMoment(id: identifier,
                                      title: recommendation.recommendation,
                                      shortDescription: recommendation.shortDescription)
            context.insert(microMoment)
        }
        microMoment.title = recommendation.recommendation
        microMoment.shortDescription = recommendation.shortDescription
        microMoment.detail = buildDetail(episode: episode, recommendation: recommendation)
        // tags stored as JSON string in SwiftData
        if let tags = recommendation.tags {
            microMoment.tags = (try? JSONEncoder().encode(tags)).flatMap { String(data: $0, encoding: .utf8) }
        } else {
            microMoment.tags = nil
        }
        microMoment.difficulty = recommendation.difficultyLevel
        microMoment.category = recommendation.category
        microMoment.sourceURL = recommendation.researchLink
        microMoment.evidenceBadge = EvidenceScorer.badge(for: recommendation.researchLink).rawValue
        microMoment.estimatedTimeSec = Int32(parseTimeInterval(from: recommendation.timeToComplete))
        microMoment.cooldownSec = recommendation.cooldownSec.map(Int32.init)
        return MicroMomentIndexPayload(id: identifier,
                                       title: microMoment.title,
                                       detail: microMoment.detail,
                                       tags: recommendation.tags)
    }

    private func recommendationIdentifier(episode: PodcastEpisode, recommendation: PodcastRecommendation) -> String {
        let base = "episode-\(episode.episodeNumber)-\(recommendation.recommendation)"
        return base.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "-", options: .regularExpression)
    }

    private func parseTimeInterval(from string: String?) -> Int {
        guard let string else { return 300 }
        let lower = string.lowercased()
        if lower.contains("day") {
            let value = extractLeadingNumber(from: lower)
            return value * 24 * 60 * 60
        }
        if lower.contains("hour") {
            return extractLeadingNumber(from: lower) * 60 * 60
        }
        if lower.contains("min") {
            return max(extractLeadingNumber(from: lower) * 60, 60)
        }
        if lower.contains("sec") {
            return max(extractLeadingNumber(from: lower), 10)
        }
        return 300
    }

    private func extractLeadingNumber(from string: String) -> Int {
        if let match = string.range(of: "\\d+", options: .regularExpression) {
            return Int(string[match]) ?? 1
        }
        return 1
    }

    private func buildDetail(episode _: PodcastEpisode, recommendation: PodcastRecommendation) -> String {
        var detailComponents: [String] = []
        detailComponents.append(recommendation.detailedDescription)
        if let microActivity = recommendation.microActivity {
            detailComponents.append("Try this: \(microActivity)")
        }
        return detailComponents.joined(separator: "\n\n")
    }

    private func discoverLibraryURLs() -> [URL] {
        var urls = configuration.bundle.urls(forResourcesWithExtension: configuration.fileExtension,
                                             subdirectory: configuration.subdirectory) ?? []
        if urls.isEmpty, configuration.subdirectory != nil {
            urls = configuration.bundle.urls(forResourcesWithExtension: configuration.fileExtension,
                                             subdirectory: nil) ?? []
        }
        return urls
    }

    private static func loadResourcesAsync(from urls: [URL]) async throws -> [LibraryResourcePayload] {
        try await Task.detached(priority: .userInitiated) {
            try loadResources(from: urls)
        }.value
    }

    private static func loadResources(from urls: [URL]) throws -> [LibraryResourcePayload] {
        guard !urls.isEmpty else { return [] }
        let decoder = JSONDecoder()
        return try urls.map { url in
            let data = try Data(contentsOf: url)
            let checksum = sha256Hex(for: data)
            let episodes: [PodcastEpisode]
            do {
                episodes = try decoder.decode([PodcastEpisode].self, from: data)
            } catch {
                throw LibraryImporterError.decodingFailed(underlying: error)
            }
            return LibraryResourcePayload(filename: url.lastPathComponent,
                                          checksum: checksum,
                                          episodes: episodes)
        }
    }

    private func upsertIndexEntries(_ payloads: [MicroMomentIndexPayload]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for payload in payloads {
                group.addTask { [vectorIndex] in
                    _ = try await vectorIndex.upsertMicroMoment(id: payload.id,
                                                                title: payload.title,
                                                                detail: payload.detail,
                                                                tags: payload.tags)
                }
            }
            try await group.waitForAll()
        }
    }

    private static func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Codable structures

private struct LibraryResourcePayload: Sendable {
    let filename: String
    let checksum: String
    let episodes: [PodcastEpisode]
}

private struct MicroMomentIndexPayload: Sendable {
    let id: String
    let title: String
    let detail: String?
    let tags: [String]?
}

private struct LibraryIngestUpdate: Sendable {
    let source: String
    let checksum: String
}

private struct LibraryProcessOutcome: Sendable {
    let payloads: [MicroMomentIndexPayload]
    let ingestUpdate: LibraryIngestUpdate?
}

private struct PodcastEpisode: Decodable {
    let episodeNumber: String
    let episodeTitle: String
    let recommendations: [PodcastRecommendation]
}

private struct PodcastRecommendation: Decodable {
    let recommendation: String
    let shortDescription: String
    let detailedDescription: String
    let microActivity: String?
    let researchLink: String?
    let difficultyLevel: String?
    let timeToComplete: String?
    let tags: [String]?
    let category: String?
    let cooldownSec: Int?
}

// SAFETY: Mutable state (`_lastImportHadDeferredEmbeddings`) is protected by `stateLock`.
// Immutable properties (`configuration`, `vectorIndex`, `modelContainer`) are set once in init.
extension LibraryImporter: @unchecked Sendable {}
