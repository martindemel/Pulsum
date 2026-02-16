import XCTest
@testable import PulsumML

final class SafetyLocalTests: XCTestCase {
    func testCrisisKeywordTriggersCrisisClassification() async {
        let safety = SafetyLocal()
        let decision = await safety.classify(text: "I am going to kill myself tonight")
        switch decision {
        case .crisis:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected crisis classification for explicit self-harm language")
        }
    }

    func testSimilarityThresholdIdentifiesCautionTone() async {
        let safety = SafetyLocal()
        let decision = await safety.classify(text: "I'm panicking right now and can't calm down")
        switch decision {
        case .caution:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected caution classification for overwhelming language")
        }
    }

    func testSafeTextRemainsUnaffected() async {
        let safety = SafetyLocal()
        let result = await safety.classify(text: "I finished a restorative stretch and feel balanced")
        XCTAssertEqual(result, .safe)
    }
}
