import XCTest
import PulsumTypes

final class Gate2_TypesWiringTests: XCTestCase {
    func testSpeechSegmentInit() {
        let segment = SpeechSegment(transcript: "hello", isFinal: true, confidence: 0.9)
        XCTAssertEqual(segment.transcript, "hello")
        XCTAssertTrue(segment.isFinal)
        XCTAssertEqual(segment.confidence, 0.9)
    }
}
