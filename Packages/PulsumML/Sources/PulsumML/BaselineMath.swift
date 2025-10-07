import Foundation

public enum BaselineMath {
    public struct RobustStats {
        public let median: Double
        public let mad: Double

        public init(median: Double, mad: Double) {
            self.median = median
            self.mad = mad
        }
    }

    public static func robustStats(for values: [Double]) -> RobustStats? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let median = percentile(sorted, percentile: 0.5)
        let deviations = sorted.map { abs($0 - median) }
        let mad = percentile(deviations.sorted(), percentile: 0.5) * 1.4826
        return RobustStats(median: median, mad: max(mad, 1e-6))
    }

    public static func zScore(value: Double, stats: RobustStats) -> Double {
        (value - stats.median) / stats.mad
    }

    public static func ewma(previous: Double?, newValue: Double, lambda: Double = 0.2) -> Double {
        guard let previous else { return newValue }
        return lambda * newValue + (1 - lambda) * previous
    }

    private static func percentile(_ values: [Double], percentile: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let index = Double(values.count - 1) * percentile
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        if lower == upper { return values[lower] }
        let weight = index - Double(lower)
        return values[lower] * (1 - weight) + values[upper] * weight
    }
}
