import XCTest
import PulsumTypes
@testable import PulsumData

final class LibraryImporterDiagnosticsTests: XCTestCase {
    private var previousConfig: DiagnosticsConfig?

    override func setUp() async throws {
        previousConfig = Diagnostics.currentConfig()
        await Diagnostics.clearDiagnostics()
        #if DEBUG
        await DebugLogBuffer.shared._testReset()
        #else
        await DebugLogBuffer.shared.clear()
        #endif
        var config = Diagnostics.currentConfig()
        config.enabled = true
        config.persistToDisk = false
        config.mirrorToOSLog = false
        config.enableSignposts = false
        Diagnostics.updateConfig(config)
    }

    override func tearDown() async throws {
        if let previousConfig {
            Diagnostics.updateConfig(previousConfig)
        }
        await Diagnostics.clearDiagnostics()
        #if DEBUG
        await DebugLogBuffer.shared._testReset()
        #else
        await DebugLogBuffer.shared.clear()
        #endif
        previousConfig = nil
        try await super.tearDown()
    }

    func testLibraryImportSpanEmitsSingleBeginOnFirstRun() async throws {
        let configuration = LibraryImporterConfiguration(bundle: .module,
                                                         subdirectory: "PulsumDataTests/Resources")
        let indexStub = DiagnosticsIndexStub()
        let importer = LibraryImporter(configuration: configuration, vectorIndex: indexStub)

        try await importer.ingestIfNeeded()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(1))
        var lines: [String] = []
        var beginIndices: [Int] = []
        var endIndices: [Int] = []
        while clock.now < deadline {
            lines = await DebugLogBuffer.shared.tail(maxLines: 500)
            beginIndices = lines.indices.filter { lines[$0].contains("library.import.begin") }
            endIndices = lines.indices.filter { lines[$0].contains("library.import.end") }
            if beginIndices.count == 1 && endIndices.count == 1 {
                break
            }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
        if beginIndices.count != 1 || endIndices.count != 1 {
            XCTFail("""
Expected one begin/end span. begin=\(beginIndices.count) end=\(endIndices.count)
Log tail:
\(lines.joined(separator: "\n"))
""")
        }

        XCTAssertEqual(beginIndices.count, 1, "Expected a single library.import.begin span on first run.")
        XCTAssertEqual(endIndices.count, 1, "Expected a single library.import.end span on first run.")
        if let beginIndex = beginIndices.first, let endIndex = endIndices.first {
            XCTAssertLessThan(beginIndex, endIndex, "library.import.begin should precede library.import.end.")
        }
    }
}

final actor DiagnosticsIndexStub: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        _ = (id, title, detail, tags)
        return Array(repeating: 0.1, count: 384)
    }

    func removeMicroMoment(id: String) async throws {
        _ = id
    }

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        _ = (query, topK)
        return []
    }
}
