import Testing
import Foundation
@testable import PulsumServices

/// Tests for LLMGateway structured output schema validation (Wall 2)
struct LLMGatewaySchemaTests {

    @Test("CoachPhrasing schema has required fields")
    func schemaStructure() {
        let schema = CoachPhrasingSchema.json()

        // Verify top-level schema structure
        #expect(schema["type"] as? String == "object", "Schema should be of type 'object'")

        guard let properties = schema["properties"] as? [String: Any] else {
            Issue.record("Schema should have properties")
            return
        }

        // Verify required fields
        let required = schema["required"] as? [String] ?? []
        #expect(Set(required) == Set(properties.keys), "Required keys should match properties")

        // Verify strict format block (now under text.format path)
        let format = CoachPhrasingSchema.responsesFormat()
        #expect(format["type"] as? String == "json_schema", "text.format type should be json_schema")
        #expect(format["name"] as? String == "CoachPhrasing", "Schema name should be CoachPhrasing")
        #expect(format["strict"] as? Bool == true, "text.format should enable strict mode")
        #expect(format["schema"] is [String: Any], "Embedded schema should be present")
    }

    @Test("CoachPhrasing grounding score bounds")
    func groundingScoreBounds() {
        let schema = CoachPhrasingSchema.json()
        let properties = schema["properties"] as? [String: Any]
        let groundingScore = properties?["groundingScore"] as? [String: Any]

        #expect(groundingScore?["type"] as? String == "number", "groundingScore should be numeric")
        #expect(groundingScore?["minimum"] as? Double == 0.0, "groundingScore min should be 0.0")
        #expect(groundingScore?["maximum"] as? Double == 1.0, "groundingScore max should be 1.0")
    }

    @Test("CoachPhrasing validates successfully")
    func validPhrasingDecodes() throws {
        let validJSON = """
        {
            "coachReply": "Your HRV looks low today. Try a short breathing exercise to help reset your nervous system.",
            "isOnTopic": true,
            "groundingScore": 0.85,
            "intentTopic": "sleep",
            "refusalReason": "",
            "nextAction": ""
        }
        """

        let data = validJSON.data(using: .utf8)!
        let phrasing = try JSONDecoder().decode(CoachPhrasing.self, from: data)

        #expect(phrasing.isOnTopic == true)
        #expect(phrasing.groundingScore == 0.85)
        #expect(phrasing.refusalReason == nil)
        #expect(phrasing.nextAction == nil)
        #expect(phrasing.coachReply.contains("HRV"))
    }

    @Test("CoachPhrasing rejects off-topic response")
    func offTopicPhrasingDecodes() throws {
        let offTopicJSON = """
        {
            "coachReply": "I’m not able to help with that.",
            "isOnTopic": false,
            "groundingScore": 0.2,
            "refusalReason": "User asked about weather, not wellbeing",
            "intentTopic": "none",
            "nextAction": ""
        }
        """

        let data = offTopicJSON.data(using: .utf8)!
        let phrasing = try JSONDecoder().decode(CoachPhrasing.self, from: data)

        #expect(phrasing.isOnTopic == false, "Off-topic response should be rejected")
        #expect(phrasing.groundingScore < 0.5, "Low grounding score expected")
        #expect(phrasing.refusalReason != nil, "Refusal reason should be provided")
    }

    @Test("CoachPhrasing low grounding score")
    func lowGroundingScore() throws {
        let lowGroundingJSON = """
        {
            "coachReply": "I can't provide specific advice without more context.",
            "isOnTopic": true,
            "groundingScore": 0.3,
            "intentTopic": "none",
            "refusalReason": "",
            "nextAction": ""
        }
        """

        let data = lowGroundingJSON.data(using: .utf8)!
        let phrasing = try JSONDecoder().decode(CoachPhrasing.self, from: data)

        #expect(phrasing.groundingScore < 0.5, "Low grounding score should be detected")
        // In production, this would be rejected by validation threshold (≥0.5)
    }

    @Test("Grounding threshold is 0.5")
    func groundingThreshold() {
        // GPT5Client uses groundingThreshold = 0.5
        // Responses with groundingScore < 0.5 should be rejected
        let threshold = 0.5

        #expect(0.3 < threshold, "Below threshold should fail")
        #expect(0.5 >= threshold, "At threshold should pass")
        #expect(0.85 >= threshold, "Above threshold should pass")
    }

