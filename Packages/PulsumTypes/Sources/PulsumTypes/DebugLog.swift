import Foundation

public actor DebugLogBuffer {
    public static let shared = DebugLogBuffer()

    private var lines: [String] = []
    private let maxLines = 30_000
    private let formatter: ISO8601DateFormatter

    private init() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.formatter = formatter
    }

    public func append(_ message: String) {
        let timestamp = formatter.string(from: Date())
        lines.append("[\(timestamp)] \(message)")
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }

    public func appendFormattedLine(_ line: String) {
        lines.append(line)
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }

    public func snapshot() -> String {
        lines.joined(separator: "\n")
    }

    public func tail(maxLines: Int) -> [String] {
        guard maxLines > 0 else { return [] }
        if lines.count <= maxLines { return lines }
        return Array(lines.suffix(maxLines))
    }

    public func clear() {
        lines.removeAll()
    }

#if DEBUG
    public func _testReset() {
        lines.removeAll()
    }
#endif
}
