import Foundation
import CoreData
import CryptoKit

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

    public init(configuration: LibraryImporterConfiguration = LibraryImporterConfiguration(),
                vectorIndex: VectorIndexProviding = VectorIndexManager.shared) {
        self.configuration = configuration
        self.vectorIndex = vectorIndex
    }

    public func ingestIfNeeded() async throws {
        var urls = configuration.bundle.urls(forResourcesWithExtension: configuration.fileExtension,
                                             subdirectory: configuration.subdirectory) ?? []
        if urls.isEmpty, configuration.subdirectory != nil {
            urls = configuration.bundle.urls(forResourcesWithExtension: configuration.fileExtension,
                                             subdirectory: nil) ?? []
        }
        guard !urls.isEmpty else {
            #if DEBUG
            print("[PulsumData] Recommendation library resources not found. Skipping ingestion.")
            #endif
            return
        }

        let resources = try loadResources(from: urls)
        guard !resources.isEmpty else { return }

        let context = PulsumData.newBackgroundContext(name: "Pulsum.LibraryImporter")
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        let result = try await context.perform {
            var payloads: [MicroMomentIndexPayload] = []
            var updates: [LibraryIngestUpdate] = []
            for resource in resources {
                let outcome = try self.process(resource: resource, context: context)
                payloads.append(contentsOf: outcome.payloads)
                if let update = outcome.ingestUpdate {
                    updates.append(update)
                }
            }

            if context.hasChanges {
                try context.save()
            }
            return (payloads, updates)
        }

        if !result.0.isEmpty {
            do {
                try await upsertIndexEntries(result.0)
            } catch {
                throw LibraryImporterError.indexingFailed(underlying: error)
            }
        }

        if !result.1.isEmpty {
            try await context.perform {
                for update in result.1 {
                    let fetchRequest: NSFetchRequest<LibraryIngest> = LibraryIngest.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "source == %@", update.source)
                    fetchRequest.fetchLimit = 1
                    let ingest: LibraryIngest
                    if let existing = try context.fetch(fetchRequest).first {
                        ingest = existing
                    } else {
                        let newIngest = LibraryIngest(context: context)
                        newIngest.id = UUID()
                        ingest = newIngest
                    }
                    ingest.source = update.source
                    ingest.checksum = update.checksum
                    ingest.version = "1"
                    ingest.ingestedAt = Date()
                }
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }

    private func process(resource: LibraryResourcePayload, context: NSManagedObjectContext) throws -> LibraryProcessOutcome {
        let fetchRequest: NSFetchRequest<LibraryIngest> = LibraryIngest.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "source == %@", resource.filename)
        fetchRequest.fetchLimit = 1

        let existing = try context.fetch(fetchRequest).first
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
                                   context: NSManagedObjectContext) throws -> MicroMomentIndexPayload {
        let identifier = recommendationIdentifier(episode: episode, recommendation: recommendation)
        let fetch: NSFetchRequest<MicroMoment> = MicroMoment.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", identifier)
        fetch.fetchLimit = 1

        let microMoment = try context.fetch(fetch).first ?? MicroMoment(context: context)
        microMoment.id = identifier
        microMoment.title = recommendation.recommendation
        microMoment.shortDescription = recommendation.shortDescription
        microMoment.detail = buildDetail(episode: episode, recommendation: recommendation)
        microMoment.tags = recommendation.tags
        microMoment.difficulty = recommendation.difficultyLevel
        microMoment.category = recommendation.category
        microMoment.sourceURL = recommendation.researchLink
        microMoment.evidenceBadge = EvidenceScorer.badge(for: recommendation.researchLink).rawValue
        microMoment.estimatedTimeSec = NSNumber(value: parseTimeInterval(from: recommendation.timeToComplete))
        microMoment.cooldownSec = recommendation.cooldownSec.map { NSNumber(value: $0) }
        let title = microMoment.title
        return MicroMomentIndexPayload(id: identifier,
                                       title: title,
                                       detail: microMoment.detail,
                                       tags: microMoment.tags)
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

    private func buildDetail(episode: PodcastEpisode, recommendation: PodcastRecommendation) -> String {
        var detailComponents: [String] = []
        detailComponents.append("Episode #\(episode.episodeNumber): \(episode.episodeTitle)")
        detailComponents.append(recommendation.detailedDescription)
        if let microActivity = recommendation.microActivity {
            detailComponents.append("Try this: \(microActivity)")
        }
        return detailComponents.joined(separator: "\n\n")
    }

    private func loadResources(from urls: [URL]) throws -> [LibraryResourcePayload] {
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

    private func sha256Hex(for data: Data) -> String {
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

extension LibraryImporter: @unchecked Sendable {}