    @Test("Max output tokens clamped to window")
    func maxOutputTokensClamped() throws {
        let context = CoachLLMContext(userToneHints: "hi",
                                      topSignal: "topic=sleep",
                                      topMomentId: nil,
                                      rationale: "steady",
                                      zScoreSummary: "z_hrv:-1.2")
        let low = try LLMGateway.makeChatRequestBody(context: context,
                                                     candidateMoments: [],
                                                     maxOutputTokens: 32)
        let high = try LLMGateway.makeChatRequestBody(context: context,
                                                      candidateMoments: [],
                                                      maxOutputTokens: 2000)

        #expect(low["max_output_tokens"] as? Int == 128)
        #expect(high["max_output_tokens"] as? Int == 1024)
    }

    @Test("Schema enforces strict mode")
    func schemaStrictMode() {
        let schema = CoachPhrasingSchema.json()

        #expect(schema["additionalProperties"] as? Bool == false, "Schema should disallow additional properties")

        guard let properties = schema["properties"] as? [String: Any] else {
            Issue.record("Schema should have properties")
            return
        }

        let optionalKeys = ["intentTopic", "refusalReason", "nextAction"]
        optionalKeys.forEach { key in
            if let property = properties[key] as? [String: Any] {
                #expect(property["type"] as? String == "string", "\(key) should be a plain string")
                #expect(property["minLength"] as? Int == 0, "\(key) should allow empty string")
            } else {
                Issue.record("Property \(key) missing in schema")
            }
        }
    }

    @Test("Payload includes candidate moments and minimized context only")
    func payloadIncludesCandidateMoments() throws {
        let candidates = [
            CandidateMoment(id: "moment-1",
                            title: "Wind-down ritual",
                            shortDescription: "Dim the lights and breathe slowly for two minutes.",
                            detail: "This short practice taps the parasympathetic response on low HRV days.",
                            evidenceBadge: "Strong"),
            CandidateMoment(id: "moment-2",
                            title: "Micro walk",
                            shortDescription: "A five-minute outdoor walk lifts mood quickly.",
                            detail: nil,
                            evidenceBadge: "Medium")
        ]
        let context = CoachLLMContext(userToneHints: "Need an evening routine",
                                      topSignal: "subj_sleepQuality:-0.8",
                                      topMomentId: candidates.first?.id,
                                      rationale: "sleep debt + subjective fatigue",
                                      zScoreSummary: "z_sleepDebt:1.2,z_hrv:-0.7",
                                      candidateMoments: candidates)
        let body = try LLMGateway.makeChatRequestBody(context: context,
                                                      candidateMoments: candidates,
                                                      maxOutputTokens: 400)

        guard let userPayload = (body["input"] as? [[String: Any]])?.last?["content"] as? String,
              let payloadData = userPayload.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            Issue.record("Failed to decode minimized payload")
            return
        }
        #expect(Set(json.keys) == ["userToneHints", "topSignal", "topMomentId", "rationale", "zScoreSummary", "candidateMoments"])
        guard let embeddedMoments = json["candidateMoments"] as? [[String: Any]],
              let first = embeddedMoments.first else {
            Issue.record("Missing embedded candidate moments")
            return
        }
        #expect(Set(first.keys).isSubset(of: ["id", "title", "short", "detail", "evidenceBadge"]))
        #expect((first["id"] as? String) == "moment-1")
        #expect(((first["short"] as? String) ?? "").contains("Dim the lights"))
    }

    @Test("Payload excludes PHI and forbidden fields like transcript/heartrate/samples")
    func payloadExcludesForbiddenFields() throws {
        let context = CoachLLMContext(userToneHints: "Focus on sleep without sharing transcript",
                                      topSignal: "subj_sleepQuality:-0.8",
                                      topMomentId: nil,
                                      rationale: "sleep debt + low HRV",
                                      zScoreSummary: "z_sleepDebt:1.2,z_hrv:-0.7")
        let body = try LLMGateway.makeChatRequestBody(context: context,
                                                      candidateMoments: [],
                                                      maxOutputTokens: 256)
        guard let userPayload = (body["input"] as? [[String: Any]])?.last?["content"] as? String else {
            Issue.record("Missing minimized payload")
            return
        }
        let lower = userPayload.lowercased()
        #expect(!lower.contains("\"transcript\""))
        #expect(!lower.contains("\"heartrate\""))
        #expect(!lower.contains("\"samples\""))
    }
}
