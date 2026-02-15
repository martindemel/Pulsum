#if canImport(MetricKit)
import Foundation
import MetricKit
import PulsumTypes

public final class CrashDiagnosticsSubscriber: NSObject, MXMetricManagerSubscriber {
    public static let shared = CrashDiagnosticsSubscriber()

    override private init() {
        super.init()
    }

    public func register() {
        MXMetricManager.shared.add(self)
        Diagnostics.log(level: .info,
                        category: .app,
                        name: "diagnostics.metricKit.registered")
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            if let crashDiagnostics = payload.crashDiagnostics {
                for diagnostic in crashDiagnostics {
                    Diagnostics.log(level: .error,
                                    category: .app,
                                    name: "diagnostics.metricKit.crash",
                                    fields: [
                                        "description": .safeString(.metadata(diagnostic.applicationVersion))
                                    ])
                }
            }
            if let hangDiagnostics = payload.hangDiagnostics {
                for diagnostic in hangDiagnostics {
                    Diagnostics.log(level: .warn,
                                    category: .app,
                                    name: "diagnostics.metricKit.hang",
                                    fields: [
                                        "description": .safeString(.metadata(diagnostic.applicationVersion))
                                    ])
                }
            }
            if let diskWriteDiagnostics = payload.diskWriteExceptionDiagnostics {
                for diagnostic in diskWriteDiagnostics {
                    Diagnostics.log(level: .warn,
                                    category: .app,
                                    name: "diagnostics.metricKit.diskWrite",
                                    fields: [
                                        "description": .safeString(.metadata(diagnostic.applicationVersion))
                                    ])
                }
            }
            if let cpuDiagnostics = payload.cpuExceptionDiagnostics {
                for diagnostic in cpuDiagnostics {
                    Diagnostics.log(level: .warn,
                                    category: .app,
                                    name: "diagnostics.metricKit.cpuException",
                                    fields: [
                                        "description": .safeString(.metadata(diagnostic.applicationVersion))
                                    ])
                }
            }
        }
    }
}

extension CrashDiagnosticsSubscriber: @unchecked Sendable {}
#endif
