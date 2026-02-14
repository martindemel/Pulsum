import SwiftUI
import PulsumAgents

struct ScoreBreakdownScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScoreBreakdownViewModel

    init(viewModel: ScoreBreakdownViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulsumBackgroundBeige.ignoresSafeArea()

                if viewModel.isLoading && viewModel.breakdown == nil {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: PulsumSpacing.lg) {
                            if let breakdown = viewModel.breakdown {
                                SummaryCard(breakdown: breakdown)

                                if let highlights = viewModel.recommendationHighlights {
                                    RecommendationLogicCard(highlights: highlights)
                                }

                                if !viewModel.objectiveMetrics.isEmpty {
                                    MetricSection(title: "Objective signals",
                                                  caption: "Physiological measures compared against your rolling baseline.",
                                                  metrics: viewModel.objectiveMetrics)
                                }

                                if !viewModel.subjectiveMetrics.isEmpty {
                                    MetricSection(title: "Subjective check-in",
                                                  caption: "Sliders you provided during today's pulse.",
                                                  metrics: viewModel.subjectiveMetrics)
                                }

                                if !viewModel.sentimentMetrics.isEmpty {
                                    MetricSection(title: "Journal + sentiment",
                                                  caption: "On-device analysis of your latest journal entry.",
                                                  metrics: viewModel.sentimentMetrics)
                                }

                                if !breakdown.generalNotes.isEmpty {
                                    NotesCard(notes: breakdown.generalNotes)
                                }
                            } else if let message = viewModel.errorMessage {
                                ErrorStateView(message: message)
                            } else {
                                EmptyStateView()
                            }
                        }
                        .padding(.horizontal, PulsumSpacing.lg)
                        .padding(.bottom, PulsumSpacing.xxl)
                    }
                }
            }
            .navigationTitle("Score details")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.pulsumTextSecondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
            #if os(iOS)
                .toolbarBackground(.automatic, for: .navigationBar)
            #endif
                .task {
                    await viewModel.refresh()
                }
        }
    }
}

private struct SummaryCard: View {
    let breakdown: ScoreBreakdown

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var dateString: String {
        Self.dateFormatter.string(from: breakdown.date)
    }

    private var topPositiveDriver: ScoreBreakdown.MetricDetail? {
        breakdown.metrics.max(by: { $0.contribution < $1.contribution })
    }

    private var topNegativeDriver: ScoreBreakdown.MetricDetail? {
        breakdown.metrics.min(by: { $0.contribution < $1.contribution })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.lg) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                Text("Today's wellbeing score")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(dateString)
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            VStack(spacing: PulsumSpacing.xs) {
                Text(breakdown.wellbeingScore.formatted(.number.precision(.fractionLength(2))))
                    .font(.pulsumDataXLarge)
                    .foregroundStyle(scoreColor(breakdown.wellbeingScore))
                Text(summaryCopy(for: breakdown.wellbeingScore))
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                Text("Top drivers")
                    .font(.pulsumSubheadline)
                    .foregroundStyle(Color.pulsumTextSecondary)
                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                    if let positive = topPositiveDriver, positive.contribution > 0 {
                        DriverRow(prefix: "Lift", metric: positive, color: Color.pulsumGreenSoft)
                    }
                    if let negative = topNegativeDriver, negative.contribution < 0 {
                        DriverRow(prefix: "Drag", metric: negative, color: Color.pulsumWarning)
                    }
                }
            }

            Text("The score is a weighted blend of physiological z-scores, subjective sliders, and journal sentiment. Each contribution shown below is the weight × today's normalized value.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .pulsumCardStyle()
    }

    private func scoreColor(_ value: Double) -> Color {
        switch value {
        case ..<(-1): return Color.pulsumWarning
        case -1 ..< 0.5: return Color.pulsumTextSecondary
        case 0.5 ..< 1.5: return Color.pulsumGreenSoft
        default: return Color.pulsumSuccess
        }
    }

    private func summaryCopy(for value: Double) -> String {
        switch value {
        case ..<(-1): return "Focus on rest and low-load actions."
        case -1 ..< 0.5: return "Holding steady around baseline."
        case 0.5 ..< 1.5: return "Positive momentum building."
        default: return "Strong recovery signal today."
        }
    }
}

