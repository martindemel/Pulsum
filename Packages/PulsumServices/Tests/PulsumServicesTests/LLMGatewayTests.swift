import XCTest
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
@testable import PulsumServices

final class MockCloudClient: CloudLLMClient {
    var shouldFail = false
    var groundingScore: Double = 0.65
    var isOnTopic = true
    var callCount = 0

    func generateResponse(context: CoachLLMContext,
                          intentTopic: String?,
                          candidateMoments: [CandidateMoment],
                          apiKey: String,
                          keySource: String) async throws -> CoachPhrasing {
        callCount += 1
        if shouldFail { throw LLMGatewayError.cloudGenerationFailed("forced failure") }
        return CoachPhrasing(
            coachReply: "Cloud response referencing \(context.topSignal).",
            isOnTopic: isOnTopic,
            groundingScore: groundingScore,
            intentTopic: intentTopic ?? "none"
        )
    }
}

final class MockLocalGenerator: OnDeviceCoachGenerator {
    var callCount = 0

    func generate(context: CoachLLMContext) async -> CoachReplyPayload {
        callCount += 1
        return CoachReplyPayload(
            coachReply: "Local fallback for \(context.topSignal)",
            nextAction: nil
        )
    }
}

final class LLMGatewayTests: XCTestCase {
    func testFallbackWhenConsentDisabled() async {
        let keychain = KeychainService()
        let gateway = LLMGateway(keychain: keychain,
                                 cloudClient: MockCloudClient(),
                                 localGenerator: MockLocalGenerator())
        try? gateway.setAPIKey("stub-key")
        let context = CoachLLMContext(userToneHints: "calm",
                                      topSignal: "topic=sleep",
                                      topMomentId: nil,
                                      rationale: "HRV suppressed",
                                      zScoreSummary: "z_hrv:-2")
        let payload = await gateway.generateCoachResponse(context: context,
                                                          intentTopic: "sleep",
                                                          candidateMoments: [],
                                                          consentGranted: false)
        XCTAssertTrue(payload.coachReply.lowercased().contains("local"))
    }

    func testGroundingFloorRespected() async {
        let cloudClient = MockCloudClient()
        let gateway = LLMGateway(keychain: KeychainService(),
                                 cloudClient: cloudClient,
                                 localGenerator: MockLocalGenerator())
        try? gateway.setAPIKey("stub-key")
        let context = CoachLLMContext(userToneHints: "calm",
                                      topSignal: "topic=sleep",
                                      topMomentId: nil,
                                      rationale: "HRV suppressed",
                                      zScoreSummary: "z_hrv:-2")

        cloudClient.groundingScore = 0.41
        let softPayload = await gateway.generateCoachResponse(context: context,
                                                              intentTopic: "sleep",
                                                              candidateMoments: [],
                                                              consentGranted: true,
                                                              groundingFloor: 0.40)
        XCTAssertTrue(softPayload.coachReply.contains("Cloud response"))

        cloudClient.groundingScore = 0.39
        let fallbackPayload = await gateway.generateCoachResponse(context: context,
                                                                  intentTopic: "sleep",
                                                                  candidateMoments: [],
                                                                  consentGranted: true,
                                                                  groundingFloor: 0.40)
        XCTAssertTrue(fallbackPayload.coachReply.lowercased().contains("local"))
    }

    func testCloudRequestBodyFormatUsesUnifiedSchema() throws {
        let candidates = [
            CandidateMoment(id: "a",
                            title: "Quick reset",
                            shortDescription: "Deep breathing reset.",
                            detail: "A concise prompt to slow breathing.",
                            evidenceBadge: "Strong")
        ]
        let context = CoachLLMContext(userToneHints: String(repeating: "a", count: 400),
                                      topSignal: "topic=sleep",
                                      topMomentId: candidates.first?.id,
                                      rationale: String(repeating: "b", count: 250),
                                      zScoreSummary: String(repeating: "c", count: 210),
                                      candidateMoments: candidates)
        let body = try LLMGateway.makeChatRequestBody(context: context,
                                                      candidateMoments: candidates,
                                                      maxOutputTokens: 512)

        XCTAssertEqual(body["model"] as? String, "gpt-5")
        let tokens = body["max_output_tokens"] as? Int
        XCTAssertEqual(tokens, 512)
        XCTAssertTrue((tokens ?? 0) >= 128 && (tokens ?? 0) <= 1024)

        guard let text = body["text"] as? [String: Any],
              text["verbosity"] as? String == "low",
              let format = text["format"] as? [String: Any],
              format["type"] as? String == "json_schema",
              format["name"] as? String == "CoachPhrasing",
              let schema = format["schema"] as? [String: Any],
              let properties = schema["properties"] as? [String: Any],
              let required = schema["required"] as? [String] else {
            XCTFail("Missing or invalid text.format schema data")
            return
        }

        XCTAssertEqual(schema["additionalProperties"] as? Bool, false)
        XCTAssertEqual(Set(required), Set(properties.keys))

        guard let inputMessages = body["input"] as? [[String: Any]],
              inputMessages.count == 2,
              let systemRole = inputMessages.first? ["role"] as? String,
              let userRole = inputMessages.last? ["role"] as? String,
              let userContent = inputMessages.last? ["content"] as? String else {
            XCTFail("Invalid input message structure")
            return
        }

        XCTAssertEqual(systemRole, "system")
       XCTAssertEqual(userRole, "user")
        XCTAssertTrue(userContent.contains("\"userToneHints\""))
        XCTAssertTrue(userContent.contains("\"candidateMoments\""))
    }

