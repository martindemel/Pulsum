import XCTest
@testable import PulsumTypes

final class DiagnosticsLoggerTests: XCTestCase {

    override func setUp() async throws {
        await Diagnostics.clearDiagnostics()
        #if DEBUG
        await DebugLogBuffer.shared._testReset()
        #else
        await DebugLogBuffer.shared.clear()
        #endif
        let exportsDir = DiagnosticsPaths.exportsDirectory()
        try? FileManager.default.removeItem(at: exportsDir)
        _ = DiagnosticsPaths.exportsDirectory()
        var config = DiagnosticsConfig.default()
        config.enabled = true
        config.persistToDisk = true
        config.mirrorToOSLog = false
        config.enableSignposts = false
        config.maxFileBytes = 512
        config.maxFiles = 2
        config.logTailLinesForExport = 50
        Diagnostics.updateConfig(config)
    }

    func testFormattedLogIncludesSessionAndCategory() async throws {
        Diagnostics.log(level: .info,
                        category: .app,
                        name: "test.event",
                        fields: ["count": .int(1)])
        try await Task.sleep(nanoseconds: 200_000_000)
        let snapshot = await DebugLogBuffer.shared.snapshot()
        XCTAssertTrue(snapshot.contains("test.event"))
        XCTAssertTrue(snapshot.contains("session="))
        XCTAssertTrue(snapshot.contains("[app]"))
    }

    func testRotationRespectsMaxFilesAndBackupExclusion() async throws {
        await Diagnostics.clearDiagnostics()
        var config = Diagnostics.currentConfig()
        config.persistToDisk = true
        config.mirrorToOSLog = false
        config.enableSignposts = false
        config.maxFileBytes = 200
        config.maxFiles = 2
        Diagnostics.updateConfig(config)

        for idx in 0..<25 {
            Diagnostics.log(level: .info,
                            category: .app,
                            name: "rotate.event",
                            fields: ["idx": .int(idx)])
        }
        try await Task.sleep(nanoseconds: 400_000_000)
        await Diagnostics.flushPersistence()

        let diagnosticsDir = DiagnosticsPaths.logsDirectory()
        let files = try FileManager.default.contentsOfDirectory(at: diagnosticsDir, includingPropertiesForKeys: [.isExcludedFromBackupKey], options: [.skipsHiddenFiles])
        let logFiles = files.filter { $0.lastPathComponent.hasPrefix("diagnostics.log") }
        XCTAssertLessThanOrEqual(logFiles.count, 2)
        if let primary = logFiles.first(where: { $0.lastPathComponent == "diagnostics.log" }) {
            let values = try primary.resourceValues(forKeys: [.isExcludedFromBackupKey])
            XCTAssertEqual(values.isExcludedFromBackup, true)
        }
    }

    func testExportReportContainsHeaderAndSnapshot() throws {
        let context = DiagnosticsReportContext(appVersion: "1.0.0",
                                               buildNumber: "100",
                                               deviceModel: "TestDevice",
                                               osVersion: "17.0",
                                               locale: "en_US",
                                               sessionId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                                               diagnosticsEnabled: true,
                                               persistenceEnabled: true,
                                               sessionsIncluded: nil)
        let snapshot = DiagnosticsSnapshot(healthGrantedCount: 2,
                                           healthDeniedCount: 1,
                                           healthPendingCount: 0,
                                           healthAvailability: DiagnosticsSafeString.stage("available", allowed: ["available", "unavailable"]),
                                           embeddingsAvailable: true,
                                           pendingJournalsCount: 0,
                                           backfillWarmCompleted: 2,
                                           backfillFullCompleted: 1,
                                           deferredLibraryImport: false,
                                           lastSnapshotDay: "2025-10-10",
                                           wellbeingScore: 0.75)
        let url = try DiagnosticsReportBuilder.buildReport(context: context,
                                                           snapshot: snapshot,
                                                           logTail: ["sample log"])
        let contents = try String(contentsOf: url)
        XCTAssertTrue(contents.contains("Pulsum Diagnostics Report"))
        XCTAssertTrue(contents.contains("app_version=1.0.0"))
        XCTAssertTrue(contents.contains("health_granted=2"))
        XCTAssertTrue(contents.contains("last_snapshot_day=2025-10-10"))
        XCTAssertTrue(contents.contains("sample log"))
        let exportsDir = DiagnosticsPaths.exportsDirectory()
        XCTAssertEqual(url.deletingLastPathComponent(), exportsDir)
        let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
#if os(iOS)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let protection = attributes[.protectionKey] as? FileProtectionType
        XCTAssertEqual(protection, .complete)
#endif
    }

