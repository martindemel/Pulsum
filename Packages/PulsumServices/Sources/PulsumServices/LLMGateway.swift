import Foundation
import os.log
import PulsumData
import PulsumML
import PulsumTypes

/// Candidate micro-moment snippet for context (privacy-safe; no PHI)
public struct CandidateMoment: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let shortDescription: String
    public let detail: String?
    public let evidenceBadge: String?

    public init(id: String,
                title: String,
                shortDescription: String,
                detail: String?,
                evidenceBadge: String?) {
        self.id = id
        self.title = title
        self.shortDescription = shortDescription
        self.detail = detail
        self.evidenceBadge = evidenceBadge
    }
}

/// Convenience wrapper for app-internal payload handled downstream by UI & agents
public struct CoachReplyPayload: Sendable {
    public let coachReply: String
    public let nextAction: String?

    public init(coachReply: String, nextAction: String? = nil) {
        self.coachReply = coachReply
        self.nextAction = nextAction
    }
}

public struct CoachPhrasing: Codable, Sendable {
    public let coachReply: String
    public let isOnTopic: Bool
    public let groundingScore: Double
    public let intentTopic: String
    public let refusalReason: String?
    public let nextAction: String?

    enum CodingKeys: String, CodingKey {
        case coachReply
        case isOnTopic
        case groundingScore
        case intentTopic
        case refusalReason
        case nextAction
    }

    public init(coachReply: String,
                isOnTopic: Bool,
                groundingScore: Double,
                intentTopic: String,
                refusalReason: String? = nil,
                nextAction: String? = nil) {
        self.coachReply = coachReply
        self.isOnTopic = isOnTopic
        self.groundingScore = groundingScore
        self.intentTopic = intentTopic
        self.refusalReason = refusalReason
        self.nextAction = nextAction
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coachReply = try container.decode(String.self, forKey: .coachReply)
        isOnTopic = try container.decode(Bool.self, forKey: .isOnTopic)
        groundingScore = try container.decode(Double.self, forKey: .groundingScore)
        intentTopic = try container.decode(String.self, forKey: .intentTopic)

        let refusal = (try? container.decode(String.self, forKey: .refusalReason)) ?? ""
        let next = (try? container.decode(String.self, forKey: .nextAction)) ?? ""

        let trimmedRefusal = refusal.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNext = next.trimmingCharacters(in: .whitespacesAndNewlines)

        refusalReason = trimmedRefusal.isEmpty ? nil : trimmedRefusal
        nextAction = trimmedNext.isEmpty ? nil : trimmedNext
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coachReply, forKey: .coachReply)
        try container.encode(isOnTopic, forKey: .isOnTopic)
        try container.encode(groundingScore, forKey: .groundingScore)
        try container.encode(intentTopic, forKey: .intentTopic)
        try container.encode(refusalReason ?? "", forKey: .refusalReason)
        try container.encode(nextAction ?? "", forKey: .nextAction)
    }
}

public struct CoachLLMContext: Codable, Sendable {
    public let userToneHints: String
    public let topSignal: String
    public let topMomentId: String?
    public let rationale: String
    public let zScoreSummary: String
    public let candidateMoments: [CandidateMoment]

    public init(userToneHints: String,
                topSignal: String,
                topMomentId: String?,
                rationale: String,
                zScoreSummary: String,
                candidateMoments: [CandidateMoment] = []) {
        self.userToneHints = userToneHints
        self.topSignal = topSignal
        self.topMomentId = topMomentId
        self.rationale = rationale
        self.zScoreSummary = zScoreSummary
        self.candidateMoments = candidateMoments
    }
}

/// Encodes minimized cloud payloads and enforces schema guardrails.
struct MinimizedCloudRequest: Codable, Sendable, Equatable {
    struct MomentContext: Codable, Sendable, Equatable {
        let id: String
        let title: String
        let short: String
        let detail: String?
        let evidenceBadge: String?
    }

    enum GuardError: Error {
        case encodingFailed
        case unexpectedRootFields(Set<String>)
        case unexpectedMomentFields(Set<String>)
        case forbiddenField(String)
    }

    private static let allowedRootKeys: Set<String> = [
        "userToneHints",
        "topSignal",
        "topMomentId",
        "rationale",
        "zScoreSummary",
        "candidateMoments"
    ]
    private static let allowedMomentKeys: Set<String> = [
        "id",
        "title",
        "short",
        "detail",
        "evidenceBadge"
    ]

