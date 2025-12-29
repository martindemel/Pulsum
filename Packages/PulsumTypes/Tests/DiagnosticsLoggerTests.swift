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

        let diagnosticsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Diagnostics")
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
                                               persistenceEnabled: true)
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
        let diagnosticsDir = DiagnosticsLogger.diagnosticsDirectory()
        XCTAssertEqual(url.deletingLastPathComponent(), diagnosticsDir)
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

        let diagnosticsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Diagnostics")
        if let content = try? String(contentsOf: diagnosticsDir.appendingPathComponent("diagnostics.log")) {
            let haystack = content.lowercased()
            XCTAssertFalse(haystack.contains(unsafe.lowercased()))
            XCTAssertFalse(haystack.contains(compact.lowercased()))
            XCTAssertFalse(haystack.contains(alphanumericsOnly.lowercased()))
        }
    }
}
