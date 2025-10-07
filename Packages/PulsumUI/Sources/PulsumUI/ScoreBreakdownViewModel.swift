import Foundation
import Observation
import PulsumAgents

@MainActor
@Observable
final class ScoreBreakdownViewModel {
    @ObservationIgnored private let orchestrator: AgentOrchestrator

    var breakdown: ScoreBreakdown?
    var isLoading = false
    var errorMessage: String?

    init(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
    }

    var recommendationHighlights: RecommendationHighlights? {
        guard let details = breakdown?.metrics else { return nil }
        let lifts = details
            .filter { $0.contribution > 0 }
            .sorted(by: { $0.contribution > $1.contribution })
            .prefix(3)
        let drags = details
            .filter { $0.contribution < 0 }
            .sorted(by: { abs($0.contribution) > abs($1.contribution) })
            .prefix(3)
        guard !lifts.isEmpty || !drags.isEmpty else { return nil }
        return RecommendationHighlights(lifts: Array(lifts), drags: Array(drags))
    }

    var objectiveMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .objective } ?? []
    }

    var subjectiveMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .subjective } ?? []
    }

    var sentimentMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .sentiment } ?? []
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            breakdown = try await orchestrator.scoreBreakdown()
            errorMessage = nil
        } catch {
            breakdown = nil
            errorMessage = mapError(error)
        }
    }

    private func mapError(_ error: Error) -> String {
        if (error as NSError).domain == NSURLErrorDomain {
            return "Network connection appears offline."
        }
        return error.localizedDescription
    }
}

struct RecommendationHighlights {
    let lifts: [ScoreBreakdown.MetricDetail]
    let drags: [ScoreBreakdown.MetricDetail]
}
