import Foundation

enum DiagnosticsPaths {
    static func baseDirectory() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let diagnosticsDir = base.appendingPathComponent("Diagnostics", isDirectory: true)
        return ensureDirectory(at: diagnosticsDir)
    }

    static func logsDirectory() -> URL {
        let logsDir = baseDirectory().appendingPathComponent("Logs", isDirectory: true)
        return ensureDirectory(at: logsDir)
    }

    static func exportsDirectory() -> URL {
        let exportsDir = baseDirectory().appendingPathComponent("Exports", isDirectory: true)
        return ensureDirectory(at: exportsDir)
    }

    private static func ensureDirectory(at url: URL) -> URL {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(resourceValues)
        return mutableURL
    }
}
