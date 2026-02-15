import Foundation
import HealthKit
import PulsumServices
import PulsumTypes

// MARK: - HealthKit Observation & Ingestion Management

extension DataAgent {
    func enableBackgroundDelivery(for grantedTypes: Set<HKSampleType>) async throws {
        guard !grantedTypes.isEmpty else {
            await DebugLogBuffer.shared.append("enableBackgroundDelivery skipped: no granted types")
            return
        }
        do {
            try await healthKit.enableBackgroundDelivery(for: grantedTypes)
            await DebugLogBuffer.shared.append("enableBackgroundDelivery enabled for \(grantedTypes.map { $0.identifier })")
        } catch HealthKitServiceError.backgroundDeliveryFailed(let type, let underlying) {
            if shouldIgnoreBackgroundDeliveryError(underlying) {
                await DebugLogBuffer.shared.append("enableBackgroundDelivery ignored missing entitlement for \(type.identifier)")
                Diagnostics.log(level: .warn,
                                category: .healthkit,
                                name: "data.healthkit.backgroundDelivery.missingEntitlement",
                                fields: ["type": .safeString(.metadata(type.identifier))])
            } else {
                throw HealthKitServiceError.backgroundDeliveryFailed(type: type, underlying: underlying)
            }
        } catch {
            throw error
        }
    }

    func startObserversIfNeeded(for types: Set<HKSampleType>) async throws {
        guard !types.isEmpty else {
            await DebugLogBuffer.shared.append("startObserversIfNeeded skipped: no granted types")
            return
        }
        for type in types {
            await DebugLogBuffer.shared.append("Starting observer for \(type.identifier)")
            try await observe(sampleType: type)
        }
    }

    func stopRevokedObservers(keeping granted: Set<HKSampleType>, resetAnchors: Bool) {
        let grantedIdentifiers = Set(granted.map { $0.identifier })
        let identifiers = Array(observers.keys)
        var revoked: [String] = []
        for identifier in identifiers where !grantedIdentifiers.contains(identifier) {
            if let type = sampleTypesByIdentifier[identifier] {
                stopObservation(for: type, resetAnchor: resetAnchors)
                revoked.append(identifier)
            } else {
                observers.removeValue(forKey: identifier)
            }
        }
        if resetAnchors, !revoked.isEmpty {
            for identifier in revoked {
                backfillProgress.removeProgress(for: identifier)
            }
            persistBackfillProgress()
        }
    }

    func readAuthorizationProbeResults(forceRefresh: Bool = false) async -> [String: ReadAuthorizationProbeResult] {
        if !forceRefresh,
           let cached = cachedReadAccess,
           Date().timeIntervalSince(cached.timestamp) < readProbeCacheTTL {
            return cached.results
        }

        let resultsByType = await healthKit.probeReadAuthorization(for: requiredSampleTypes)
        var mapped: [String: ReadAuthorizationProbeResult] = [:]
        for (type, result) in resultsByType {
            mapped[type.identifier] = result
        }
        cachedReadAccess = (timestamp: Date(), results: mapped)
        return mapped
    }

    func invalidateReadAccessCache() {
        cachedReadAccess = nil
    }

    func logHealthStatus(_ status: HealthAccessStatus,
                         requestStatus: HKAuthorizationRequestStatus?,
                         probeResults: [String: ReadAuthorizationProbeResult]) {
        var debugLines: [String] = []
        debugLines.append("Health access status -> granted: \(status.granted.map(\.identifier)), denied: \(status.denied.map(\.identifier)), pending: \(status.notDetermined.map(\.identifier)), availability: \(status.availability)")
        if let requestStatus {
            debugLines.append("HealthKit requestStatusForAuthorization=\(requestStatus.rawValue)")
        }
        if !probeResults.isEmpty {
            debugLines.append(readProbeSummary(probeResults))
            let perType = probeResults
                .map { "\($0.key)=\(probeLabel(for: $0.value))" }
                .sorted()
                .joined(separator: ", ")
            debugLines.append("HealthKit read probe per-type: \(perType)")
        }
        for line in debugLines {
            Task { await DebugLogBuffer.shared.append(line) }
        }
        Diagnostics.log(level: .info,
                        category: .healthkit,
                        name: "data.healthkit.status",
                        fields: [
                            "granted": .int(status.granted.count),
                            "denied": .int(status.denied.count),
                            "pending": .int(status.notDetermined.count),
                            "availability": .safeString(DiagnosticsSafeString.stage(status.availability == .available ? "available" : "unavailable",
                                                                                    allowed: Set(["available", "unavailable"])))
                        ],
                        traceId: diagnosticsTraceId)
    }