    let userToneHints: String
    let topSignal: String
    let topMomentId: String?
    let rationale: String
    let zScoreSummary: String
    let candidateMoments: [MomentContext]

    static func build(from context: CoachLLMContext,
                      candidateMoments: [CandidateMoment]) -> MinimizedCloudRequest {
        let limitedMoments = Array(candidateMoments.prefix(3))
        let sanitizedMoments = limitedMoments.map { moment -> MomentContext in
            let short = sanitize(moment.shortDescription, limit: 180)
            let detail = sanitize(moment.detail ?? "", limit: 200)
            let sanitizedDetail = detail.isEmpty ? nil : detail
            let badge = sanitize(moment.evidenceBadge ?? "", limit: 32)
            return MomentContext(id: sanitize(moment.id, limit: 80),
                                 title: sanitize(moment.title, limit: 120),
                                 short: short,
                                 detail: sanitizedDetail,
                                 evidenceBadge: badge.isEmpty ? nil : badge)
        }

        return MinimizedCloudRequest(
            userToneHints: sanitize(context.userToneHints, limit: 180),
            topSignal: sanitize(context.topSignal, limit: 120),
            topMomentId: context.topMomentId.map { sanitize($0, limit: 80) },
            rationale: sanitize(context.rationale, limit: 180),
            zScoreSummary: sanitize(context.zScoreSummary, limit: 220),
            candidateMoments: sanitizedMoments
        )
    }

    func encodedJSONString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(self)
        try Self.guardFields(in: data)
        guard let json = String(data: data, encoding: .utf8) else {
            throw GuardError.encodingFailed
        }
        return json
    }

    private static func guardFields(in data: Data) throws {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any] else {
            throw GuardError.encodingFailed
        }
        let rootKeys = Set(root.keys)
        if !rootKeys.isSubset(of: allowedRootKeys) {
            throw GuardError.unexpectedRootFields(rootKeys.subtracting(allowedRootKeys))
        }
        if let moments = root["candidateMoments"] as? [[String: Any]] {
            for moment in moments {
                let keys = Set(moment.keys)
                if !keys.isSubset(of: allowedMomentKeys) {
                    throw GuardError.unexpectedMomentFields(keys.subtracting(allowedMomentKeys))
                }
            }
        }
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw GuardError.encodingFailed
        }
        let lower = jsonString.lowercased()
        for forbidden in ["\"transcript\"", "\"heartrate\"", "\"samples\""] {
            if lower.contains(forbidden) {
                throw GuardError.forbiddenField(forbidden)
            }
        }
    }

    private static func sanitize(_ text: String, limit: Int) -> String {
        if text.isEmpty { return "" }
        let collapsed = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= limit { return trimmed }
        return String(trimmed.prefix(limit))
    }
}

public protocol CloudLLMClient {
    func generateResponse(context: CoachLLMContext,
                          intentTopic: String?,
                          candidateMoments: [CandidateMoment],
                          apiKey: String,
                          keySource: String) async throws -> CoachPhrasing
}

public protocol OnDeviceCoachGenerator {
    func generate(context: CoachLLMContext) async -> CoachReplyPayload
}

public enum LLMGatewayError: LocalizedError, Equatable {
    case apiKeyMissing
    case cloudGenerationFailed(String)

    public static func == (lhs: LLMGatewayError, rhs: LLMGatewayError) -> Bool {
        switch (lhs, rhs) {
        case (.apiKeyMissing, .apiKeyMissing):
            return true
        case let (.cloudGenerationFailed(l), .cloudGenerationFailed(r)):
            return l == r
        default:
            return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "LLM API key is missing."
        case .cloudGenerationFailed(let detail):
            return "Cloud phrasing failed: \(detail)"
        }
    }
}

/// Manages consent-aware phrasing requests.
private let validationLogger = Logger(subsystem: "ai.pulsum", category: "LLMGateway.Validation")

public final class LLMGateway {
    private static let apiKeyIdentifier = "openai.api.key"
    private static let environmentVariableName = "PULSUM_COACH_API_KEY"

    private static func environmentAPIKey() -> String? {
        guard let raw = ProcessInfo.processInfo.environment[environmentVariableName]?.trimmedNonEmpty else {
            return nil
        }
        return raw
    }

