import Foundation

public struct DiagnosticsReportContext: Sendable {
    public let appVersion: String
    public let buildNumber: String
    public let deviceModel: String
    public let osVersion: String
    public let locale: String
    public let sessionId: UUID
    public let diagnosticsEnabled: Bool
    public let persistenceEnabled: Bool

    public init(appVersion: String,
                buildNumber: String,
                deviceModel: String,
                osVersion: String,
                locale: String,
                sessionId: UUID,
                diagnosticsEnabled: Bool,
                persistenceEnabled: Bool) {
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.locale = locale
        self.sessionId = sessionId
        self.diagnosticsEnabled = diagnosticsEnabled
        self.persistenceEnabled = persistenceEnabled
    }
}

public struct DiagnosticsSnapshot: Sendable {
    public var healthGrantedCount: Int?
    public var healthDeniedCount: Int?
    public var healthPendingCount: Int?
    public var healthAvailability: DiagnosticsSafeString?
    public var embeddingsAvailable: Bool?
    public var pendingJournalsCount: Int?
    public var backfillWarmCompleted: Int?
    public var backfillFullCompleted: Int?
    public var deferredLibraryImport: Bool?
    public var lastSnapshotDay: String?
    public var wellbeingScore: Double?

    public init(healthGrantedCount: Int? = nil,
                healthDeniedCount: Int? = nil,
                healthPendingCount: Int? = nil,
                healthAvailability: DiagnosticsSafeString? = nil,
                embeddingsAvailable: Bool? = nil,
                pendingJournalsCount: Int? = nil,
                backfillWarmCompleted: Int? = nil,
                backfillFullCompleted: Int? = nil,
                deferredLibraryImport: Bool? = nil,
                lastSnapshotDay: String? = nil,
                wellbeingScore: Double? = nil) {
        self.healthGrantedCount = healthGrantedCount
        self.healthDeniedCount = healthDeniedCount
        self.healthPendingCount = healthPendingCount
        self.healthAvailability = healthAvailability
        self.embeddingsAvailable = embeddingsAvailable
        self.pendingJournalsCount = pendingJournalsCount
        self.backfillWarmCompleted = backfillWarmCompleted
        self.backfillFullCompleted = backfillFullCompleted
        self.deferredLibraryImport = deferredLibraryImport
        self.lastSnapshotDay = lastSnapshotDay
        self.wellbeingScore = wellbeingScore
    }
}

public enum DiagnosticsReportBuilder {
    public static func buildReport(context: DiagnosticsReportContext,
                                   snapshot: DiagnosticsSnapshot,
                                   logTail: [String]) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let safeTimestamp = timestamp.replacingOccurrences(of: ":", with: "-")
        var sections: [String] = []
        sections.append("Pulsum Diagnostics Report")
        sections.append("Generated: \(timestamp)")
        sections.append("")
        sections.append("[Header]")
        sections.append("app_version=\(context.appVersion)")
        sections.append("build_number=\(context.buildNumber)")
        sections.append("device_model=\(context.deviceModel)")
        sections.append("os_version=\(context.osVersion)")
        sections.append("locale=\(context.locale)")
        sections.append("session_id=\(context.sessionId.uuidString)")
        sections.append("diagnostics_enabled=\(context.diagnosticsEnabled)")
        sections.append("persistence_enabled=\(context.persistenceEnabled)")

        sections.append("")
        sections.append("[Snapshot]")
        if let granted = snapshot.healthGrantedCount {
            sections.append("health_granted=\(granted)")
        }
        if let denied = snapshot.healthDeniedCount {
            sections.append("health_denied=\(denied)")
        }
        if let pending = snapshot.healthPendingCount {
            sections.append("health_pending=\(pending)")
        }
        if let availability = snapshot.healthAvailability {
            sections.append("health_availability=\(availability.value)")
        }
        if let available = snapshot.embeddingsAvailable {
            sections.append("embeddings_available=\(available)")
        }
        if let pending = snapshot.pendingJournalsCount {
            sections.append("pending_journals_count=\(pending)")
        }
        if let warm = snapshot.backfillWarmCompleted {
            sections.append("backfill_warm_completed_types=\(warm)")
        }
        if let full = snapshot.backfillFullCompleted {
            sections.append("backfill_full_completed_types=\(full)")
        }
        if let deferred = snapshot.deferredLibraryImport {
            sections.append("deferred_library_import=\(deferred)")
        }
        if let day = snapshot.lastSnapshotDay {
            sections.append("last_snapshot_day=\(day)")
        }
        if let score = snapshot.wellbeingScore {
            sections.append(String(format: "last_wellbeing_score=%.3f", score))
        }

        sections.append("")
        sections.append("[Logs]")
        if logTail.isEmpty {
            sections.append("No diagnostics captured yet.")
        } else {
            sections.append(contentsOf: logTail)
        }

        let content = sections.joined(separator: "\n")
        let directory = DiagnosticsLogger.diagnosticsDirectory()
        let url = directory.appendingPathComponent("PulsumDiagnostics-\(safeTimestamp).txt")
        guard let data = content.data(using: .utf8) else {
            throw NSError(domain: "PulsumDiagnostics", code: -1)
        }
        try data.write(to: url, options: .atomic)
        DiagnosticsLogger.applySecurityAttributes(to: url)
        return url
    }
}