    func statusSummary(_ status: HealthAccessStatus) -> String {
        let grantedIds = status.granted.map(\.identifier).sorted().joined(separator: ",")
        let deniedIds = status.denied.map(\.identifier).sorted().joined(separator: ",")
        let pendingIds = status.notDetermined.map(\.identifier).sorted().joined(separator: ",")
        return "granted=[\(grantedIds)] denied=[\(deniedIds)] pending=[\(pendingIds)] availability=\(status.availability)"
    }

    func stopAllObservers(resetAnchors: Bool) {
        let identifiers = Array(observers.keys)
        for identifier in identifiers {
            if let type = sampleTypesByIdentifier[identifier] {
                stopObservation(for: type, resetAnchor: resetAnchors)
            }
        }
        observers.removeAll()
    }

    func stopObservation(for type: HKSampleType, resetAnchor: Bool) {
        observers.removeValue(forKey: type.identifier)
        healthKit.stopObserving(sampleType: type, resetAnchor: resetAnchor)
    }

    func readProbeSummary(_ results: [String: ReadAuthorizationProbeResult]) -> String {
        var authorized = 0
        var denied = 0
        var pending = 0
        var protected = 0
        var errors = 0

        for result in results.values {
            switch result {
            case .authorized:
                authorized += 1
            case .denied:
                denied += 1
            case .notDetermined:
                pending += 1
            case .protectedDataUnavailable, .healthDataUnavailable:
                protected += 1
            case .error:
                errors += 1
            }
        }

        return "HealthKit read probe summary: authorized=\(authorized) denied=\(denied) pending=\(pending) protected=\(protected) error=\(errors)"
    }

    func probeLabel(for result: ReadAuthorizationProbeResult) -> String {
        switch result {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .protectedDataUnavailable:
            return "protectedDataUnavailable"
        case .healthDataUnavailable:
            return "healthDataUnavailable"
        case let .error(domain, code):
            return "error(\(domain):\(code))"
        }
    }

    func shouldIgnoreBackgroundDeliveryError(_ error: Error) -> Bool {
        if let hkError = error as? HKError {
            if hkError.errorCode == HKError.errorInvalidArgument.rawValue {
                return false
            }
        }
        let nsError = error as NSError
        if nsError.domain == HKError.errorDomain,
           nsError.code == HKError.errorInvalidArgument.rawValue {
            return false
        }
        return nsError.localizedDescription.localizedCaseInsensitiveContains("background-delivery")
    }

    func observationTypes(for status: HealthAccessStatus) -> Set<HKSampleType> {
        guard case .available = status.availability else { return [] }
        if lastAuthorizationRequestStatus == .unnecessary {
            return Set(status.required).subtracting(status.denied)
        }
        return status.granted
    }

    func configureObservation(for status: HealthAccessStatus,
                              resetRevokedAnchors: Bool) async throws {
        let observationTypes = observationTypes(for: status)
        await DebugLogBuffer.shared.append("configureObservation availability=\(status.availability) granted=\(status.granted.map { $0.identifier }) observation=\(observationTypes.map { $0.identifier })")
        guard case .available = status.availability else {
            stopAllObservers(resetAnchors: resetRevokedAnchors)
            return
        }

        try await enableBackgroundDelivery(for: observationTypes)
        try await startObserversIfNeeded(for: observationTypes)
        stopRevokedObservers(keeping: observationTypes, resetAnchors: resetRevokedAnchors)
    }
}
