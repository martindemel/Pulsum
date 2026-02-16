import Foundation

// MARK: - DailyMetricsSnapshot

public struct DailyMetricsSnapshot: Sendable, Codable {
    public let date: Date
    public let hrvMedian: Double?
    public let nocturnalHRPercentile10: Double?
    public let restingHR: Double?
    public let totalSleepTime: Double?
    public let sleepDebt: Double?
    public let respiratoryRate: Double?
    public let steps: Double?
    public let flags: String?

    public init(
        date: Date,
        hrvMedian: Double? = nil,
        nocturnalHRPercentile10: Double? = nil,
        restingHR: Double? = nil,
        totalSleepTime: Double? = nil,
        sleepDebt: Double? = nil,
        respiratoryRate: Double? = nil,
        steps: Double? = nil,
        flags: String? = nil
    ) {
        self.date = date
        self.hrvMedian = hrvMedian
        self.nocturnalHRPercentile10 = nocturnalHRPercentile10
        self.restingHR = restingHR
        self.totalSleepTime = totalSleepTime
        self.sleepDebt = sleepDebt
        self.respiratoryRate = respiratoryRate
        self.steps = steps
        self.flags = flags
    }
}

// MARK: - WellbeingScoreSnapshot

public struct WellbeingScoreSnapshot: Sendable, Codable {
    public let date: Date
    public let score: Double
    public let label: String
    public let contributing: [String: Double]

    public init(
        date: Date,
        score: Double,
        label: String,
        contributing: [String: Double]
    ) {
        self.date = date
        self.score = score
        self.label = label
        self.contributing = contributing
    }
}

// MARK: - JournalEntrySnapshot

public struct JournalEntrySnapshot: Sendable, Codable {
    public let id: UUID
    public let date: Date
    public let transcript: String
    public let sentiment: Double

    public init(
        id: UUID,
        date: Date,
        transcript: String,
        sentiment: Double
    ) {
        self.id = id
        self.date = date
        self.transcript = transcript
        self.sentiment = sentiment
    }
}

// MARK: - BaselineSnapshot

public struct BaselineSnapshot: Sendable, Codable {
    public let metric: String
    public let windowDays: Int16
    public let median: Double?
    public let mad: Double?
    public let ewma: Double?
    public let updatedAt: Date?

    public init(
        metric: String,
        windowDays: Int16,
        median: Double? = nil,
        mad: Double? = nil,
        ewma: Double? = nil,
        updatedAt: Date? = nil
    ) {
        self.metric = metric
        self.windowDays = windowDays
        self.median = median
        self.mad = mad
        self.ewma = ewma
        self.updatedAt = updatedAt
    }
}

// MARK: - FeatureVectorSnapshot

public struct FeatureVectorSnapshot: Sendable, Codable {
    public let date: Date
    public let zHrv: Double?
    public let zNocturnalHR: Double?
    public let zRestingHR: Double?
    public let zSleepDebt: Double?
    public let zRespiratoryRate: Double?
    public let zSteps: Double?
    public let subjectiveStress: Double?
    public let subjectiveEnergy: Double?
    public let subjectiveSleepQuality: Double?
    public let sentiment: Double?
    public let imputedFlags: String?

    public init(
        date: Date,
        zHrv: Double? = nil,
        zNocturnalHR: Double? = nil,
        zRestingHR: Double? = nil,
        zSleepDebt: Double? = nil,
        zRespiratoryRate: Double? = nil,
        zSteps: Double? = nil,
        subjectiveStress: Double? = nil,
        subjectiveEnergy: Double? = nil,
        subjectiveSleepQuality: Double? = nil,
        sentiment: Double? = nil,
        imputedFlags: String? = nil
    ) {
        self.date = date
        self.zHrv = zHrv
        self.zNocturnalHR = zNocturnalHR
        self.zRestingHR = zRestingHR
        self.zSleepDebt = zSleepDebt
        self.zRespiratoryRate = zRespiratoryRate
        self.zSteps = zSteps
        self.subjectiveStress = subjectiveStress
        self.subjectiveEnergy = subjectiveEnergy
        self.subjectiveSleepQuality = subjectiveSleepQuality
        self.sentiment = sentiment
        self.imputedFlags = imputedFlags
    }
}

// MARK: - MicroMomentSnapshot

public struct MicroMomentSnapshot: Sendable, Codable {
    public let id: String
    public let title: String
    public let shortDescription: String
    public let detail: String?
    public let tags: String?
    public let estimatedTimeSec: Int32?
    public let difficulty: String?
    public let category: String?
    public let sourceURL: String?
    public let evidenceBadge: String?
    public let cooldownSec: Int32?

    public init(
        id: String,
        title: String,
        shortDescription: String,
        detail: String? = nil,
        tags: String? = nil,
        estimatedTimeSec: Int32? = nil,
        difficulty: String? = nil,
        category: String? = nil,
        sourceURL: String? = nil,
        evidenceBadge: String? = nil,
        cooldownSec: Int32? = nil
    ) {
        self.id = id
        self.title = title
        self.shortDescription = shortDescription
        self.detail = detail
        self.tags = tags
        self.estimatedTimeSec = estimatedTimeSec
        self.difficulty = difficulty
        self.category = category
        self.sourceURL = sourceURL
        self.evidenceBadge = evidenceBadge
        self.cooldownSec = cooldownSec
    }
}

// MARK: - UserPrefsSnapshot

public struct UserPrefsSnapshot: Sendable, Codable {
    public let id: String
    public let consentCloud: Bool
    public let updatedAt: Date

    public init(
        id: String,
        consentCloud: Bool,
        updatedAt: Date
    ) {
        self.id = id
        self.consentCloud = consentCloud
        self.updatedAt = updatedAt
    }
}

// MARK: - ConsentStateSnapshot

public struct ConsentStateSnapshot: Sendable, Codable {
    public let id: UUID
    public let version: String
    public let grantedAt: Date?
    public let revokedAt: Date?

    public init(
        id: UUID,
        version: String,
        grantedAt: Date? = nil,
        revokedAt: Date? = nil
    ) {
        self.id = id
        self.version = version
        self.grantedAt = grantedAt
        self.revokedAt = revokedAt
    }
}

// MARK: - RecommendationEventSnapshot

public struct RecommendationEventSnapshot: Sendable, Codable {
    public let momentId: String
    public let date: Date
    public let accepted: Bool
    public let completedAt: Date?

    public init(
        momentId: String,
        date: Date,
        accepted: Bool,
        completedAt: Date? = nil
    ) {
        self.momentId = momentId
        self.date = date
        self.accepted = accepted
        self.completedAt = completedAt
    }
}
