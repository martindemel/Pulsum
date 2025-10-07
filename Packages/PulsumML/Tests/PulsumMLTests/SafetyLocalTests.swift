import XCTest
@testable import PulsumML

final class SafetyLocalTests: XCTestCase {
    func testCrisisKeywordTriggersCrisisClassification() {
        let safety = SafetyLocal()
        let decision = safety.classify(text: "I am going to kill myself tonight")
        switch decision {
        case .crisis:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected crisis classification for explicit self-harm language")
        }
    }

    func testSimilarityThresholdIdentifiesCautionTone() {
        let safety = SafetyLocal()
        let decision = safety.classify(text: "I'm panicking right now and can't calm down")
        switch decision {
        case .caution:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected caution classification for overwhelming language")
        }
    }

    func testSafeTextRemainsUnaffected() {
        let safety = SafetyLocal()
        let result = safety.classify(text: "I finished a restorative stretch and feel balanced")
        XCTAssertEqual(result, .safe)
    }
}
