import Foundation

/// Canonical strict schema for GPT‑5 structured coach phrasing.
/// All fields are 'required' (strict JSON mode), but semantically-optional
/// ones ("refusalReason", "nextAction", "intentTopic") must allow empty "".
public enum CoachPhrasingSchema {
    public static func json() -> [String: Any] {
        // Properties dictionary
        let props: [String: Any] = [
            "coachReply": [
                "type": "string",
                "minLength": 1,
                "maxLength": 280,
                "description": "Reply ≤2 sentences, ≤280 chars total."
            ],
            "isOnTopic": [
                "type": "boolean",
                "description": "Model’s own topicality check."
            ],
            "groundingScore": [
                "type": "number",
                "minimum": 0.0,
                "maximum": 1.0,
                "description": "Self-assessed grounding in provided context."
            ],
            "intentTopic": [
                "type": "string",
                "minLength": 0,
                "maxLength": 32,
                "enum": ["sleep","stress","energy","hrv","mood","movement","mindfulness","goals","none"],
                "description": "Echo of deterministic routing topic (or 'none')."
            ],
            "refusalReason": [
                "type": "string",
                "minLength": 0,
                "maxLength": 160,
                "description": "Empty string when not refusing/cautioning."
            ],
            "nextAction": [
                "type": "string",
                "minLength": 0,
                "maxLength": 120,
                "description": "Optional micro-action; empty string when N/A."
            ]
        ]

        // strict=true requires every property to be in 'required'
        let required = Array(props.keys).sorted()

        return [
            "type": "object",
            "additionalProperties": false,
            "properties": props,
            "required": required
        ]
    }

    /// Top-level Responses API wrapper for strict JSON Schema output
    public static func responsesFormat() -> [String: Any] {
        return [
            "type": "json_schema",
            "name": "CoachPhrasing",
            "schema": CoachPhrasingSchema.json(),
            "strict": true
        ]
    }
}