private struct DriverRow: View {
    let prefix: String
    let metric: ScoreBreakdown.MetricDetail
    let color: Color

    var body: some View {
        HStack(spacing: PulsumSpacing.xs) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)
            Text("\(prefix): \(metric.name) \(formatContribution(metric.contribution))")
                .font(.pulsumCaption)
                .foregroundStyle(color)
        }
    }
}

private struct MetricSection: View {
    let title: String
    let caption: String
    let metrics: [ScoreBreakdown.MetricDetail]

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text(title)
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(caption)
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            LazyVStack(spacing: PulsumSpacing.md) {
                ForEach(metrics) { metric in
                    MetricCard(detail: metric)
                }
            }
        }
    }
}

private struct MetricCard: View {
    let detail: ScoreBreakdown.MetricDetail

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                    Text(detail.name)
                        .font(.pulsumHeadline)
                        .foregroundStyle(Color.pulsumTextPrimary)
                    if let valueLine {
                        Text(valueLine)
                            .font(.pulsumCallout)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    } else {
                        Text("No data today")
                            .font(.pulsumCallout)
                            .foregroundStyle(Color.pulsumTextTertiary)
                    }
                }
                Spacer()
                ContributionBadge(contribution: detail.contribution)
            }

            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                if let zScoreLine {
                    InfoRow(systemName: "chart.line.uptrend.xyaxis", text: zScoreLine)
                }
                if let coverageLine {
                    InfoRow(systemName: "stethoscope", text: coverageLine)
                }
                if let baselineLine {
                    InfoRow(systemName: "calendar", text: baselineLine)
                }
                if let ewmaLine {
                    InfoRow(systemName: "waveform.path.ecg", text: ewmaLine)
                }
            }

            if !detail.notes.isEmpty {
                ForEach(detail.notes, id: \.self) { note in
                    NoteRow(text: note)
                }
            }

            Text(detail.explanation)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .pulsumCardStyle(padding: PulsumSpacing.lg)
    }

    private var valueLine: String? {
        guard let value = detail.value else { return nil }
        return formatValue(value, unit: detail.unit)
    }

    private var zScoreLine: String? {
        guard let zScore = detail.zScore else { return nil }
        let formatted = formatSigned(value: zScore, decimals: 2)
        return "Z-score vs baseline: \(formatted)"
    }

    private var coverageLine: String? {
        guard let coverage = detail.coverage else { return nil }
        let daysLabel = coverage.daysWithSamples == 1 ? "day" : "days"
        let sampleLabel = coverage.sampleCount == 1 ? "data point" : "data points"
        return "Health data: \(coverage.daysWithSamples) \(daysLabel), \(coverage.sampleCount) \(sampleLabel)"
    }

    private var baselineLine: String? {
        guard let median = detail.baselineMedian else { return nil }
        let prefix: String
        if let days = detail.rollingWindowDays {
            prefix = "Rolling baseline (\(days)d median):"
        } else {
            prefix = "Rolling baseline median:"
        }
        let value = formatValue(median, unit: detail.unit) ?? String(format: "%.2f", median)
        return "\(prefix) \(value)"
    }

    private var ewmaLine: String? {
        guard let ewma = detail.baselineEwma else { return nil }
        let value = formatValue(ewma, unit: detail.unit) ?? String(format: "%.2f", ewma)
        return "EWMA trend (λ=0.2): \(value)"
    }
}

private struct NotesCard: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
            Text("Data notes")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)
            ForEach(notes, id: \.self) { note in
                NoteRow(text: note)
            }
        }
        .pulsumCardStyle()
    }
}