    private let keychain: KeychainStoring
    private let cloudClient: CloudLLMClient
    private let localGenerator: OnDeviceCoachGenerator
    private let session: URLSession
    private let usesUITestStub: Bool

    private var inMemoryAPIKey: String?

    private let logger = Logger(subsystem: "ai.pulsum", category: "LLMGateway")

    public init(keychain: KeychainStoring = KeychainService(),
                cloudClient: CloudLLMClient? = nil,
                localGenerator: OnDeviceCoachGenerator? = nil,
                session: URLSession = .shared) {
        self.keychain = keychain
        let stubEnabled = Self.isUITestStubEnabled()
        self.usesUITestStub = stubEnabled

        let resolvedCloudClient: CloudLLMClient
#if DEBUG
        if BuildFlags.uiTestSeamsCompiledIn && stubEnabled {
            resolvedCloudClient = UITestMockCloudClient()
        } else {
            resolvedCloudClient = cloudClient ?? GPT5Client(session: session)
        }
#else
        resolvedCloudClient = cloudClient ?? GPT5Client(session: session)
#endif
        self.cloudClient = resolvedCloudClient

        self.localGenerator = localGenerator ?? createDefaultLocalGenerator()
        self.session = session
    }

    public func setAPIKey(_ key: String) throws {
        guard let trimmed = key.trimmedNonEmpty,
              let data = trimmed.data(using: .utf8) else {
            throw LLMGatewayError.apiKeyMissing
        }
        try keychain.setSecret(data, for: Self.apiKeyIdentifier)
        inMemoryAPIKey = trimmed
        logger.debug("LLM API key saved to keychain (length=\(trimmed.count, privacy: .private)).")
    }

    public func testAPIConnection() async throws -> Bool {
        if usesUITestStub {
            logger.debug("UITest stub enabled: short-circuiting GPT ping.")
            return true
        }
        let body = Self.makePingRequestBody()
        if let text = body["text"] as? [String: Any],
           let format = text["format"] as? [String: Any] {
            let hasName = (format["name"] as? String) == "CoachPhrasing"
            let hasSchema = format["schema"] as? [String: Any] != nil
            let tokenLogValue = body["max_output_tokens"] as? Int ?? -1
            logger.debug("Responses API: max_output_tokens=\(tokenLogValue, privacy: .public) schemaNamePresent=\(hasName) schemaPresent=\(hasSchema)")
        }

        guard Self.validatePingPayload(body) else {
            logger.error("Ping payload failed validation guard.")
            return false
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let apiKey = try resolveAPIKey()
        let source = keySourceDescriptor()
        logger.debug("LLM using API key from \(source, privacy: .public).")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Ping failed: missing HTTP response")
            return false
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let code = httpResponse.statusCode
            let errorText = String(data: data, encoding: .utf8) ?? "HTTP \(code)"
            logger.error("Ping failed: status=\(code) body=\(errorText.prefix(200), privacy: .public)")
            return false
        }

        return true
    }

