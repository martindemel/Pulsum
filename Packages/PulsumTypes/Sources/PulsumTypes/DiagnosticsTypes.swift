import Foundation

public enum DiagnosticsLevel: Int, Codable, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3

    public static func < (lhs: DiagnosticsLevel, rhs: DiagnosticsLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }
}

public enum DiagnosticsCategory: String, Codable, CaseIterable, Sendable {
    case app
    case ui
    case orchestrator
    case healthkit
    case dataAgent
    case backfill
    case embeddings
    case sentiment
    case library
    case vectorIndex
    case coach
    case llm
    case speech
    case safety
    case persistence
}

public struct DiagnosticsSafeString: Codable, Sendable, Hashable {
    public let value: String

    private init(_ value: String) {
        self.value = value
    }

    public static func literal(_ value: StaticString) -> DiagnosticsSafeString {
        DiagnosticsSafeString(String(describing: value))
    }

    public static func enumCase<T: RawRepresentable>(_ value: T) -> DiagnosticsSafeString where T.RawValue == String {
        DiagnosticsSafeString(value.rawValue)
    }

    public static func stage(_ value: String, allowed: Set<String>) -> DiagnosticsSafeString {
        guard allowed.contains(value) else { return .redacted() }
        return DiagnosticsSafeString(value)
    }

    public static func metadata(_ value: String, maxLength: Int = 48) -> DiagnosticsSafeString {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .redacted() }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-+")
        let filteredScalars = trimmed.unicodeScalars.filter { allowed.contains($0) }
        guard filteredScalars.count == trimmed.unicodeScalars.count else { return .redacted() }
        guard !filteredScalars.isEmpty else { return .redacted() }
        let limited = String(String.UnicodeScalarView(filteredScalars).prefix(maxLength))
        return DiagnosticsSafeString(limited)
    }

    public static func redacted() -> DiagnosticsSafeString {
        DiagnosticsSafeString("<redacted>")
    }
}

public enum DiagnosticsValue: Codable, Sendable, Hashable {
    case int(Int)
    case double(Double)
    case bool(Bool)
    case safeString(DiagnosticsSafeString)
    case day(String)
    case uuid(UUID)

    public static func day(_ date: Date) -> DiagnosticsValue {
        .day(DiagnosticsDayFormatter.dayString(from: date))
    }

    public func toDisplayString() -> String {
        switch self {
        case .int(let value): return String(value)
        case .double(let value): return String(format: "%.3f", value)
        case .bool(let value): return value ? "true" : "false"
        case .safeString(let value): return value.value
        case .day(let value): return value
        case .uuid(let value): return value.uuidString
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum ValueType: String, Codable {
        case int
        case double
        case bool
        case safeString
        case day
        case uuid
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .int:
            self = try .int(container.decode(Int.self, forKey: .value))
        case .double:
            self = try .double(container.decode(Double.self, forKey: .value))
        case .bool:
            self = try .bool(container.decode(Bool.self, forKey: .value))
        case .safeString:
            self = try .safeString(container.decode(DiagnosticsSafeString.self, forKey: .value))
        case .day:
            self = try .day(container.decode(String.self, forKey: .value))
        case .uuid:
            self = try .uuid(container.decode(UUID.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .int(let value):
            try container.encode(ValueType.int, forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode(ValueType.double, forKey: .type)
            try container.encode(value, forKey: .value)
        case .bool(let value):
            try container.encode(ValueType.bool, forKey: .type)
            try container.encode(value, forKey: .value)
        case .safeString(let value):
            try container.encode(ValueType.safeString, forKey: .type)
            try container.encode(value, forKey: .value)
        case .day(let value):
            try container.encode(ValueType.day, forKey: .type)
            try container.encode(value, forKey: .value)
        case .uuid(let value):
            try container.encode(ValueType.uuid, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

public struct DiagnosticsEvent: Codable, Sendable, Hashable {
    public let timestamp: Date
    public let level: DiagnosticsLevel
    public let category: DiagnosticsCategory
    public let name: String
    public let sessionId: UUID
    public let traceId: UUID?
    public let fields: [String: DiagnosticsValue]
    public let errorDomain: DiagnosticsSafeString?
    public let errorCode: Int?
    public let durationMs: Double?

    enum CodingKeys: String, CodingKey {
        case timestamp = "ts"
        case level
        case category
        case name
        case sessionId = "session_id"
        case traceId = "trace_id"
        case fields
        case errorDomain = "error_domain"
        case errorCode = "error_code"
        case durationMs = "duration_ms"
    }
}

public struct DiagnosticsConfig: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var minLevel: DiagnosticsLevel
    public var persistToDisk: Bool
    public var mirrorToOSLog: Bool
    public var enableSignposts: Bool
    public var maxFileBytes: Int
    public var maxFiles: Int
    public var logTailLinesForExport: Int

    public static func `default`() -> DiagnosticsConfig {
        #if DEBUG
        return DiagnosticsConfig(enabled: true,
                                 minLevel: .debug,
                                 persistToDisk: true,
                                 mirrorToOSLog: true,
                                 enableSignposts: true,
                                 maxFileBytes: 3_000_000,
                                 maxFiles: 3,
                                 logTailLinesForExport: 2_000)
        #else
        return DiagnosticsConfig(enabled: true,
                                 minLevel: .info,
                                 persistToDisk: true,
                                 mirrorToOSLog: true,
                                 enableSignposts: true,
                                 maxFileBytes: 3_000_000,
                                 maxFiles: 3,
                                 logTailLinesForExport: 2_000)
        #endif
    }
}

public enum DiagnosticsConfigStore {
    private static let defaultsKey = PulsumDefaultsKey.diagnosticsConfig

    public static var current: DiagnosticsConfig {
        loadFromDefaults() ?? DiagnosticsConfig.default()
    }

    public static func update(_ config: DiagnosticsConfig) {
        persist(config)
    }

    private static func loadFromDefaults() -> DiagnosticsConfig? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(DiagnosticsConfig.self, from: data)
    }

    private static func persist(_ config: DiagnosticsConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}

public enum DiagnosticsDayFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public static func dayString(from date: Date) -> String {
        formatter.string(from: date)
    }
}