private struct RecommendationLogicCard: View {
    let highlights: RecommendationHighlights

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("How recommendations use this")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            Text("The Coach agent builds a retrieval query from the wellbeing score plus the strongest signals below, then ranks activities with the RecRanker model.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)

            if !highlights.lifts.isEmpty {
                BulletList(title: "Signals lifting you", details: highlights.lifts, color: Color.pulsumGreenSoft)
            }

            if !highlights.drags.isEmpty {
                BulletList(title: "Signals needing support", details: highlights.drags, color: Color.pulsumWarning)
            }

            Text("Cards are prioritized when they address the most urgent drags while reinforcing the current lifts. Updating your pulse inputs or new HealthKit data will reshuffle this analysis on the next sync.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .pulsumCardStyle()
    }
}

private struct BulletList: View {
    let title: String
    let details: [ScoreBreakdown.MetricDetail]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
            Text(title)
                .font(.pulsumSubheadline)
                .foregroundStyle(color)
            ForEach(details) { detail in
                HStack(alignment: .top, spacing: PulsumSpacing.xs) {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                        Text(detail.name)
                            .font(.pulsumCallout)
                            .foregroundStyle(Color.pulsumTextPrimary)
                        Text(contributionLine(for: detail))
                            .font(.pulsumCaption)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    }
                }
            }
        }
    }

    private func contributionLine(for detail: ScoreBreakdown.MetricDetail) -> String {
        let contribution = formatContribution(detail.contribution)
        if let explanation = detail.explanation.split(separator: "\n").first {
            return "\(contribution) – \(explanation)"
        }
        return contribution
    }
}

private struct ContributionBadge: View {
    let contribution: Double

    var body: some View {
        Text(formatContribution(contribution))
            .font(.pulsumCaption)
            .fontWeight(.semibold)
            .padding(.vertical, PulsumSpacing.xxs)
            .padding(.horizontal, PulsumSpacing.sm)
            .background(badgeBackground)
            .foregroundStyle(badgeForeground)
            .clipShape(Capsule())
    }

    private var badgeBackground: Color {
        if contribution > 0.05 {
            return Color.pulsumGreenSoft.opacity(0.15)
        } else if contribution < -0.05 {
            return Color.pulsumWarning.opacity(0.15)
        } else {
            return Color.pulsumBlueSoft.opacity(0.1)
        }
    }

    private var badgeForeground: Color {
        if contribution > 0.05 {
            return Color.pulsumGreenSoft
        } else if contribution < -0.05 {
            return Color.pulsumWarning
        } else {
            return Color.pulsumTextSecondary
        }
    }
}

private struct InfoRow: View {
    let systemName: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: PulsumSpacing.xs) {
            Image(systemName: systemName)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumBlueSoft)
            Text(text)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
        }
    }
}

private struct NoteRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: PulsumSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumWarning)
            Text(text)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumWarning)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: PulsumSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.pulsumTitle2)
                .foregroundStyle(Color.pulsumWarning)
            Text("Unable to load score details")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)
            Text(message)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulsumSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, PulsumSpacing.xl)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: PulsumSpacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.pulsumTitle2)
                .foregroundStyle(Color.pulsumBlueSoft)
            Text("No metrics yet")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)
            Text("We will show a full breakdown after Pulsum completes the first nightly sync.")
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulsumSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, PulsumSpacing.xl)
    }
}

// MARK: - Formatting Helpers

private func formatValue(_ value: Double, unit: String?) -> String? {
    guard let unit else { return formatSigned(value: value, decimals: 2) }
    switch unit {
    case "ms":
        return String(format: "%.0f ms", value)
    case "bpm":
        return String(format: "%.1f bpm", value)
    case "breaths/min":
        return String(format: "%.1f breaths/min", value)
    case "steps":
        return "\(Int(round(value))) steps"
    case "h":
        return String(format: "%.1f h", value)
    case "(1-7)":
        return String(format: "%.1f / 7", value)
    default:
        return formatSigned(value: value, decimals: 2)
    }
}

private let signedFormatter2: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
}()

private func formatSigned(value: Double, decimals: Int) -> String {
    let formatted: String
    if decimals == 2 {
        formatted = signedFormatter2.string(from: NSNumber(value: abs(value))) ?? String(format: "%.*f", decimals, abs(value))
    } else {
        formatted = String(format: "%.*f", decimals, abs(value))
    }
    return value >= 0 ? "+\(formatted)" : "-\(formatted)"
}

private func formatContribution(_ contribution: Double) -> String {
    formatSigned(value: contribution, decimals: 2)
}