    public func generateCoachResponse(context: CoachLLMContext,
                                      intentTopic: String?,
                                      candidateMoments: [CandidateMoment],
                                      consentGranted: Bool,
                                      groundingFloor: Double = 0.50) async -> CoachReplyPayload {
        let sanitizedContext = CoachLLMContext(userToneHints: PIIRedactor.redact(context.userToneHints),
                                               topSignal: context.topSignal,
                                               topMomentId: context.topMomentId,
                                               rationale: PIIRedactor.redact(context.rationale),
                                               zScoreSummary: context.zScoreSummary,
                                               candidateMoments: context.candidateMoments)
        logger.debug("Generating coach response. Consent: \(consentGranted, privacy: .public), tone_chars: \(sanitizedContext.userToneHints.count, privacy: .public), rationale_chars: \(sanitizedContext.rationale.count, privacy: .public), score_chars: \(sanitizedContext.zScoreSummary.count, privacy: .public), topSignal: \(sanitizedContext.topSignal, privacy: .public), candidates: \(candidateMoments.count, privacy: .public)")
        if consentGranted {
            do {
                let apiKey = try resolveAPIKey()
                let keySource = keySourceDescriptor()
                logger.info("Attempting cloud phrasing via GPT client (key=\(keySource, privacy: .public)).")
                let phrasing = try await cloudClient.generateResponse(context: sanitizedContext,
                                                                      intentTopic: intentTopic,
                                                                      candidateMoments: candidateMoments,
                                                                      apiKey: apiKey,
                                                                      keySource: keySource)
                if phrasing.isOnTopic, phrasing.groundingScore >= groundingFloor {
                    let cleaned = CoachReplyPayload(
                        coachReply: sanitize(response: phrasing.coachReply),
                        nextAction: phrasing.nextAction
                    )
                    logger.debug("Cloud response received. Grounding: \(String(format: "%.2f", phrasing.groundingScore), privacy: .public), hasNextAction: \(cleaned.nextAction != nil, privacy: .public)")
                    return cleaned
                }
                logger.warning("Wall-2 grounding too low (score=\(String(format: "%.2f", phrasing.groundingScore)) floor=\(String(format: "%.2f", groundingFloor))). Falling back on-device.")
                notifyCloudError("Grounding score \(String(format: "%.2f", phrasing.groundingScore)) below floor \(String(format: "%.2f", groundingFloor))")
            } catch {
                // WALL 2 failure: schema validation failed or grounding too low
                // Fail-closed: fallback to on-device Foundation Models
                let nsError = error as NSError
                logger.error("Cloud phrasing failed (schema validation/grounding). domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public). Falling back to on-device generator.")
                notifyCloudError(error.localizedDescription)
            }
        }
        let fallback = await localGenerator.generate(context: sanitizedContext)
        let cleanedFallback = CoachReplyPayload(
            coachReply: sanitize(response: fallback.coachReply),
            nextAction: fallback.nextAction
        )
        logger.notice("Using on-device phrasing. Length: \(cleanedFallback.coachReply.count, privacy: .public)")
        return cleanedFallback
    }

    private func notifyCloudError(_ message: String) {
#if DEBUG
        NotificationCenter.default.post(name: .pulsumChatCloudError,
                                        object: nil,
                                        userInfo: ["message": message])
#endif
    }

    private func keySourceDescriptor() -> String {
        if usesUITestStub {
            return "uitest-stub"
        }
        if inMemoryAPIKey?.trimmedNonEmpty != nil {
            return "memory"
        }
        if ((try? keychain.secret(for: Self.apiKeyIdentifier)) ?? nil) != nil {
            return "keychain"
        }
        if Self.environmentAPIKey() != nil {
            return "env"
        }
        return "missing"
    }

    public func currentAPIKey() -> String? {
        if usesUITestStub {
            return "UITEST_STUB_KEY"
        }
        if let m = inMemoryAPIKey?.trimmedNonEmpty { return m }
        if let data = try? keychain.secret(for: Self.apiKeyIdentifier),
           let k = String(data: data, encoding: .utf8)?.trimmedNonEmpty {
            return k
        }
        if let env = Self.environmentAPIKey() {
            return env
        }
        return nil
    }

    private func resolveAPIKey() throws -> String {
        guard let key = currentAPIKey() else {
            throw LLMGatewayError.apiKeyMissing
        }
        return key
    }

    private func sanitize(response: String) -> String {
        // Ensure output is ≤2 sentences and neutral tone.
        let sentences = response.split(whereSeparator: { $0 == "." || $0 == "!" || $0 == "?" })
        let trimmed = sentences.prefix(2).map { sentence -> String in
            let cleaned = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.prefix(280).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed.joined(separator: ". ").appending(trimmed.isEmpty ? "" : ".")
    }

    func debugResolveAPIKey() throws -> String {
        try resolveAPIKey()
    }

    func debugOverrideInMemoryKey(_ key: String?) {
        inMemoryAPIKey = key?.trimmedNonEmpty
    }

    func debugClearPersistedAPIKey() throws {
        try keychain.removeSecret(for: Self.apiKeyIdentifier)
    }

    // Gate-1b: UITest seams are compiled out of Release builds.
    // In Release, env flags are ignored so remote stubs never activate.
    private static func isUITestStubEnabled() -> Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["UITEST_USE_STUB_LLM"] == "1"
#else
        return false
#endif
    }
}

