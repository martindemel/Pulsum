import Dispatch
import Foundation
import OSLog
import os.signpost

public enum Diagnostics {
    private static let sessionIdentifier = UUID()
    private static let subsystem = "com.pulsum"
    private static let signpostLogs: [DiagnosticsCategory: OSLog] = Dictionary(uniqueKeysWithValues: DiagnosticsCategory.allCases.map {
        ($0, OSLog(subsystem: subsystem, category: $0.rawValue))
    })

    public static var sessionId: UUID { sessionIdentifier }

    public static func log(level: DiagnosticsLevel,
                           category: DiagnosticsCategory,
                           name: String,
                           fields: [String: DiagnosticsValue] = [:],
                           traceId: UUID? = nil,
                           error: Error? = nil,
                           errorDomain: DiagnosticsSafeString? = nil,
                           errorCode: Int? = nil,
                           durationMs: Double? = nil) {
        let config = DiagnosticsConfigStore.current
        guard config.enabled, level >= config.minLevel else { return }
        let errorInfo = resolveError(error, fallbackDomain: errorDomain, fallbackCode: errorCode)
        let event = DiagnosticsEvent(timestamp: Date(),
                                     level: level,
                                     category: category,
                                     name: name,
                                     sessionId: sessionIdentifier,
                                     traceId: traceId,
                                     fields: fields,
                                     errorDomain: errorInfo.domain,
                                     errorCode: errorInfo.code,
                                     durationMs: durationMs)
        DiagnosticsLogger.enqueue(event: event, configSnapshot: config)
    }

    public static func span(category: DiagnosticsCategory,
                            name: String,
                            fields: [String: DiagnosticsValue] = [:],
                            traceId: UUID? = nil,
                            level: DiagnosticsLevel = .info) -> DiagnosticsSpanToken {
        let config = DiagnosticsConfigStore.current
        guard config.enabled, level >= config.minLevel else {
            return DiagnosticsSpanToken(isEnabled: false,
                                        category: category,
                                        name: name,
                                        traceId: traceId,
                                        baseFields: fields,
                                        signpostLog: nil,
                                        level: level)
        }
        let signpostLog = config.enableSignposts ? signpostLogs[category] : nil
        let token = DiagnosticsSpanToken(isEnabled: true,
                                         category: category,
                                         name: name,
                                         traceId: traceId,
                                         baseFields: fields,
                                         signpostLog: signpostLog,
                                         level: level)
        log(level: level, category: category, name: "\(name).begin", fields: fields, traceId: traceId)
        token.beginSignpost()
        return token
    }

    public static func measure<T>(category: DiagnosticsCategory,
                                  name: String,
                                  fields: [String: DiagnosticsValue] = [:],
                                  traceId: UUID? = nil,
                                  level: DiagnosticsLevel = .info,
                                  operation: @Sendable () async throws -> T) async rethrows -> T {
        let token = span(category: category,
                         name: name,
                         fields: fields,
                         traceId: traceId,
                         level: level)
        do {
            let result = try await operation()
            token.end(additionalFields: [:], error: nil)
            return result
        } catch {
            token.end(additionalFields: [:], error: error)
            throw error
        }
    }

    public static func updateConfig(_ config: DiagnosticsConfig) {
        DiagnosticsConfigStore.update(config)
        DiagnosticsLogger.updateConfig(config)
    }

    public static func currentConfig() -> DiagnosticsConfig {
        DiagnosticsConfigStore.current
    }

    public static func clearDiagnostics() async {
        await DebugLogBuffer.shared.clear()
        await DiagnosticsLogger.shared.clearPersistedLogs()
    }

    public static func persistedLogTail(maxLines: Int) async -> [String] {
        await DiagnosticsLogger.shared.persistedLogTail(maxLines: maxLines)
    }

    public static func flushPersistence() async {
        await DiagnosticsLogger.shared.flushPending()
    }

