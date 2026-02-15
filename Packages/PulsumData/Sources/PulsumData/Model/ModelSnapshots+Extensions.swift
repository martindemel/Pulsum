import Foundation
import PulsumTypes

// MARK: - Snapshot Extensions

public extension DailyMetrics {
    var snapshot: DailyMetricsSnapshot {
        DailyMetricsSnapshot(
            date: date,
            hrvMedian: hrvMedian,
            nocturnalHRPercentile10: nocturnalHRPercentile10,
            restingHR: restingHR,
            totalSleepTime: totalSleepTime,
            sleepDebt: sleepDebt,
            respiratoryRate: respiratoryRate,
            steps: steps,
            flags: flags
        )
    }
}

public extension JournalEntry {
    var snapshot: JournalEntrySnapshot {
        JournalEntrySnapshot(
            id: id,
            date: date,
            transcript: transcript,
            sentiment: sentiment
        )
    }
}

public extension Baseline {
    var snapshot: BaselineSnapshot {
        BaselineSnapshot(
            metric: metric,
            windowDays: windowDays,
            median: median,
            mad: mad,
            ewma: ewma,
            updatedAt: updatedAt
        )
    }
}

public extension FeatureVector {
    var snapshot: FeatureVectorSnapshot {
        FeatureVectorSnapshot(
            date: date,
            zHrv: zHrv,
            zNocturnalHR: zNocturnalHR,
            zRestingHR: zRestingHR,
            zSleepDebt: zSleepDebt,
            zRespiratoryRate: zRespiratoryRate,
            zSteps: zSteps,
            subjectiveStress: subjectiveStress,
            subjectiveEnergy: subjectiveEnergy,
            subjectiveSleepQuality: subjectiveSleepQuality,
            sentiment: sentiment,
            imputedFlags: imputedFlags
        )
    }
}

public extension MicroMoment {
    var snapshot: MicroMomentSnapshot {
        MicroMomentSnapshot(
            id: id,
            title: title,
            shortDescription: shortDescription,
            detail: detail,
            tags: tags,
            estimatedTimeSec: estimatedTimeSec,
            difficulty: difficulty,
            category: category,
            sourceURL: sourceURL,
            evidenceBadge: evidenceBadge,
            cooldownSec: cooldownSec
        )
    }
}

public extension RecommendationEvent {
    var snapshot: RecommendationEventSnapshot {
        RecommendationEventSnapshot(
            momentId: momentId,
            date: date,
            accepted: accepted,
            completedAt: completedAt
        )
    }
}