    func testForbiddenSubstringNotLeaked() async throws {
        await Diagnostics.clearDiagnostics()
        #if DEBUG
        await DebugLogBuffer.shared._testReset()
        #else
        await DebugLogBuffer.shared.clear()
        #endif
        let unsafe = "USER ENTERED FREE TEXT 1234"
        let compact = unsafe.replacingOccurrences(of: " ", with: "")
        let alphanumericsOnly = unsafe.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map { String($0) }
            .joined()
        Diagnostics.log(level: .info,
                        category: .app,
                        name: "test.forbidden",
                        fields: ["unsafe": .safeString(.metadata(unsafe))])
        try await Task.sleep(nanoseconds: 300_000_000)
        await Diagnostics.flushPersistence()

        let snapshot = await DebugLogBuffer.shared.snapshot()
        XCTAssertTrue(snapshot.contains("<redacted>"))
        XCTAssertFalse(snapshot.lowercased().contains(unsafe.lowercased()))
        XCTAssertFalse(snapshot.lowercased().contains(compact.lowercased()))
        XCTAssertFalse(snapshot.lowercased().contains(alphanumericsOnly.lowercased()))

        let diagnosticsDir = DiagnosticsPaths.logsDirectory()
        if let content = try? String(contentsOf: diagnosticsDir.appendingPathComponent("diagnostics.log")) {
            let haystack = content.lowercased()
            XCTAssertFalse(haystack.contains(unsafe.lowercased()))
            XCTAssertFalse(haystack.contains(compact.lowercased()))
            XCTAssertFalse(haystack.contains(alphanumericsOnly.lowercased()))
        }
    }

    func testPersistedTailOrdersOldestToNewestIgnoringExports() async throws {
        let logsDir = DiagnosticsPaths.logsDirectory()
        try? FileManager.default.removeItem(at: logsDir)
        _ = DiagnosticsPaths.logsDirectory()

        let log2 = logsDir.appendingPathComponent("diagnostics.log.2")
        let log1 = logsDir.appendingPathComponent("diagnostics.log.1")
        let log0 = logsDir.appendingPathComponent("diagnostics.log")
        try "old-1\nold-2\n".write(to: log2, atomically: true, encoding: .utf8)
        try "mid-1\n".write(to: log1, atomically: true, encoding: .utf8)
        try "new-1\nnew-2\n".write(to: log0, atomically: true, encoding: .utf8)

        let unrelated = logsDir.appendingPathComponent("PulsumDiagnostics-Old.txt")
        try "should-be-ignored".write(to: unrelated, atomically: true, encoding: .utf8)

        let tail = await Diagnostics.persistedLogTail(maxLines: 10)
        XCTAssertEqual(tail, ["old-1", "old-2", "mid-1", "new-1", "new-2"])
        XCTAssertFalse(tail.contains("should-be-ignored"))
    }

    func testExportReportOverwritesLatestInExportsDirectory() throws {
        let context = DiagnosticsReportContext(appVersion: "1.0.0",
                                               buildNumber: "100",
                                               deviceModel: "TestDevice",
                                               osVersion: "17.0",
                                               locale: "en_US",
                                               sessionId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                                               diagnosticsEnabled: true,
                                               persistenceEnabled: true,
                                               sessionsIncluded: nil)
        let firstURL = try DiagnosticsReportBuilder.buildReport(context: context,
                                                                snapshot: DiagnosticsSnapshot(),
                                                                logTail: ["first-log-line"])
        let secondURL = try DiagnosticsReportBuilder.buildReport(context: context,
                                                                 snapshot: DiagnosticsSnapshot(),
                                                                 logTail: ["second-log-line"])
        XCTAssertEqual(firstURL, secondURL)
        let exportsDir = DiagnosticsPaths.exportsDirectory()
        XCTAssertEqual(secondURL.deletingLastPathComponent(), exportsDir)
        let contents = try String(contentsOf: secondURL)
        XCTAssertTrue(contents.contains("second-log-line"))
        XCTAssertFalse(contents.contains("first-log-line"))
    }
}
