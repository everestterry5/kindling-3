import SwiftUI
import Combine

enum KindlingRoute: Hashable {
    case logIdea
    case report(UUID)
    case validation(UUID)
    case businessPlan(UUID)
    case pitchDeck(UUID)
    case ai(UUID)
    case portfolio
    case founderBrief
    case whatChanged
    case flowOverview
}

final class KindlingRouter: ObservableObject {
    @Published var path: [KindlingRoute] = []

    func push(_ route: KindlingRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func showReportAfterCreating(_ id: UUID) {
        path = [.report(id)]
    }

    func showMainJourney(for id: UUID) {
        path = [
            .report(id),
            .validation(id),
            .businessPlan(id)
        ]
    }
}