fileprivate func validateChatPayload(body: [String: Any],
                                     context: CoachLLMContext,
                                     intentTopic: String?,
                                     candidateMoments: [CandidateMoment],
                                     maxTokens: Int) -> Bool {
    guard
        let text = body["text"] as? [String: Any],
        let format = text["format"] as? [String: Any],
        (format["type"] as? String) == "json_schema"
    else {
        return false
    }

    let schemaNamePresent = (format["name"] as? String) == "CoachPhrasing"
    guard schemaNamePresent,
          let schema = format["schema"] as? [String: Any] else {
        return false
    }

    validationLogger.debug("validateChatPayload schemaNamePresent=true schemaPresent=true")

    guard schema["type"] as? String == "object",
          (schema["additionalProperties"] as? Bool) == false,
          let properties = schema["properties"] as? [String: Any],
          let required = schema["required"] as? [String] else {
        return false
    }

    guard Set(required) == Set(properties.keys) else {
        return false
    }

    if !(128...1024).contains(maxTokens) { return false }

    guard let input = body["input"] as? [[String: Any]], input.count == 2,
          (input.first? ["role"] as? String) == "system",
          (input.last? ["role"] as? String) == "user"
    else { return false }

    guard let input = body["input"] as? [[String: Any]],
          input.count == 2,
          (input.first?["role"] as? String) == "system",
          (input.last?["role"] as? String) == "user",
          let userContent = input.last?["content"] as? String else {
        return false
    }

    do {
        let expected = MinimizedCloudRequest.build(from: context, candidateMoments: candidateMoments)
        let expectedJSON = try expected.encodedJSONString()
        if expectedJSON != userContent {
            return false
        }
    } catch {
        return false
    }

    return true
}

extension LLMGateway {
    static func validatePingPayload(_ body: [String: Any]) -> Bool {
    guard
        let text = body["text"] as? [String: Any],
        let format = text["format"] as? [String: Any],
        (format["type"] as? String) == "json_schema"
    else {
        return false
    }

    let schemaNamePresent = (format["name"] as? String) == "CoachPhrasing"
    guard schemaNamePresent,
          let schema = format["schema"] as? [String: Any] else {
        return false
    }

    validationLogger.debug("validatePingPayload schemaNamePresent=true schemaPresent=true")

    guard schema["type"] as? String == "object",
          (schema["additionalProperties"] as? Bool) == false,
          let properties = schema["properties"] as? [String: Any],
          let required = schema["required"] as? [String] else {
        return false
    }

    guard Set(required) == Set(properties.keys) else {
        return false
    }

    guard body["max_output_tokens"] as? Int == 32 else { return false }

    guard let input = body["input"] as? [[String: Any]],
          input.count == 1,
          (input.first? ["role"] as? String) == "user",
          let content = (input.first? ["content"] as? String)?.lowercased(),
          content == "ping" else {
        return false
    }

    return true
    }
}

// MARK: - Cloud Client