    private static func resolveError(_ error: Error?,
                                     fallbackDomain: DiagnosticsSafeString?,
                                     fallbackCode: Int?) -> (domain: DiagnosticsSafeString?, code: Int?) {
        if fallbackDomain != nil || fallbackCode != nil {
            return (fallbackDomain, fallbackCode)
        }
        guard let error else { return (nil, nil) }
        let nsError = error as NSError
        let allowlist: Set<String> = [
            NSCocoaErrorDomain,
            NSURLErrorDomain,
            NSPOSIXErrorDomain,
            NSOSStatusErrorDomain,
            "CMErrorDomain",
            "AVFoundationErrorDomain",
            "AVErrorDomain",
            "HKErrorDomain",
            "PulsumErrorDomain"
        ]
        let domain = DiagnosticsSafeString.stage(nsError.domain, allowed: allowlist)
        return (domain, nsError.code)
    }
}

public struct DiagnosticsSpanToken {
    private let isEnabled: Bool
    private let category: DiagnosticsCategory
    private let name: String
    private let traceId: UUID?
    private let baseFields: [String: DiagnosticsValue]
    private let start: ContinuousClock.Instant
    private let signpostID: OSSignpostID
    private let signpostLog: OSLog?
    private let level: DiagnosticsLevel

    init(isEnabled: Bool,
         category: DiagnosticsCategory,
         name: String,
         traceId: UUID?,
         baseFields: [String: DiagnosticsValue],
         signpostLog: OSLog?,
         level: DiagnosticsLevel) {
        self.isEnabled = isEnabled
        self.category = category
        self.name = name
        self.traceId = traceId
        self.baseFields = baseFields
        self.signpostID = OSSignpostID(log: signpostLog ?? OSLog.disabled)
        self.signpostLog = signpostLog
        self.level = level
        self.start = ContinuousClock().now
    }

    fileprivate func beginSignpost() {
        guard isEnabled, let signpostLog else { return }
        os_signpost(.begin,
                    log: signpostLog,
                    name: "diagnostics.span",
                    signpostID: signpostID,
                    "%{public}s",
                    name)
    }

    public func end(additionalFields: [String: DiagnosticsValue] = [:], error: Error?) {
        guard isEnabled else { return }
        let elapsed = ContinuousClock().now - start
        let millis = Double(elapsed.components.seconds) * 1_000 + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000.0
        var mergedFields = baseFields
        additionalFields.forEach { mergedFields[$0.key] = $0.value }
        Diagnostics.log(level: error == nil ? level : .error,
                        category: category,
                        name: "\(name).end",
                        fields: mergedFields,
                        traceId: traceId,
                        error: error,
                        durationMs: millis)
        guard let signpostLog else { return }
        os_signpost(.end,
                    log: signpostLog,
                    name: "diagnostics.span",
                    signpostID: signpostID,
                    "event=%{public}s duration_ms=%{public}.3f",
                    name,
                    millis)
    }
}

public actor DiagnosticsStallMonitor {
    private let category: DiagnosticsCategory
    private let name: String
    private let traceId: UUID?
    private let threshold: TimeInterval
    private var lastHeartbeat: Date
    private var lastFields: [String: DiagnosticsValue]
    private var task: Task<Void, Never>?
    private var isActive = false

    public init(category: DiagnosticsCategory,
                name: String,
                traceId: UUID?,
                thresholdSeconds: TimeInterval,
                initialFields: [String: DiagnosticsValue] = [:]) {
        self.category = category
        self.name = name
        self.traceId = traceId
        self.threshold = thresholdSeconds
        self.lastHeartbeat = Date()
        self.lastFields = initialFields
    }

    deinit {
        task?.cancel()
    }

    public func heartbeat(progressFields: [String: DiagnosticsValue] = [:]) {
        lastHeartbeat = Date()
        progressFields.forEach { lastFields[$0.key] = $0.value }
    }

    public func start() {
        guard task == nil else { return }
        isActive = true
        let thresholdSeconds = threshold
        task = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.monitorLoop(thresholdSeconds: thresholdSeconds)
        }
    }

    public func stop(finalFields: [String: DiagnosticsValue] = [:]) {
        isActive = false
        task?.cancel()
        task = nil
        finalFields.forEach { lastFields[$0.key] = $0.value }
    }

    private func monitorLoop(thresholdSeconds: TimeInterval) async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(thresholdSeconds * 500_000_000))
            await checkForStallIfActive()
            if !isActive {
                break
            }
        }
    }

    private func checkForStallIfActive() async {
        guard isActive else { return }
        let elapsed = Date().timeIntervalSince(lastHeartbeat)
        guard elapsed >= threshold else { return }
        Diagnostics.log(level: .warn,
                        category: category,
                        name: "\(name).stall",
                        fields: lastFields,
                        traceId: traceId,
                        durationMs: elapsed * 1_000)
        lastHeartbeat = Date()
    }
}

