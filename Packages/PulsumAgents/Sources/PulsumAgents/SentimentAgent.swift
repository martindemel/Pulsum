import Foundation
import CoreData
#if canImport(FoundationModels)
import FoundationModels
#endif
import PulsumData
import PulsumML
import PulsumServices
import PulsumTypes

public enum SentimentAgentError: LocalizedError {
    case noActiveRecording
    case noSpeechDetected
    case sessionAlreadyActive
    
    public var errorDescription: String? {
        switch self {
        case .noActiveRecording:
            return "No active recording session found."
        case .noSpeechDetected:
            return "No speech detected. Please try again and speak clearly."
        case .sessionAlreadyActive:
            return "A recording is already in progress."
        }
    }
}

@MainActor
public final class SentimentAgent {
    private let speechService: SpeechService
    private let embeddingService = EmbeddingService.shared
    private let context: NSManagedObjectContext
    private let calendar = Calendar(identifier: .gregorian)
    private let sentimentService: SentimentService
    private let sessionState = JournalSessionState()
    
    public var audioLevels: AsyncStream<Float>? {
        sessionState.audioLevels
    }
    
    public var speechStream: AsyncThrowingStream<SpeechSegment, Error>? {
        sessionState.speechStream
    }

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

    /// Begins voice journal recording and returns immediately after starting audio capture.
    /// Audio levels and speech stream become available synchronously via properties.
    /// The caller should consume the speech stream to get real-time transcription.
    /// Call `finishVoiceJournal(transcript:)` to complete recording and persist the result.
    public func beginVoiceJournal(maxDuration: TimeInterval = 30) async throws {
        try await speechService.requestAuthorization()
        let session = try await speechService.startRecording(maxDuration: min(maxDuration, 30))
        do {
            try sessionState.begin(with: session)
        } catch {
            session.stop()
            throw error
        }
    }
    
    /// Updates the latest transcript. Called by the UI as it consumes the speech stream.
    public func updateTranscript(_ transcript: String) {
        sessionState.updateTranscript(transcript)
    }
    
    /// Completes the voice journal recording that was started with `beginVoiceJournal()`.
    /// Uses the provided transcript (from consuming the speech stream) to persist the journal.
    /// Returns the persisted journal result with transcript and sentiment.
    public func finishVoiceJournal(transcript: String? = nil) async throws -> JournalResult {
        guard let (session, cachedTranscript) = sessionState.takeSession() else {
            throw SentimentAgentError.noActiveRecording
        }
        
        defer { session.stop() }
        
        // Use provided transcript or fall back to stored transcript
        let finalTranscript = transcript ?? cachedTranscript
        
        // Check for empty transcript
        let trimmed = finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SentimentAgentError.noSpeechDetected
        }
        
        return try await persistJournal(transcript: trimmed)
    }

    /// Legacy method that combines begin + finish for backward compatibility
    public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws -> JournalResult {
        try await beginVoiceJournal(maxDuration: maxDuration)
        
        // Consume the speech stream to get the transcript
        var transcript = ""
        if let stream = speechStream {
            do {
                for try await segment in stream {
                    transcript = segment.transcript
                    sessionState.updateTranscript(transcript)
                }
            } catch {
                sessionState.stopActiveSession()
                throw error
            }
        }
        
        return try await finishVoiceJournal(transcript: transcript)
    }

    public func stopRecording() {
        sessionState.stopActiveSession()
    }

    func latestTranscriptSnapshot() -> String {
        sessionState.latestTranscriptSnapshot()
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
                                 date: entry.date,
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

final class JournalSessionState: @unchecked Sendable {
    private var activeSession: SpeechService.Session?
    private var latestTranscript: String = ""
    private let queue = DispatchQueue(label: "ai.pulsum.sentimentAgent.session", qos: .userInitiated)

    var audioLevels: AsyncStream<Float>? {
        queue.sync { activeSession?.audioLevels }
    }

    var speechStream: AsyncThrowingStream<SpeechSegment, Error>? {
        queue.sync { activeSession?.stream }
    }

    func begin(with session: SpeechService.Session) throws {
        try queue.sync {
            guard activeSession == nil else { throw SentimentAgentError.sessionAlreadyActive }
            activeSession = session
            latestTranscript = ""
        }
    }

    func updateTranscript(_ transcript: String) {
        queue.async { self.latestTranscript = transcript }
    }

    func takeSession() -> (SpeechService.Session, String)? {
        queue.sync {
            guard let session = activeSession else { return nil }
            let transcript = latestTranscript
            activeSession = nil
            latestTranscript = ""
            return (session, transcript)
        }
    }

    func stopActiveSession() {
        queue.sync {
            activeSession?.stop()
            activeSession = nil
            latestTranscript = ""
        }
    }

    func latestTranscriptSnapshot() -> String {
        queue.sync { latestTranscript }
    }
}
