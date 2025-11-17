import Testing
@testable import PulsumServices

struct Gate4_ConsentRoutingTests {

    @Test("Consent OFF forces on-device generator")
    func consentOffFallsBackLocal() async {
        let cloud = ConsentCloudClientStub()
        let local = ConsentLocalGeneratorStub()
        let gateway = LLMGateway(keychain: KeychainService(),
                                 cloudClient: cloud,
                                 localGenerator: local)
        let context = CoachLLMContext(userToneHints: "How can I improve my sleep?",
                                      topSignal: "topic=sleep",
                                      topMomentId: nil,
                                      rationale: "soft-pass",
                                      zScoreSummary: "z_sleepDebt:+0.8")
        _ = await gateway.generateCoachResponse(context: context,
                                                intentTopic: "sleep",
                                                candidateMoments: [],
                                                consentGranted: false,
                                                groundingFloor: 0.40)
        #expect(cloud.callCount == 0)
        #expect(local.callCount == 1)
    }

    @Test("Consent ON routes to cloud when coverage strong")
    func consentOnUsesCloud() async {
        let cloud = ConsentCloudClientStub()
        let local = ConsentLocalGeneratorStub()
        let gateway = LLMGateway(keychain: KeychainService(),
                                 cloudClient: cloud,
                                 localGenerator: local)
        let context = CoachLLMContext(userToneHints: "Give me a stress reset.",
                                      topSignal: "topic=stress",
                                      topMomentId: nil,
                                      rationale: "strong-pass",
                                      zScoreSummary: "z_hrv:-0.9")
        _ = await gateway.generateCoachResponse(context: context,
                                                intentTopic: "stress",
                                                candidateMoments: [],
                                                consentGranted: true,
                                                groundingFloor: 0.40)
        #expect(cloud.callCount == 1)
        #expect(local.callCount == 0)
    }
}

private final class ConsentCloudClientStub: CloudLLMClient {
    var callCount = 0

    func generateResponse(context: CoachLLMContext,
                          intentTopic: String?,
                          candidateMoments: [CandidateMoment],
                          apiKey: String,
                          keySource: String) async throws -> CoachPhrasing {
        callCount += 1
        return CoachPhrasing(coachReply: "Cloud response",
                             isOnTopic: true,
                             groundingScore: 0.9,
                             intentTopic: intentTopic ?? "none")
    }
}

private final class ConsentLocalGeneratorStub: OnDeviceCoachGenerator {
    var callCount = 0

    func generate(context: CoachLLMContext) async -> CoachReplyPayload {
        callCount += 1
        return CoachReplyPayload(coachReply: "Local response for \(context.topSignal).")
    }
}