    func testSchemaErrorFallsBackToLocalGenerator() async {
        let local = MockLocalGenerator()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LLMURLProtocolStub.self]
        LLMURLProtocolStub.invocationCount = 0
        LLMURLProtocolStub.handler = nil
        LLMURLProtocolStub.respondWithSchemaError = true

        let gateway = LLMGateway(cloudClient: nil,
                                 localGenerator: local,
                                 session: URLSession(configuration: configuration))
        try? gateway.setAPIKey("stub-key")
        let context = CoachLLMContext(userToneHints: "calm",
                                      topSignal: "topic=sleep",
                                      topMomentId: nil,
                                      rationale: "HRV suppressed",
                                      zScoreSummary: "z_hrv:-2")

        let payload = await gateway.generateCoachResponse(context: context,
                                                          intentTopic: "sleep",
                                                          candidateMoments: [],
                                                          consentGranted: true,
                                                          groundingFloor: 0.5)

        XCTAssertTrue(payload.coachReply.lowercased().contains("local"))
        XCTAssertEqual(local.callCount, 1)
        XCTAssertEqual(LLMURLProtocolStub.invocationCount, 1)

        LLMURLProtocolStub.respondWithSchemaError = false
    }

    func testAPIConnectionReturnsTrueOn200() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LLMURLProtocolStub.self]
        LLMURLProtocolStub.handler = nil
        LLMURLProtocolStub.invocationCount = 0

        let gateway = LLMGateway(session: URLSession(configuration: configuration))
        try? gateway.setAPIKey("stub-key")
        let success = try await gateway.testAPIConnection()

        XCTAssertTrue(success)
        XCTAssertEqual(LLMURLProtocolStub.invocationCount, 1)
    }

    func testAPIConnectionReturnsFalseOn400() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LLMURLProtocolStub.self]
        LLMURLProtocolStub.invocationCount = 0
        LLMURLProtocolStub.handler = { _ in
            (400, Data("{\"error\":{\"message\":\"Missing text.format.name\"}}".utf8))
        }

        let gateway = LLMGateway(session: URLSession(configuration: configuration))
        try? gateway.setAPIKey("stub-key")
        let success = try await gateway.testAPIConnection()

        XCTAssertFalse(success)
        XCTAssertEqual(LLMURLProtocolStub.invocationCount, 1)

        LLMURLProtocolStub.handler = nil
    }

    func testKeyResolutionFailsWhenSourcesMissing() throws {
        unsetenv("PULSUM_COACH_API_KEY")
        let gateway = LLMGateway(keychain: InMemoryKeychain(),
                                 cloudClient: MockCloudClient(),
                                 localGenerator: MockLocalGenerator())
        XCTAssertNil(gateway.currentAPIKey())
        XCTAssertThrowsError(try gateway.debugResolveAPIKey()) { error in
            guard case LLMGatewayError.apiKeyMissing = error else {
                return XCTFail("Expected apiKeyMissing, got \(error)")
            }
        }
    }

    func testKeyResolutionPrefersInMemoryThenKeychainThenEnv() throws {
        let keychain = InMemoryKeychain()
        let gateway = LLMGateway(keychain: keychain,
                                 cloudClient: MockCloudClient(),
                                 localGenerator: MockLocalGenerator())

        let previousEnv = getenv("PULSUM_COACH_API_KEY").flatMap { String(cString: $0) }
        setenv("PULSUM_COACH_API_KEY", "env-key", 1)
        defer {
            if let previousEnv {
                setenv("PULSUM_COACH_API_KEY", previousEnv, 1)
            } else {
                unsetenv("PULSUM_COACH_API_KEY")
            }
        }

        XCTAssertEqual(try gateway.debugResolveAPIKey(), "env-key")

        try keychain.setSecret(Data("kc-key".utf8), for: "openai.api.key")
        gateway.debugOverrideInMemoryKey(nil)
        XCTAssertEqual(try gateway.debugResolveAPIKey(), "kc-key")

        gateway.debugOverrideInMemoryKey("memory-key")
        XCTAssertEqual(try gateway.debugResolveAPIKey(), "memory-key")
    }
}

private final class InMemoryKeychain: KeychainStoring {
    private var values: [String: Data] = [:]

    func setSecret(_ value: Data, for key: String) throws {
        values[key] = value
    }

    func secret(for key: String) throws -> Data? {
        values[key]
    }

    func removeSecret(for key: String) throws {
        values.removeValue(forKey: key)
    }
}

extension InMemoryKeychain: @unchecked Sendable {}
