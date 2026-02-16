import PulsumAgents
import PulsumTypes
import SwiftUI

/// Shared view that renders the correct wellbeing card based on state.
/// Used by both PulsumRootView (main tab) and SettingsScreen.
struct WellbeingStateCardView: View {
    let wellbeingState: WellbeingScoreState
    let snapshotKind: WellbeingSnapshotKind
    let makeDetailViewModel: () -> ScoreBreakdownViewModel?
    let requestHealthAccess: () -> Void
    let retryAction: () -> Void

    var body: some View {
        switch wellbeingState {
        case let .ready(score, _):
            if let detailViewModel = makeDetailViewModel() {
                NavigationLink {
                    ScoreBreakdownScreen(viewModel: detailViewModel)
                } label: {
                    WellbeingScoreCard(score: score)
                }
                .buttonStyle(.plain)
            } else {
                WellbeingScoreCard(score: score)
            }
        case .loading:
            WellbeingScoreLoadingCard()
        case let .noData(reason):
            if snapshotKind == .placeholder, reason == .insufficientSamples {
                WellbeingPlaceholderCard()
            } else {
                WellbeingNoDataCard(reason: reason) {
                    requestHealthAccess()
                }
            }
        case let .error(message):
            WellbeingErrorCard(message: message) {
                retryAction()
            }
        }
    }
}