public final class GPT5Client: CloudLLMClient {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let logger = Logger(subsystem: "ai.pulsum", category: "LLMGateway.Cloud")
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func generateResponse(context: CoachLLMContext,
                                 intentTopic: String?,
                                 candidateMoments: [CandidateMoment],
                                 apiKey: String,
                                 keySource: String) async throws -> CoachPhrasing {
        logger.debug("Sending cloud chat request with JSON schema. Top signal: \(context.topSignal, privacy: .public)")

        var requestedTokens: Int? = nil
        var attempt = 0
        let limitedMoments = Array(candidateMoments.prefix(2))

        while attempt < 2 {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"

            let body = try LLMGateway.makeChatRequestBody(context: context,
                                                          candidateMoments: limitedMoments,
                                                          maxOutputTokens: requestedTokens ?? 512)

            if let text = body["text"] as? [String: Any],
               let format = text["format"] as? [String: Any] {
                let hasName = (format["name"] as? String) == "CoachPhrasing"
                let hasSchema = format["schema"] as? [String: Any] != nil
                let tokenLogValue = body["max_output_tokens"] as? Int ?? -1
                logger.debug("Responses API: max_output_tokens=\(tokenLogValue, privacy: .public) schemaNamePresent=\(hasName) schemaPresent=\(hasSchema)")
            }

            let maxTokens = body["max_output_tokens"] as? Int ?? LLMGateway.clampTokens(512)
            guard validateChatPayload(body: body,
                                      context: context,
                                      intentTopic: intentTopic,
                                      candidateMoments: limitedMoments,
                                      maxTokens: maxTokens) else {
                throw LLMGatewayError.cloudGenerationFailed("Invalid payload structure")
            }

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            logger.debug("LLM using API key from \(keySource, privacy: .public).")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMGatewayError.cloudGenerationFailed("Invalid HTTP response")
            }

            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let phrasing = try parseAndValidateStructuredResponse(data: data)
                    logger.debug("Cloud chat succeeded. Grounding: \(String(format: "%.2f", phrasing.groundingScore), privacy: .public), isOnTopic: \(phrasing.isOnTopic, privacy: .public), hasNextAction: \(phrasing.nextAction != nil, privacy: .public)")
                    return phrasing
                } catch {
                    // If parsing fails due to incomplete response, retry with more tokens
                    let errorMsg = error.localizedDescription
                    if attempt == 0, errorMsg.contains("incomplete") {
                        requestedTokens = 1024
                        attempt += 1
                        logger.info("Retrying with max tokens due to incomplete response")
                        continue
                    }
                    throw error
                }
            }

            let statusCode = httpResponse.statusCode
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(statusCode)"

            if attempt == 0, statusCode == 400, errorMsg.contains("max_output_tokens") {
                requestedTokens = 128
                attempt += 1
                continue
            }

            logger.error("Cloud chat failed. status=\(statusCode), message=\(errorMsg.prefix(256), privacy: .public)")
            throw LLMGatewayError.cloudGenerationFailed(errorMsg)
        }

        throw LLMGatewayError.cloudGenerationFailed("Exceeded retry attempts")
    }

    private func parseAndValidateStructuredResponse(data: Data) throws -> CoachPhrasing {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            logger.error("Failed to parse GPT response: \(errorMsg.prefix(280), privacy: .public)")
            throw LLMGatewayError.cloudGenerationFailed("Invalid JSON structure")
        }

        // Check for incomplete response (token limit exceeded)
        if let status = root["status"] as? String, status == "incomplete",
           let details = root["incomplete_details"] as? [String: Any],
           let reason = details["reason"] as? String {
            logger.warning("GPT response incomplete: \(reason, privacy: .public)")
            throw LLMGatewayError.cloudGenerationFailed("Response incomplete: \(reason)")
        }

        func extractText(from node: Any) -> String? {
            guard let object = node as? [String: Any] else { return nil }
            if let content = object["content"] as? [[String: Any]] {
                for part in content {
                    if let text = part["text"] as? String { return text }
                }
            }
            return nil
        }

        var textPayload: String?

        if let outputArray = root["output"] as? [[String: Any]] {
            for item in outputArray {
                if let text = extractText(from: item) {
                    textPayload = text
                    break
                }
            }
        } else if let outputObject = root["output"] as? [String: Any] {
            textPayload = extractText(from: outputObject)
        }

        if textPayload == nil,
           let choices = root["choices"] as? [[String: Any]],
           let message = choices.first? ["message"] as? [String: Any],
           let text = message["content"] as? String {
            textPayload = text
        }

        // Optional legacy parsed fallback (for older responses/tests)
        if textPayload == nil {
            if let parsed = (root["output"] as? [String: Any])?["parsed"] ?? (root["output"] as? [[String: Any]])?.first? ["parsed"] {
                if let parsedData = try? JSONSerialization.data(withJSONObject: parsed),
                   let parsedString = String(data: parsedData, encoding: .utf8) {
                    textPayload = parsedString
                }
            }
        }

        guard let jsonString = textPayload,
              let jsonData = jsonString.data(using: .utf8) else {
            let snippet = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            logger.error("Failed to locate structured content in GPT response (snippet: \(snippet.prefix(280)), privacy: .public)")
            throw LLMGatewayError.cloudGenerationFailed("Missing structured output")
        }

        let phrasing: CoachPhrasing
        do {
            phrasing = try JSONDecoder().decode(CoachPhrasing.self, from: jsonData)
        } catch {
            let nsError = error as NSError
            logger.error("Failed to decode CoachPhrasing schema. domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
            throw LLMGatewayError.cloudGenerationFailed("Schema validation failed: \(nsError.domain)#\(nsError.code)")
        }

        guard phrasing.isOnTopic else {
            let refusal = phrasing.refusalReason ?? "none"
            logger.notice("GPT marked response as off-topic. Refusal: \(refusal, privacy: .public)")
            throw LLMGatewayError.cloudGenerationFailed("Response marked as off-topic by model")
        }

        return phrasing
    }
}

#if DEBUG
private final class UITestMockCloudClient: CloudLLMClient {
    private let logger = Logger(subsystem: "ai.pulsum", category: "LLMGateway.UITests")

