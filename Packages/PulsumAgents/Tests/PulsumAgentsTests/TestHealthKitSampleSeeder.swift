@testable import PulsumServices
import HealthKit

enum TestHealthKitSampleSeeder {
    static func authorizeAllTypes(_ stub: HealthKitServiceStub) {
        for type in HealthKitService.orderedReadSampleTypes {
            stub.authorizationStatuses[type.identifier] = .sharingAuthorized
            stub.readProbeResults[type.identifier] = .authorized
        }
    }

    static func populateSamples(_ stub: HealthKitServiceStub,
                                days: Int,
                                calendar: Calendar = Calendar(identifier: .gregorian)) {
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<days {
            let dayStart = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let sleepStart = calendar.date(byAdding: .hour, value: 22, to: dayStart) ?? dayStart
            let sleepEnd = calendar.date(byAdding: .hour, value: 32, to: dayStart) ?? dayStart.addingTimeInterval(32 * 3600)
            for type in HealthKitService.orderedReadSampleTypes {
                switch type {
                case let quantity as HKQuantityType:
                    appendQuantitySample(type: quantity,
                                         dayStart: dayStart,
                                         sleepStart: sleepStart,
                                         sleepEnd: sleepEnd,
                                         offset: offset,
                                         stub: stub)
                case let category as HKCategoryType:
                    let sleep = HKCategorySample(type: category,
                                                 value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                                                 start: sleepStart,
                                                 end: sleepEnd)
                    append(sample: sleep, to: stub, identifier: category.identifier)
                default:
                    break
                }
            }
        }
    }

    private static func appendQuantitySample(type: HKQuantityType,
                                             dayStart: Date,
                                             sleepStart: Date,
                                             sleepEnd: Date,
                                             offset: Int,
                                             stub: HealthKitServiceStub) {
        let identifier = type.identifier
        switch identifier {
        case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
            let quantity = HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: 50 + Double(offset % 5))
            let sample = HKQuantitySample(type: type, quantity: quantity, start: sleepStart, end: sleepStart.addingTimeInterval(60))
            append(sample: sample, to: stub, identifier: identifier)
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 58 + Double(offset % 3))
            let sample = HKQuantitySample(type: type,
                                          quantity: quantity,
                                          start: sleepStart.addingTimeInterval(3600),
                                          end: sleepStart.addingTimeInterval(3660))
            append(sample: sample, to: stub, identifier: identifier)
        case HKQuantityTypeIdentifier.restingHeartRate.rawValue:
            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 55 + Double(offset % 2))
            let sample = HKQuantitySample(type: type,
                                          quantity: quantity,
                                          start: dayStart.addingTimeInterval(9 * 3600),
                                          end: dayStart.addingTimeInterval(9 * 3600 + 60))
            append(sample: sample, to: stub, identifier: identifier)
        case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 14 + Double(offset % 2))
            let sample = HKQuantitySample(type: type,
                                          quantity: quantity,
                                          start: sleepStart.addingTimeInterval(7200),
                                          end: sleepStart.addingTimeInterval(7260))
            append(sample: sample, to: stub, identifier: identifier)
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: 6000 + Double(offset * 10))
            let sample = HKQuantitySample(type: type,
                                          quantity: quantity,
                                          start: dayStart.addingTimeInterval(12 * 3600),
                                          end: dayStart.addingTimeInterval(13 * 3600))
            append(sample: sample, to: stub, identifier: identifier)
        default:
            break
        }
    }

    private static func append(sample: HKSample, to stub: HealthKitServiceStub, identifier: String) {
        var existing = stub.fetchedSamples[identifier] ?? []
        existing.append(sample)
        stub.fetchedSamples[identifier] = existing
    }
}
