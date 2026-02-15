import Foundation

struct DailySummary {
    let date: Date
    let hrv: Double?
    let nocturnalHR: Double?
    let restingHR: Double?
    let totalSleepSeconds: Double?
    let sleepNeedHours: Double
    let sleepDebtHours: Double?
    let respiratoryRate: Double?
    let stepCount: Double?
    let updatedFlags: DailyFlags
    let imputed: [String: Bool]
}
