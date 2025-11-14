import Foundation

public struct SpeechSegment: Sendable, Equatable {
    public let transcript: String
    public let isFinal: Bool
    public let confidence: Float?

    public init(transcript: String, isFinal: Bool, confidence: Float? = nil) {
        self.transcript = transcript
        self.isFinal = isFinal
        self.confidence = confidence
    }
}