    func generateResponse(context: CoachLLMContext,
                          intentTopic: String?,
                          candidateMoments: [CandidateMoment],
                          apiKey: String,
                          keySource: String) async throws -> CoachPhrasing {
        logger.debug("UITest stub invoked. keySource=\(keySource, privacy: .public)")
        let reply = "Stub response: focus on \(context.topSignal.lowercased()). Three steady breaths and a quick stretch keep momentum."
        return CoachPhrasing(
            coachReply: reply,
            isOnTopic: true,
            groundingScore: 0.99,
            intentTopic: intentTopic ?? "general",
            refusalReason: nil,
            nextAction: "Take a mindful breathing break"
        )
    }
}
#endif

// MARK: - Generator Factory

private func createDefaultLocalGenerator() -> OnDeviceCoachGenerator {
    if #available(iOS 26.0, *) {
        return FoundationModelsCoachGenerator()
    } else {
        return LegacyCoachGenerator()
    }
}

// MARK: - Legacy fallback generator (pre-iOS 26 only)

public final class LegacyCoachGenerator: OnDeviceCoachGenerator {
    private let logger = Logger(subsystem: "ai.pulsum", category: "LLMGateway.Legacy")

    public init() {}

    public func generate(context: CoachLLMContext) async -> CoachReplyPayload {
        logger.warning("Legacy generator called on pre-iOS 26 device. Foundation Models unavailable.")
        // Honest failure - no rule-based coaching
        return CoachReplyPayload(
            coachReply: "Personalized coaching requires iOS 26 or cloud connection. Please update your device or check your internet connection.",
            nextAction: nil
        )
    }
}

extension LLMGateway {
    static func coachFormat() -> [String: Any] {
        CoachPhrasingSchema.responsesFormat()
    }

    static func makeChatRequestBody(context: CoachLLMContext,
                                    candidateMoments: [CandidateMoment],
                                    maxOutputTokens: Int) throws -> [String: Any] {
        let minimized = MinimizedCloudRequest.build(from: context, candidateMoments: candidateMoments)
        let userPayload = try minimized.encodedJSONString()

        let systemMessage =
"""
You are Pulsum, a supportive wellness coach. You MUST return ONLY JSON that matches the CoachPhrasing schema provided via text.format (no prose, no markdown). The user input is a JSON blob with keys: userToneHints, topSignal, topMomentId, rationale, zScoreSummary, candidateMoments[]. Each candidate includes id, title, short, detail, and evidenceBadge. Use ONLY that minimized context (no assumptions, no external data).

Style for coachReply:
- 1–2 short sentences.
- Warm, actionable, specific to the user's top signal and context.
- Avoid disclaimers and generic platitudes.

Field rules:
- isOnTopic: true if the message touches sleep, stress, energy, mood, movement, or nutrition; false otherwise.
- refusalReason: "" when isOnTopic is true; otherwise a short code like "off_topic_smalltalk".
- groundingScore: number 0.0–1.0; estimate confidence from provided z-scores (higher confidence → closer to 1.0). Round to two decimals.
- intentTopic: one of ["sleep","stress","energy","mood","movement","nutrition","goals"] based on the input.
- nextAction: one concrete step the user can do in < 8 words, e.g., "Dim lights 30 min before bed".

Keep JSON compact. Do not echo the schema or input.
"""

        let body: [String: Any] = [
            "model": "gpt-5",
            "input": [
                ["role": "system",
                 "content": systemMessage],
                ["role": "user",
                 "content": userPayload]
            ],
            "max_output_tokens": clampTokens(maxOutputTokens),
            "text": [
                "verbosity": "low",
                "format": coachFormat()
            ]
        ]

        return body
    }

    static func makePingRequestBody() -> [String: Any] {
        return [
            "model": "gpt-5",
            "input": [
                ["role": "user", "content": "ping"]
            ],
            "max_output_tokens": 32,
            "text": [
                "verbosity": "low",
                "format": coachFormat()
            ]
        ]
    }

    fileprivate static func clampTokens(_ requested: Int) -> Int {
        let value = requested
        let minTokens = 128
        let maxTokens = 1024
        return max(minTokens, min(maxTokens, value))
    }
}

extension LLMGateway: @unchecked Sendable {}

// Small helper
private extension String {
    var trimmedNonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
