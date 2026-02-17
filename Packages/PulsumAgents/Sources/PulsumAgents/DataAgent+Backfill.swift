import Foundation
import HealthKit
import SwiftData
import PulsumData
import PulsumML
import PulsumServices
import PulsumTypes

// MARK: - Bootstrap & Backfill

extension DataAgent {
    func scheduleBootstrapWatchdog(for status: HealthAccessStatus) {
        bootstrapWatchdogTask?.cancel()
        guard case .available = status.availability else { return }
        let deadlineSeconds = bootstrapPolicy.placeholderDeadlineSeconds
        let traceId = diagnosticsTraceId
        bootstrapWatchdogTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(max(0, deadlineSeconds) * 1_000_000_000))
            } catch {
                return
            }
            guard let self else { return }
            do {
                if let _ = try await self.latestFeatureVector() {
                    return
                }
            } catch {
                return
            }
            let created = await self.ensurePlaceholderSnapshot(for: Date(),
                                                               reason: .stage("bootstrap",
                                                                              allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]),
                                                               trigger: "watchdog")
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.bootstrap.watchdog.triggered",
                            fields: [
                                "deadline_seconds": .double(deadlineSeconds),
                                "placeholder_created": .bool(created)
                            ],
                            traceId: traceId)
        }
    }

    func backfillHistoricalSamplesIfNeeded(for status: HealthAccessStatus) async {
        guard case .available = status.availability else {
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.skip",
                           fields: [
                               "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                               "reason": .safeString(.stage("health_unavailable", allowed: ["health_unavailable", "no_granted"]))
                           ])
            return
        }
        let observationTypes = observationTypes(for: status)
        guard !observationTypes.isEmpty else {
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.skip",
                           fields: [
                               "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                               "reason": .safeString(.stage("no_granted", allowed: ["health_unavailable", "no_granted"]))
                           ])
            return
        }

        let today = calendar.startOfDay(for: Date())
        let warmStartStart = calendar.date(byAdding: .day, value: -(warmStartWindowDays - 1), to: today) ?? today
        let fullWindowStart = calendar.date(byAdding: .day, value: -(fullAnalysisWindowDays - 1), to: today) ?? today

        let warmStartTypes = observationTypes.filter { !backfillProgress.warmStartCompletedTypes.contains($0.identifier) }
        if warmStartTypes.isEmpty {
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.skip",
                           fields: [
                               "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                               "reason": .safeString(.stage("already_complete", allowed: ["health_unavailable", "no_granted", "already_complete"]))
                           ])
        } else {
            let phaseSpan = Diagnostics.span(category: .backfill,
                                             name: "data.backfill.phase",
                                             fields: [
                                                 "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                                                 "start_day": .day(warmStartStart),
                                                 "end_day": .day(today),
                                                 "target_start_day": .day(fullWindowStart)
                                             ],
                                             traceId: diagnosticsTraceId,
                                             level: .info)
            let monitor = DiagnosticsStallMonitor(category: .backfill,
                                                  name: "data.backfill.warmStart",
                                                  traceId: diagnosticsTraceId,
                                                  thresholdSeconds: 25,
                                                  initialFields: [
                                                      "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                                                      "type_count": .int(warmStartTypes.count)
                                                  ])
            await monitor.start()
            let result = await performBackfill(for: warmStartTypes.sorted { $0.identifier < $1.identifier },
                                               startDate: warmStartStart,
                                               endDate: today,
                                               phase: "warm-start",
                                               targetStartDate: fullWindowStart,
                                               markWarmStart: true,
                                               monitor: monitor)
            await monitor.stop(finalFields: [
                "touched_days": .int(result.days.count),
                "raw_sample_count": .int(result.totalSamples)
            ])
            phaseSpan.end(additionalFields: [
                "touched_days": .int(result.days.count),
                "raw_sample_count": .int(result.totalSamples)
            ], error: nil)
            notifySnapshotUpdate(for: today,
                                 reason: .stage("warm_backfill",
                                                allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
        }

        scheduleBackgroundFullBackfillIfNeeded(grantedTypes: observationTypes, targetStartDate: fullWindowStart)
    }

    func bootstrapFirstScore(for status: HealthAccessStatus) async {
        guard case .available = status.availability else {
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.bootstrap.end",
                            fields: [
                                "reason": .safeString(.stage("health_unavailable", allowed: ["health_unavailable", "no_granted"])),
                                "has_snapshot": .bool(false),
                                "no_feature_vector": .bool(true)
                            ],
                            traceId: diagnosticsTraceId)
            return
        }
        guard !status.granted.isEmpty else {
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.bootstrap.end",
                            fields: [
                                "reason": .safeString(.stage("no_granted", allowed: ["health_unavailable", "no_granted"])),
                                "has_snapshot": .bool(false),
                                "no_feature_vector": .bool(true)
                            ],
                            traceId: diagnosticsTraceId)
            return
        }
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(bootstrapWindowDays - 1), to: today) else { return }
        let types = status.granted.sorted { $0.identifier < $1.identifier }
        let bootstrapSpan = Diagnostics.span(category: .dataAgent,
                                             name: "data.bootstrap",
                                             fields: [
                                                 "window_days": .int(bootstrapWindowDays),
                                                 "start_day": .day(start),
                                                 "end_day": .day(today)
                                             ],
                                             traceId: diagnosticsTraceId)
        let fetchTimeoutSeconds = bootstrapPolicy.bootstrapTimeoutSeconds
        let heartRateTimeoutSeconds = bootstrapPolicy.heartRateTimeoutSeconds
        var touchedDays = Set<Date>()
        var totalSamples = 0
        var outcomes: [String: BootstrapBatchResult] = [:]
        var retryIdentifiers: Set<String> = []
        var snapshotDay: Date?
        var placeholderPublished = false
        var endError: Error?
        var allFailed = false

        defer {
            let successCount = outcomes.values.filter { $0 == .success }.count
            let emptyCount = outcomes.values.filter { $0 == .empty }.count
            let timeoutCount = outcomes.values.filter { $0 == .timeout }.count
            let errorCount = outcomes.values.filter { $0 == .error }.count
            let cancelledCount = outcomes.values.filter { $0 == .cancelled }.count
            var fields: [String: DiagnosticsValue] = [
                "touched_days": .int(touchedDays.count),
                "raw_sample_count": .int(totalSamples),
                "type_success_count": .int(successCount),
                "type_empty_count": .int(emptyCount),
                "type_timeout_count": .int(timeoutCount),
                "type_error_count": .int(errorCount),
                "type_cancelled_count": .int(cancelledCount),
                "all_failed": .bool(allFailed),
                "placeholder_published": .bool(placeholderPublished),
                "has_snapshot": .bool(snapshotDay != nil),
                "no_feature_vector": .bool(snapshotDay == nil)
            ]
            if let snapshotDay {
                fields["snapshot_day"] = .day(snapshotDay)
            }
            bootstrapSpan.end(additionalFields: fields, error: endError)
            Diagnostics.log(level: endError == nil ? .info : .error,
                            category: .dataAgent,
                            name: "data.bootstrap.end",
                            fields: fields,
                            traceId: diagnosticsTraceId,
                            error: endError)
        }

        for type in types {
            let fetchResult = await fetchAndProcessBootstrapType(type,
                                                                 startDate: start,
                                                                 endDate: today,
                                                                 fetchTimeoutSeconds: fetchTimeoutSeconds,
                                                                 heartRateTimeoutSeconds: heartRateTimeoutSeconds,
                                                                 contextPrefix: "Bootstrap",
                                                                 batchSpanName: "data.bootstrap.batch")
            outcomes[type.identifier] = fetchResult.outcome
            touchedDays.formUnion(fetchResult.touchedDays)
            totalSamples += fetchResult.sampleCount
            if fetchResult.outcome == .timeout || fetchResult.outcome == .error {
                retryIdentifiers.insert(type.identifier)
            }
        }
        notifySnapshotUpdate(for: today,
                             reason: .stage("bootstrap",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))

        do {
            if let snapshot = try await latestRealFeatureVector() {
                snapshotDay = snapshot.date
                return
            }
        } catch {
            endError = error
        }

        allFailed = !outcomes.isEmpty && outcomes.values.allSatisfy { $0 == .timeout || $0 == .error }
        if allFailed {
            placeholderPublished = await ensurePlaceholderSnapshot(for: today,
                                                                   reason: .stage("bootstrap",
                                                                                  allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]),
                                                                   trigger: "bootstrap_failures")
        }

        if !retryIdentifiers.isEmpty {
            scheduleBootstrapRetry(for: retryIdentifiers,
                                   startDate: start,
                                   endDate: today,
                                   trigger: "bootstrap_failures")
        }

        let fallbackEnd = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let fallbackStart = calendar.date(byAdding: .day, value: -(fullAnalysisWindowDays - 1), to: today) ?? today
        let fallbackSucceeded = await bootstrapFromFallbackWindow(status: status,
                                                                  fallbackStartDate: fallbackStart,
                                                                  fallbackEndDate: fallbackEnd)
        if !fallbackSucceeded {
            notifySnapshotUpdate(for: today,
                                 reason: .stage("bootstrap",
                                                allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
        }

        do {
            if let snapshot = try await latestRealFeatureVector() {
                snapshotDay = snapshot.date
                return
            }
        } catch {
            endError = error
        }

        if snapshotDay == nil && !placeholderPublished {
            placeholderPublished = await ensurePlaceholderSnapshot(for: today,
                                                                   reason: .stage("bootstrap",
                                                                                  allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]),
                                                                   trigger: "bootstrap_complete")
        }
    }

    func scheduleBackfill(for status: HealthAccessStatus) {
        guard case .available = status.availability else { return }
        warmStartBackfillTask?.cancel()
        warmStartBackfillTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.backfillHistoricalSamplesIfNeeded(for: status)
        }
    }

    func scheduleBootstrapRetry(for identifiers: Set<String>,
                                startDate: Date,
                                endDate: Date,
                                trigger: String) {
        guard !identifiers.isEmpty else { return }
        pendingBootstrapRetryIdentifiers.formUnion(identifiers)

        let now = Date()
        if bootstrapRetryStart == nil {
            bootstrapRetryStart = now
        }
        if let retryStart = bootstrapRetryStart,
           now.timeIntervalSince(retryStart) > bootstrapPolicy.retryMaxElapsedSeconds {
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.bootstrap.retry.skipped",
                            fields: [
                                "reason": .safeString(.stage("max_elapsed", allowed: ["max_elapsed", "max_attempts"])),
                                "attempt": .int(bootstrapRetryAttempt)
                            ],
                            traceId: diagnosticsTraceId)
            return
        }

        let nextAttempt = bootstrapRetryAttempt + 1
        guard nextAttempt <= bootstrapPolicy.retryMaxAttempts else {
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.bootstrap.retry.skipped",
                            fields: [
                                "reason": .safeString(.stage("max_attempts", allowed: ["max_elapsed", "max_attempts"])),
                                "attempt": .int(bootstrapRetryAttempt)
                            ],
                            traceId: diagnosticsTraceId)
            return
        }

        guard bootstrapRetryTask == nil else { return }
        bootstrapRetryAttempt = nextAttempt
        let attempt = nextAttempt
        let delaySeconds = bootstrapPolicy.retryDelaySeconds * pow(2.0, Double(attempt - 1))
        let timeoutSeconds = bootstrapPolicy.retryTimeoutSeconds + Double(attempt - 1) * 2
        let traceId = diagnosticsTraceId

        Diagnostics.log(level: .info,
                        category: .dataAgent,
                        name: "data.bootstrap.retry.scheduled",
                        fields: [
                            "attempt": .int(attempt),
                            "type_count": .int(identifiers.count),
                            "delay_seconds": .double(delaySeconds),
                            "timeout_seconds": .double(timeoutSeconds),
                            "window_start_day": .day(startDate),
                            "window_end_day": .day(endDate),
                            "trigger": .safeString(.stage(trigger,
                                                          allowed: ["bootstrap_timeout", "bootstrap_failures", "retry_timeout", "unknown"]))
                        ],
                        traceId: traceId)

        bootstrapRetryTask = Task.detached(priority: .background) { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(max(0, delaySeconds) * 1_000_000_000))
            } catch {
                return
            }
            await self?.performBootstrapRetry(attempt: attempt,
                                              timeoutSeconds: timeoutSeconds,
                                              startDate: startDate,
                                              endDate: endDate)
        }
    }

    func performBootstrapRetry(attempt: Int,
                               timeoutSeconds: Double,
                               startDate: Date,
                               endDate: Date) async {
        let identifiers = pendingBootstrapRetryIdentifiers
        pendingBootstrapRetryIdentifiers.removeAll()
        let types = identifiers.compactMap { sampleTypesByIdentifier[$0] }.sorted { $0.identifier < $1.identifier }
        guard !types.isEmpty else {
            bootstrapRetryTask = nil
            return
        }

        let span = Diagnostics.span(category: .dataAgent,
                                    name: "data.bootstrap.retry",
                                    fields: [
                                        "attempt": .int(attempt),
                                        "type_count": .int(types.count),
                                        "window_start_day": .day(startDate),
                                        "window_end_day": .day(endDate),
                                        "timeout_seconds": .double(timeoutSeconds)
                                    ],
                                    traceId: diagnosticsTraceId,
                                    level: .info)

        var touchedDays = Set<Date>()
        var totalSamples = 0
        var outcomes: [String: BootstrapBatchResult] = [:]
        var timedOutIdentifiers: Set<String> = []

        for type in types {
            let fetchResult = await fetchAndProcessBootstrapType(type,
                                                                 startDate: startDate,
                                                                 endDate: endDate,
                                                                 fetchTimeoutSeconds: timeoutSeconds,
                                                                 heartRateTimeoutSeconds: timeoutSeconds,
                                                                 contextPrefix: "Bootstrap retry",
                                                                 batchSpanName: "data.bootstrap.retry.batch",
                                                                 extraBatchSpanFields: ["attempt": .int(attempt)])
            outcomes[type.identifier] = fetchResult.outcome
            touchedDays.formUnion(fetchResult.touchedDays)
            totalSamples += fetchResult.sampleCount
            if fetchResult.outcome == .timeout {
                timedOutIdentifiers.insert(type.identifier)
            }
        }

        if let latestDay = touchedDays.max() {
            notifySnapshotUpdate(for: latestDay,
                                 reason: .stage("bootstrap",
                                                allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
        }

        let hasSnapshot: Bool
        do {
            hasSnapshot = try (await latestRealFeatureVector()) != nil
        } catch {
            hasSnapshot = false
        }

        let successCount = outcomes.values.filter { $0 == .success }.count
        let emptyCount = outcomes.values.filter { $0 == .empty }.count
        let timeoutCount = outcomes.values.filter { $0 == .timeout }.count
        let errorCount = outcomes.values.filter { $0 == .error }.count
        let cancelledCount = outcomes.values.filter { $0 == .cancelled }.count
        let fields: [String: DiagnosticsValue] = [
            "attempt": .int(attempt),
            "touched_days": .int(touchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "type_success_count": .int(successCount),
            "type_empty_count": .int(emptyCount),
            "type_timeout_count": .int(timeoutCount),
            "type_error_count": .int(errorCount),
            "type_cancelled_count": .int(cancelledCount),
            "has_snapshot": .bool(hasSnapshot)
        ]
        span.end(additionalFields: fields, error: nil)
        Diagnostics.log(level: .info,
                        category: .dataAgent,
                        name: "data.bootstrap.retry.end",
                        fields: fields,
                        traceId: diagnosticsTraceId)

        if hasSnapshot {
            bootstrapRetryAttempt = 0
            bootstrapRetryStart = nil
        }

        bootstrapRetryTask = nil

        if !timedOutIdentifiers.isEmpty {
            scheduleBootstrapRetry(for: timedOutIdentifiers,
                                   startDate: startDate,
                                   endDate: endDate,
                                   trigger: "retry_timeout")
        }
    }

    @discardableResult
    func ensurePlaceholderSnapshot(for date: Date,
                                   reason: DiagnosticsSafeString,
                                   trigger: String) async -> Bool {
        do {
            if let _ = try await latestRealFeatureVector() {
                return false
            }
        } catch {
            return false
        }

        let day = calendar.startOfDay(for: date)
        do {
            let targetDate = day
            var descriptor = FetchDescriptor<FeatureVector>(predicate: #Predicate { $0.date == targetDate })
            descriptor.fetchLimit = 1
            if let existing = try modelContext.fetch(descriptor).first {
                let bundle = BaselineCalculator.materializeFeatures(from: existing)
                if SnapshotPlaceholder.isPlaceholder(bundle.imputed) {
                    return false
                }
                return false
            }
            let vector = FeatureVector(date: day)
            modelContext.insert(vector)
            var zeroFeatures: [String: Double] = [:]
            for key in FeatureBundle.requiredKeys {
                zeroFeatures[key] = 0
            }
            baselineCalc.apply(features: zeroFeatures, to: vector)
            let imputed: [String: Bool] = [SnapshotPlaceholder.imputedFlagKey: true]
            vector.imputedFlags = BaselineCalculator.encodeFeatureMetadata(imputed: imputed,
                                                                           contributions: [:],
                                                                           wellbeing: 0)
            try modelContext.save()
            notifySnapshotUpdate(for: day, reason: reason)
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.snapshot.placeholder",
                            fields: [
                                "trigger": .safeString(.stage(trigger,
                                                              allowed: ["watchdog", "bootstrap_failures", "bootstrap_complete", "bootstrap_timeout", "unknown"])),
                                "snapshot_day": .day(day)
                            ],
                            traceId: diagnosticsTraceId)
            return true
        } catch {
            Diagnostics.log(level: .error,
                            category: .dataAgent,
                            name: "data.snapshot.placeholder.failed",
                            fields: [
                                "trigger": .safeString(.stage(trigger,
                                                              allowed: ["watchdog", "bootstrap_failures", "bootstrap_complete", "bootstrap_timeout", "unknown"])),
                                "snapshot_day": .day(day)
                            ],
                            traceId: diagnosticsTraceId,
                            error: error)
            return false
        }
    }

    func bootstrapFromFallbackWindow(status: HealthAccessStatus,
                                     fallbackStartDate: Date,
                                     fallbackEndDate: Date) async -> Bool {
        guard case .available = status.availability else { return false }
        guard !status.granted.isEmpty else { return false }

        let span = Diagnostics.span(category: .dataAgent,
                                    name: "data.bootstrap.fallback",
                                    fields: [
                                        "start_day": .day(fallbackStartDate),
                                        "end_day": .day(fallbackEndDate)
                                    ],
                                    traceId: diagnosticsTraceId,
                                    level: .info)
        var touchedDays: Set<Date> = []
        var totalSamples = 0
        let fetchTimeoutSeconds = bootstrapPolicy.bootstrapTimeoutSeconds
        let heartRateTimeoutSeconds = bootstrapPolicy.heartRateTimeoutSeconds
        let types = status.granted.sorted { $0.identifier < $1.identifier }

        for type in types {
            let fetchResult = await fetchAndProcessBootstrapType(type,
                                                                 startDate: fallbackStartDate,
                                                                 endDate: fallbackEndDate,
                                                                 fetchTimeoutSeconds: fetchTimeoutSeconds,
                                                                 heartRateTimeoutSeconds: heartRateTimeoutSeconds,
                                                                 contextPrefix: "Bootstrap fallback",
                                                                 batchSpanName: "data.bootstrap.fallback.batch")
            touchedDays.formUnion(fetchResult.touchedDays)
            totalSamples += fetchResult.sampleCount
            if fetchResult.hadUnrecoverableError {
                span.end(additionalFields: [
                    "touched_days": .int(touchedDays.count),
                    "raw_sample_count": .int(totalSamples)
                ], error: fetchResult.unrecoverableError)
                return false
            }
        }

        guard let latestDay = touchedDays.max() else {
            span.end(additionalFields: [
                "touched_days": .int(touchedDays.count),
                "raw_sample_count": .int(totalSamples)
            ], error: nil)
            return false
        }
        notifySnapshotUpdate(for: latestDay,
                             reason: .stage("bootstrap",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
        span.end(additionalFields: [
            "touched_days": .int(touchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "snapshot_day": .day(latestDay)
        ], error: nil)
        return true
    }

    func processBackfillSamples(_ samples: [HKSample], type: HKSampleType) async throws -> (processedSamples: Int, days: Set<Date>) {
        switch type {
        case let quantityType as HKQuantityType:
            let quantitySamples = samples.compactMap { $0 as? HKQuantitySample }
            guard !quantitySamples.isEmpty else {
                logDiagnostics(level: .info,
                               category: .backfill,
                               name: "data.backfill.skip",
                               fields: [
                                   "type": .safeString(.metadata(quantityType.identifier)),
                                   "reason": .safeString(.stage("no_castable_samples", allowed: ["no_castable_samples"]))
                               ])
                return (0, [])
            }
            // Group by day to avoid huge single calls and to log progress.
            let grouped = Dictionary(grouping: quantitySamples) { calendar.startOfDay(for: $0.startDate) }
            var touched: Set<Date> = []
            var processedCount = 0
            for (_, daySamples) in grouped {
                let days = try await processQuantitySamples(daySamples, type: quantityType)
                touched.formUnion(days)
                processedCount += daySamples.count
            }
            return (processedCount, touched)

        case let categoryType as HKCategoryType:
            let categorySamples = samples.compactMap { $0 as? HKCategorySample }
            guard !categorySamples.isEmpty else {
                logDiagnostics(level: .info,
                               category: .backfill,
                               name: "data.backfill.skip",
                               fields: [
                                   "type": .safeString(.metadata(categoryType.identifier)),
                                   "reason": .safeString(.stage("no_castable_samples", allowed: ["no_castable_samples"]))
                               ])
                return (0, [])
            }
            let grouped = Dictionary(grouping: categorySamples) { calendar.startOfDay(for: $0.startDate) }
            var touched: Set<Date> = []
            var processedCount = 0
            for (_, daySamples) in grouped {
                let days = try await processCategorySamples(daySamples, type: categoryType)
                touched.formUnion(days)
                processedCount += daySamples.count
            }
            return (processedCount, touched)

        default:
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.skip",
                           fields: [
                               "type": .safeString(.metadata(type.identifier)),
                               "reason": .safeString(.stage("unsupported_type", allowed: ["unsupported_type"]))
                           ])
            return (0, [])
        }
    }

    func performBackfill(for types: [HKSampleType],
                         startDate: Date,
                         endDate: Date,
                         phase: String,
                         targetStartDate: Date,
                         markWarmStart: Bool,
                         monitor: DiagnosticsStallMonitor? = nil) async -> (days: Set<Date>, totalSamples: Int) {
        guard !types.isEmpty else { return ([], 0) }
        let sorted = types.sorted { $0.identifier < $1.identifier }
        let backfillTimeoutSeconds = bootstrapPolicy.backfillTimeoutSeconds
        var touchedDays: Set<Date> = []
        var totalSamples = 0
        var processedTypeCount = 0
        for type in sorted {
            let fetchResult = await fetchAndProcessBootstrapType(
                type,
                startDate: startDate,
                endDate: endDate,
                fetchTimeoutSeconds: backfillTimeoutSeconds,
                heartRateTimeoutSeconds: backfillTimeoutSeconds,
                contextPrefix: "Backfill (\(phase))",
                batchSpanName: "data.backfill.batch",
                extraBatchSpanFields: [
                    "phase": .safeString(.stage(phase, allowed: ["warm-start", "full"])),
                    "target_start_day": .day(targetStartDate),
                    "mark_warm_start": .bool(markWarmStart)
                ])

            touchedDays.formUnion(fetchResult.touchedDays)
            totalSamples += fetchResult.sampleCount

            // Record progress unless there was an error or cancellation.
            // The safe* fetch wrappers convert protected-data errors into empty results
            // (not thrown errors), so .empty here means "no data" — not a fetch failure.
            if fetchResult.outcome != .error && fetchResult.outcome != .cancelled {
                if markWarmStart {
                    backfillProgress.recordWarmStart(for: type.identifier, earliestDate: startDate, calendar: calendar)
                } else {
                    backfillProgress.recordProcessedRange(for: type.identifier,
                                                          startDate: startDate,
                                                          targetStartDate: targetStartDate,
                                                          calendar: calendar)
                }
                persistBackfillProgress()
            }

            await monitor?.heartbeat(progressFields: [
                "phase": .safeString(.stage(phase, allowed: ["warm-start", "full"])),
                "processed_types": .int(processedTypeCount + 1)
            ])
            processedTypeCount += 1
        }
        return (touchedDays, totalSamples)
    }

    func scheduleBackgroundFullBackfillIfNeeded(grantedTypes: Set<HKSampleType>, targetStartDate: Date) {
        guard needsFullBackfill(for: grantedTypes, targetStartDate: targetStartDate) else {
            Task { await DebugLogBuffer.shared.append("Background backfill skipped: full window already covered") }
            return
        }
        if let task = fullBackfillTask, !task.isCancelled {
            return
        }
        fullBackfillTask = Task { [weak self] in
            await self?.performBackgroundFullBackfill(grantedTypes: grantedTypes, targetStartDate: targetStartDate)
        }
    }

    func needsFullBackfill(for grantedTypes: Set<HKSampleType>, targetStartDate: Date) -> Bool {
        for type in grantedTypes {
            let identifier = type.identifier
            if backfillProgress.fullBackfillCompletedTypes.contains(identifier) {
                continue
            }
            guard let earliest = backfillProgress.earliestProcessedDate(for: identifier, calendar: calendar) else {
                return true
            }
            if earliest > targetStartDate {
                return true
            }
        }
        return false
    }

    func performBackgroundFullBackfill(grantedTypes: Set<HKSampleType>, targetStartDate: Date) async {
        let phaseSpan = Diagnostics.span(category: .backfill,
                                         name: "data.backfill.phase",
                                         fields: [
                                             "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                                             "target_start_day": .day(targetStartDate)
                                         ],
                                         traceId: diagnosticsTraceId,
                                         level: .info)
        let monitor = DiagnosticsStallMonitor(category: .backfill,
                                              name: "data.backfill.full",
                                              traceId: diagnosticsTraceId,
                                              thresholdSeconds: 90,
                                              initialFields: [
                                                  "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                                                  "granted_types": .int(grantedTypes.count)
                                              ])
        await monitor.start()
        defer { fullBackfillTask = nil }

        var iteration = 0
        var batchTouchedDays: Set<Date> = []
        var batchSampleCount = 0
        var batchTypes: [String] = []
        var totalTouchedDays: Set<Date> = []
        var totalSamples = 0
        let today = calendar.startOfDay(for: Date())

        while !Task.isCancelled {
            var madeProgress = false
            let sorted = grantedTypes.sorted { $0.identifier < $1.identifier }

            for type in sorted {
                let identifier = type.identifier
                if backfillProgress.fullBackfillCompletedTypes.contains(identifier) {
                    continue
                }

                let currentEarliest = backfillProgress.earliestProcessedDate(for: identifier, calendar: calendar) ?? calendar.startOfDay(for: Date())
                if currentEarliest <= targetStartDate {
                    backfillProgress.markFullBackfillComplete(for: identifier)
                    persistBackfillProgress()
                    continue
                }

                let batchEnd = calendar.date(byAdding: .day, value: -1, to: currentEarliest) ?? targetStartDate
                var batchStart = calendar.date(byAdding: .day, value: -(backgroundBackfillBatchDays - 1), to: batchEnd) ?? targetStartDate
                if batchStart < targetStartDate { batchStart = targetStartDate }

                let touched = await performBackfill(for: [type],
                                                    startDate: batchStart,
                                                    endDate: batchEnd,
                                                    phase: "full",
                                                    targetStartDate: targetStartDate,
                                                    markWarmStart: false,
                                                    monitor: monitor)
                batchTypes.append(identifier)
                batchSampleCount += touched.totalSamples
                totalSamples += touched.totalSamples
                batchTouchedDays.formUnion(touched.days)
                totalTouchedDays.formUnion(touched.days)
                madeProgress = true
            }

            if !needsFullBackfill(for: grantedTypes, targetStartDate: targetStartDate) {
                break
            }
            if !madeProgress {
                logDiagnostics(level: .warn,
                               category: .backfill,
                               name: "data.backfill.phase.pause",
                               fields: [
                                   "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                                   "reason": .safeString(.stage("no_progress", allowed: ["no_progress"]))
                               ])
                break
            }
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.iteration",
                           fields: [
                               "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                               "iteration": .int(iteration),
                               "window_start_day": batchTouchedDays.min().map { .day($0) } ?? .day(today),
                               "window_end_day": batchTouchedDays.max().map { .day($0) } ?? .day(today),
                               "types_processed": .int(batchTypes.count),
                               "touched_days": .int(batchTouchedDays.count),
                               "raw_sample_count": .int(batchSampleCount)
                           ])
            if !batchTouchedDays.isEmpty {
                notifySnapshotUpdate(for: today,
                                     reason: .stage("full_backfill",
                                                    allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
            }
            batchTouchedDays.removeAll()
            batchSampleCount = 0
            batchTypes.removeAll()
            iteration += 1
            if iteration > 64 { break }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }

        await monitor.stop(finalFields: [
            "touched_days": .int(totalTouchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "iterations": .int(iteration)
        ])

        phaseSpan.end(additionalFields: [
            "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
            "touched_days": .int(totalTouchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "iterations": .int(iteration)
        ], error: nil)
    }

    // MARK: - Shared Bootstrap Type Processing

    struct BootstrapTypeResult {
        let outcome: BootstrapBatchResult
        let touchedDays: Set<Date>
        let sampleCount: Int
        let hadUnrecoverableError: Bool
        let unrecoverableError: Error?

        init(outcome: BootstrapBatchResult,
             touchedDays: Set<Date> = [],
             sampleCount: Int = 0,
             hadUnrecoverableError: Bool = false,
             unrecoverableError: Error? = nil) {
            self.outcome = outcome
            self.touchedDays = touchedDays
            self.sampleCount = sampleCount
            self.hadUnrecoverableError = hadUnrecoverableError
            self.unrecoverableError = unrecoverableError
        }
    }

    /// Fetches and processes samples for a single HK type during bootstrap/retry/fallback.
    /// Handles the three-way switch on type (stepCount, heartRate, default),
    /// creates and ends the batch diagnostics span, and returns the result.
    func fetchAndProcessBootstrapType(
        _ type: HKSampleType,
        startDate: Date,
        endDate: Date,
        fetchTimeoutSeconds: Double,
        heartRateTimeoutSeconds: Double,
        contextPrefix: String,
        batchSpanName: String,
        extraBatchSpanFields: [String: DiagnosticsValue] = [:]
    ) async -> BootstrapTypeResult {
        let identifier = type.identifier
        var spanFields: [String: DiagnosticsValue] = [
            "type": .safeString(.metadata(identifier)),
            "batch_start_day": .day(startDate),
            "batch_end_day": .day(endDate)
        ]
        spanFields.merge(extraBatchSpanFields) { _, new in new }
        let batchSpan = Diagnostics.span(category: .dataAgent,
                                         name: batchSpanName,
                                         fields: spanFields,
                                         traceId: diagnosticsTraceId,
                                         level: .info)
        let context = "\(contextPrefix) \(identifier)"

        do {
            switch identifier {
            case HKQuantityTypeIdentifier.stepCount.rawValue:
                let totalsResult: HardTimeoutResult<[Date: Int]>
                do {
                    totalsResult = try await withHardTimeout(seconds: fetchTimeoutSeconds) {
                        try await self.safeFetchDailyStepTotals(startDate: startDate,
                                                                endDate: endDate,
                                                                context: context)
                    }
                } catch {
                    let isProtected = isProtectedHealthDataInaccessible(error)
                    endBootstrapBatch(batchSpan,
                                      result: isProtected ? .empty : .error,
                                      skipReason: .stage(isProtected ? "protected_data" : "fetch_failed",
                                                         allowed: ["protected_data", "fetch_failed"]),
                                      error: isProtected ? nil : error)
                    return BootstrapTypeResult(outcome: isProtected ? .empty : .error)
                }
                switch totalsResult {
                case .timedOut:
                    endBootstrapBatch(batchSpan, result: .timeout, rawCount: 0, processedDays: 0,
                                      timeoutMs: Int(fetchTimeoutSeconds * 1_000))
                    return BootstrapTypeResult(outcome: .timeout)
                case .value(let totals):
                    let days = try await applyStepTotals(totals)
                    let result: BootstrapBatchResult = totals.isEmpty ? .empty : .success
                    endBootstrapBatch(batchSpan, result: result, rawCount: totals.count,
                                      processedDays: days.count)
                    return BootstrapTypeResult(outcome: result, touchedDays: days,
                                               sampleCount: totals.count)
                }

            case HKQuantityTypeIdentifier.heartRate.rawValue:
                let hrResult = await fetchHeartRateStatsWithTimeout(
                    startDate: startDate, endDate: endDate,
                    context: context, timeoutSeconds: heartRateTimeoutSeconds)
                switch hrResult.result {
                case .success:
                    do {
                        let days = try await applyNocturnalStats(hrResult.stats)
                        endBootstrapBatch(batchSpan, result: .success,
                                          rawCount: hrResult.stats.count,
                                          processedDays: days.count)
                        return BootstrapTypeResult(outcome: .success, touchedDays: days,
                                                   sampleCount: hrResult.stats.count)
                    } catch {
                        endBootstrapBatch(batchSpan, result: .error,
                                          rawCount: hrResult.stats.count,
                                          processedDays: hrResult.stats.count,
                                          error: error)
                        return BootstrapTypeResult(outcome: .error)
                    }
                case .empty:
                    endBootstrapBatch(batchSpan, result: .empty, rawCount: 0, processedDays: 0)
                    return BootstrapTypeResult(outcome: .empty)
                case .timeout:
                    endBootstrapBatch(batchSpan, result: .timeout, rawCount: 0, processedDays: 0,
                                      timeoutMs: Int(heartRateTimeoutSeconds * 1_000))
                    return BootstrapTypeResult(outcome: .timeout)
                case .error:
                    endBootstrapBatch(batchSpan, result: .error, rawCount: 0, processedDays: 0,
                                      error: hrResult.error)
                    return BootstrapTypeResult(outcome: .error)
                case .cancelled:
                    endBootstrapBatch(batchSpan, result: .cancelled, rawCount: 0, processedDays: 0)
                    return BootstrapTypeResult(outcome: .cancelled)
                }

            default:
                let samplesResult: HardTimeoutResult<[HKSample]>
                do {
                    samplesResult = try await withHardTimeout(seconds: fetchTimeoutSeconds) {
                        try await self.healthKit.fetchSamples(for: type, startDate: startDate,
                                                              endDate: endDate)
                    }
                } catch {
                    let isProtected = isProtectedHealthDataInaccessible(error)
                    endBootstrapBatch(batchSpan,
                                      result: isProtected ? .empty : .error,
                                      skipReason: .stage(isProtected ? "protected_data" : "fetch_failed",
                                                         allowed: ["protected_data", "fetch_failed"]),
                                      error: isProtected ? nil : error)
                    if isProtected {
                        return BootstrapTypeResult(outcome: .empty)
                    }
                    return BootstrapTypeResult(outcome: .error, hadUnrecoverableError: true,
                                               unrecoverableError: error)
                }
                switch samplesResult {
                case .timedOut:
                    endBootstrapBatch(batchSpan, result: .timeout, rawCount: 0, processedDays: 0,
                                      timeoutMs: Int(fetchTimeoutSeconds * 1_000))
                    return BootstrapTypeResult(outcome: .timeout)
                case .value(let samples):
                    let processed = try await processBackfillSamples(samples, type: type)
                    let result: BootstrapBatchResult = samples.isEmpty ? .empty : .success
                    endBootstrapBatch(batchSpan, result: result, rawCount: samples.count,
                                      processedCount: processed.processedSamples,
                                      processedDays: processed.days.count)
                    return BootstrapTypeResult(outcome: result, touchedDays: processed.days,
                                               sampleCount: processed.processedSamples)
                }
            }
        } catch {
            let isProtected = isProtectedHealthDataInaccessible(error)
            endBootstrapBatch(batchSpan,
                              result: isProtected ? .empty : .error,
                              skipReason: .stage(isProtected ? "protected_data" : "fetch_failed",
                                                 allowed: ["protected_data", "fetch_failed"]),
                              error: isProtected ? nil : error)
            if isProtected {
                return BootstrapTypeResult(outcome: .empty)
            }
            return BootstrapTypeResult(outcome: .error, hadUnrecoverableError: true,
                                       unrecoverableError: error)
        }
    }

    // MARK: - Backfill Helpers

    func safeFetchDailyStepTotals(startDate: Date, endDate: Date, context: String) async throws -> [Date: Int] {
        do {
            return try await healthKit.fetchDailyStepTotals(startDate: startDate, endDate: endDate)
        } catch {
            if isProtectedHealthDataInaccessible(error) {
                await DebugLogBuffer.shared.append("\(context): protected data inaccessible (device likely locked); returning empty step totals.")
                return [:]
            }
            throw error
        }
    }

    func safeFetchNocturnalHeartRateStats(startDate: Date, endDate: Date, context: String) async throws -> [Date: (avgBPM: Double, minBPM: Double?)] {
        do {
            return try await healthKit.fetchNocturnalHeartRateStats(startDate: startDate, endDate: endDate)
        } catch {
            if let hkError = error as? HKError, hkError.code == .errorNoData {
                await DebugLogBuffer.shared.append("\(context): no heart-rate data available; returning empty stats.")
                return [:]
            }
            let nsError = error as NSError
            if nsError.domain == HKError.errorDomain,
               nsError.code == HKError.Code.errorNoData.rawValue {
                await DebugLogBuffer.shared.append("\(context): no heart-rate data available; returning empty stats.")
                return [:]
            }
            if isProtectedHealthDataInaccessible(error) {
                await DebugLogBuffer.shared.append("\(context): protected data inaccessible (device likely locked); returning empty nocturnal HR stats.")
                return [:]
            }
            throw error
        }
    }

    func fetchHeartRateStatsWithTimeout(startDate: Date,
                                        endDate: Date,
                                        context: String,
                                        timeoutSeconds: Double) async -> (result: BootstrapBatchResult, stats: [Date: (avgBPM: Double, minBPM: Double?)], error: Error?) {
        do {
            let timed = try await withHardTimeout(seconds: timeoutSeconds) {
                try await self.safeFetchNocturnalHeartRateStats(startDate: startDate,
                                                                endDate: endDate,
                                                                context: context)
            }
            switch timed {
            case .timedOut:
                await DebugLogBuffer.shared.append("\(context): heart-rate fetch timed out after \(timeoutSeconds)s; treating as empty.")
                return (.timeout, [:], nil)
            case .value(let stats):
                if stats.isEmpty {
                    return (.empty, [:], nil)
                }
                return (.success, stats, nil)
            }
        } catch {
            return (.error, [:], error)
        }
    }

    func endBootstrapBatch(_ span: DiagnosticsSpanToken,
                           result: BootstrapBatchResult,
                           rawCount: Int = 0,
                           processedCount: Int? = nil,
                           processedDays: Int? = nil,
                           timeoutMs: Int? = nil,
                           skipReason: DiagnosticsSafeString? = nil,
                           error: Error? = nil) {
        var fields: [String: DiagnosticsValue] = [
            "result": .safeString(.stage(result.rawValue,
                                         allowed: ["success", "empty", "timeout", "error", "cancelled"])),
            "raw_sample_count": .int(rawCount)
        ]
        if let processedCount {
            fields["processed_sample_count"] = .int(processedCount)
        }
        if let processedDays {
            fields["processed_days"] = .int(processedDays)
        }
        if let timeoutMs {
            fields["timeout_ms"] = .int(timeoutMs)
        }
        if let skipReason {
            fields["skip_reason"] = .safeString(skipReason)
        }

        span.end(additionalFields: fields, error: error)
    }

    func isProtectedHealthDataInaccessible(_ error: Error) -> Bool {
        if let hkError = error as? HKError {
            return hkError.code == .errorDatabaseInaccessible || hkError.code == .errorHealthDataUnavailable
        }
        let nsError = error as NSError
        if nsError.domain == HKError.errorDomain {
            return nsError.code == HKError.errorDatabaseInaccessible.rawValue
        }
        return nsError.localizedDescription.localizedCaseInsensitiveContains("Protected health data is inaccessible")
    }
}