public actor DiagnosticsLogger {
    static let shared = DiagnosticsLogger()

    private var config: DiagnosticsConfig
    private let formatter: ISO8601DateFormatter
    private let subsystem = "com.pulsum"
    private let osLoggers: [DiagnosticsCategory: Logger]
    private var pendingLines: [String] = []
    private var pendingBytes: Int = 0
    private var flushTask: Task<Void, Never>?
    private let flushInterval: TimeInterval = 1.0
    private let logDirectoryURL: URL
    private var currentLogURL: URL?

    private init() {
        self.config = DiagnosticsConfigStore.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.formatter = formatter
        var loggerMap: [DiagnosticsCategory: Logger] = [:]
        for category in DiagnosticsCategory.allCases {
            loggerMap[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
        self.osLoggers = loggerMap
        self.logDirectoryURL = DiagnosticsLogger.makeDirectory()
    }

    nonisolated static func enqueue(event: DiagnosticsEvent, configSnapshot: DiagnosticsConfig) {
        Task.detached(priority: .utility) {
            await DiagnosticsLogger.shared.record(event: event, configSnapshot: configSnapshot)
        }
    }

    nonisolated static func updateConfig(_ config: DiagnosticsConfig) {
        Task.detached(priority: .utility) {
            await DiagnosticsLogger.shared.apply(config: config)
        }
    }

    func apply(config: DiagnosticsConfig) {
        self.config = config
    }

    func record(event: DiagnosticsEvent, configSnapshot: DiagnosticsConfig) async {
        self.config = configSnapshot
        let formatted = format(event: event)
        await DebugLogBuffer.shared.appendFormattedLine(formatted)

        if config.mirrorToOSLog {
            mirrorToOSLog(event: event)
        }

        if config.persistToDisk {
            await enqueueForPersistence(formatted)
        }
    }

    func flushPending() async {
        let lines = pendingLines
        pendingLines.removeAll()
        pendingBytes = 0
        flushTask?.cancel()
        flushTask = nil
        guard !lines.isEmpty else { return }
        await write(lines: lines)
    }

    func clearPersistedLogs() async {
        flushTask?.cancel()
        flushTask = nil
        pendingLines.removeAll()
        pendingBytes = 0
        try? FileManager.default.removeItem(at: logDirectoryURL)
        _ = DiagnosticsLogger.makeDirectory()
        currentLogURL = nil
    }

    func persistedLogTail(maxLines: Int) async -> [String] {
        await flushPending()
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: logDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return []
        }
        let candidates: [(index: Int, url: URL)] = files.compactMap { url in
            let name = url.lastPathComponent
            if name == "diagnostics.log" {
                return (0, url)
            }
            let prefix = "diagnostics.log."
            if name.hasPrefix(prefix), let index = Int(name.dropFirst(prefix.count)) {
                return (index, url)
            }
            return nil
        }
        let sorted = candidates.sorted {
            if $0.index == $1.index {
                return $0.url.path < $1.url.path
            }
            return $0.index > $1.index
        }

        var collected: [String] = []
        for (_, url) in sorted {
            guard let data = try? Data(contentsOf: url),
                  let content = String(data: data, encoding: .utf8) else { continue }
            let lines = content.split(separator: "\n").map(String.init)
            collected.append(contentsOf: lines)
        }
        if collected.count > maxLines {
            collected = Array(collected.suffix(maxLines))
        }
        return collected
    }

    private func format(event: DiagnosticsEvent) -> String {
        let timestamp = formatter.string(from: event.timestamp)
        var components: [String] = []
        components.append("[\(timestamp)]")
        components.append("[\(event.level.label)]")
        components.append("[\(event.category.rawValue)]")
        components.append(event.name)
        components.append("session=\(event.sessionId.uuidString)")
        if let traceId = event.traceId {
            components.append("trace=\(traceId.uuidString)")
        }

        var keyValues: [String: DiagnosticsValue] = event.fields
        if let duration = event.durationMs {
            keyValues["duration_ms"] = .double(duration)
        }
        if let errorDomain = event.errorDomain {
            keyValues["error_domain"] = .safeString(errorDomain)
        }
        if let errorCode = event.errorCode {
            keyValues["error_code"] = .int(errorCode)
        }

        for key in keyValues.keys.sorted() {
            if let value = keyValues[key] {
                components.append("\(key)=\(value.toDisplayString())")
            }
        }
        return components.joined(separator: " ")
    }

    private func mirrorToOSLog(event: DiagnosticsEvent) {
        let logger = osLoggers[event.category] ?? Logger(subsystem: subsystem, category: event.category.rawValue)
        let keyValuesSummary = event.fields
            .map { "\($0.key)=\($0.value.toDisplayString())" }
            .joined(separator: " ")
        logger.log(level: osLogType(for: event.level),
                   "\(event.name, privacy: .public) session=\(event.sessionId.uuidString, privacy: .public) trace=\(event.traceId?.uuidString ?? "none", privacy: .public) \(keyValuesSummary, privacy: .public)")
    }

    private func osLogType(for level: DiagnosticsLevel) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warn: return .default
        case .error: return .error
        }
    }

    private func enqueueForPersistence(_ line: String) async {
        pendingLines.append(line)
        pendingBytes += line.utf8.count + 1
        let threshold = max(4096, config.maxFileBytes / 8)
        if pendingBytes >= threshold {
            await flushPending()
            return
        }
        scheduleFlushIfNeeded()
    }

    private func scheduleFlushIfNeeded() {
        guard flushTask == nil else { return }
        flushTask = Task.detached(priority: .utility) { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((self?.flushInterval ?? 1.0) * 1_000_000_000))
            await self?.flushPending()
        }
    }

    private func write(lines: [String]) async {
        let joined = lines.joined(separator: "\n") + "\n"
        guard let data = joined.data(using: .utf8) else { return }
        do {
            try rotateIfNeeded(addingBytes: data.count)
            let url = try ensureLogFile()
            if let handle = try? FileHandle(forWritingTo: url) {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: url, options: [.atomic])
            }
        } catch {
            // Persisted logging is best-effort; intentionally swallow errors.
        }
    }

    private func ensureLogFile() throws -> URL {
        if let currentLogURL {
            return currentLogURL
        }
        let url = logDirectoryURL.appendingPathComponent("diagnostics.log")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
            Self.applySecurityAttributes(to: url)
        }
        currentLogURL = url
        return url
    }

    private func rotateIfNeeded(addingBytes: Int) throws {
        let url = try ensureLogFile()
        let currentSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        guard currentSize + addingBytes > config.maxFileBytes else { return }
        let fm = FileManager.default
        for index in stride(from: config.maxFiles - 1, through: 1, by: -1) {
            let source = logDirectoryURL.appendingPathComponent("diagnostics.log.\(index)")
            let target = logDirectoryURL.appendingPathComponent("diagnostics.log.\(index + 1)")
            if fm.fileExists(atPath: target.path) {
                try? fm.removeItem(at: target)
            }
            if fm.fileExists(atPath: source.path) {
                try? fm.moveItem(at: source, to: target)
            }
        }
        let rotated = logDirectoryURL.appendingPathComponent("diagnostics.log.1")
        try? fm.removeItem(at: rotated)
        if fm.fileExists(atPath: url.path) {
            try fm.moveItem(at: url, to: rotated)
        }
        currentLogURL = nil
    }

    nonisolated static func applySecurityAttributes(to url: URL) {
#if os(iOS)
        try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
#endif
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(resourceValues)
    }

    nonisolated static func diagnosticsDirectory() -> URL {
        makeDirectory()
    }

    private static func makeDirectory() -> URL {
        DiagnosticsPaths.logsDirectory()
    }
}
