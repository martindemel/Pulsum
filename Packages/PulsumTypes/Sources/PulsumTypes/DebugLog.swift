import Foundation

public actor DebugLogBuffer {
    public static let shared = DebugLogBuffer()

    private var lines: [String] = []
    private let maxLines = 200

    private init() {}

    public func append(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        lines.append("[\(timestamp)] \(message)")
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }

    public func snapshot() -> String {
        lines.joined(separator: "\n")
    }
}
