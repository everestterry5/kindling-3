import SwiftUI
import Combine

final class KindlingStore: ObservableObject {
    @Published var ideas: [BusinessIdea]

    init(ideas: [BusinessIdea] = BusinessIdea.demoIdeas) {
        self.ideas = ideas
    }

    var topIdea: BusinessIdea? {
        ideas.max(by: { $0.viabilityScore < $1.viabilityScore })
    }

    var bestFitIdea: BusinessIdea? {
        ideas.max(by: { $0.founderFit < $1.founderFit })
    }

    func idea(withID id: UUID) -> BusinessIdea? {
        ideas.first(where: { $0.id == id })
    }

    @discardableResult
    func addIdea(_ idea: BusinessIdea) -> BusinessIdea {
        ideas.insert(idea, at: 0)
        return idea
    }

    func update(_ idea: BusinessIdea) {
        guard let index = ideas.firstIndex(where: { $0.id == idea.id }) else {
            return
        }

        var updated = idea
        updated.updatedAt = Date()
        ideas[index] = updated
    }

    func updateLifecycle(
        id: UUID,
        lifecycle: IdeaLifecycle
    ) {
        guard let index = ideas.firstIndex(where: { $0.id == id }) else {
            return
        }

        ideas[index].lifecycle = lifecycle
        ideas[index].updatedAt = Date()
    }

    func updateDecision(
        id: UUID,
        decision: IdeaDecision
    ) {
        guard let index = ideas.firstIndex(where: { $0.id == id }) else {
            return
        }

        ideas[index].decision = decision
        ideas[index].updatedAt = Date()
    }

    func advanceLifecycle(id: UUID) {
        guard
            let idea = idea(withID: id),
            let next = idea.lifecycle.next
        else {
            return
        }

        updateLifecycle(id: id, lifecycle: next)
    }

    func retreatLifecycle(id: UUID) {
        guard
            let idea = idea(withID: id),
            let previous = idea.lifecycle.previous
        else {
            return
        }

        updateLifecycle(id: id, lifecycle: previous)
    }

    func pauseIdea(id: UUID) {
        updateDecision(id: id, decision: .pause)
    }

    func resumeIdea(id: UUID) {
        guard let idea = idea(withID: id) else {
            return
        }

        let resumedDecision: IdeaDecision

        switch idea.lifecycle {
        case .captured:
            resumedDecision = .explore
        case .analyzed, .validating:
            resumedDecision = .validate
        case .planning, .building, .launched:
            resumedDecision = .pursue
        }

        updateDecision(id: id, decision: resumedDecision)
    }
}
