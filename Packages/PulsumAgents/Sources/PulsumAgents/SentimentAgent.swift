import Foundation
import CoreData
#if canImport(FoundationModels)
import FoundationModels
#endif
import PulsumData
import PulsumML
import PulsumServices

@MainActor
public final class SentimentAgent {
    private let speechService: SpeechService
    private let embeddingService = EmbeddingService.shared
    private let context: NSManagedObjectContext
    private let calendar = Calendar(identifier: .gregorian)
    private let sentimentService: SentimentService
    private var activeStopHandler: (() -> Void)?

    public init(speechService: SpeechService = SpeechService(),
                container: NSPersistentContainer = PulsumData.container,
                sentimentService: SentimentService = SentimentService()) {
        self.speechService = speechService
        self.sentimentService = sentimentService
        self.context = container.newBackgroundContext()
        self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.context.name = "Pulsum.SentimentAgent.FoundationModels"
    }

    public func requestAuthorization() async throws {
        try await speechService.requestAuthorization()
    }

    public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws -> JournalResult {
        try await speechService.requestAuthorization()
        let session = try await speechService.startRecording(maxDuration: min(maxDuration, 30))
        activeStopHandler = session.stop
        defer { activeStopHandler = nil }
        var transcript = ""
        do {
            for try await segment in session.stream {
                transcript = segment.transcript
            }
        } catch {
            session.stop()
            throw error
        }
        session.stop()
        return try await persistJournal(transcript: transcript)
    }

    public func stopRecording() {
        activeStopHandler?()
        activeStopHandler = nil
    }

    public func importTranscript(_ transcript: String) async throws -> JournalResult {
        try await persistJournal(transcript: transcript)
    }

    private func persistJournal(transcript: String) async throws -> JournalResult {
        let sanitized = PIIRedactor.redact(transcript)
        
        // Use async Foundation Models sentiment analysis
        let sentiment = await sentimentService.sentiment(for: sanitized)
        let vector = embeddingService.embedding(for: sanitized)

        let entryID = UUID()
        let vectorURL = try persistVector(vector: vector, id: entryID)

        return try await context.perform { [context, calendar] () -> JournalResult in
            let entry = JournalEntry(context: context)
            entry.id = entryID
            entry.date = Date()
            entry.transcript = sanitized
            entry.sentiment = NSNumber(value: sentiment)
            entry.sensitiveFlags = "{}"
            entry.embeddedVectorURL = vectorURL.lastPathComponent

            let day = calendar.startOfDay(for: entry.date)
            let request = FeatureVector.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", day as NSDate)
            request.fetchLimit = 1
            let featureVector = try context.fetch(request).first ?? FeatureVector(context: context)
            featureVector.date = day
            featureVector.sentiment = NSNumber(value: sentiment)

            try context.save()

            return JournalResult(entryID: entry.objectID,
                                 transcript: sanitized,
                                 sentimentScore: sentiment,
                                 vectorURL: vectorURL)
        }
    }

    nonisolated private func persistVector(vector: [Float], id: UUID) throws -> URL {
        let directory = PulsumData.vectorIndexDirectory.appendingPathComponent("JournalEntries", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
        }
        let url = directory.appendingPathComponent("\(id.uuidString).vec")
        var data = Data(capacity: vector.count * MemoryLayout<Float>.size)
        for value in vector {
            var bits = value.bitPattern.littleEndian
            withUnsafeBytes(of: &bits) { buffer in
                data.append(buffer.bindMemory(to: UInt8.self))
            }
        }
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        return url
    }
}
