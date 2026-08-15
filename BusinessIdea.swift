import SwiftUI

enum IdeaLifecycle: String, CaseIterable, Codable, Hashable {
    case captured = "Captured"
    case analyzed = "Analyzed"
    case validating = "Validating"
    case planning = "Planning"
    case building = "Building"
    case launched = "Launched"
}

enum IdeaDecision: String, Codable, Hashable {
    case explore = "Explore"
    case validate = "Validate"
    case pursue = "Pursue"
    case watch = "Watch"
    case pause = "Pause"
}

enum IdeaAccent: String, Codable, Hashable, CaseIterable {
    case coral
    case blue
    case orange
    case green
    case pink
}

struct BusinessIdea: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var summary: String
    var customer: String
    var problem: String
    var businessModel: String
    var category: String

    var viabilityScore: Int
    var founderFit: Int
    var entryDifficulty: Int
    var competitorCount: Int
    var marketDirection: String

    var lifecycle: IdeaLifecycle
    var validationProgress: Int
    var businessPlanProgress: Int
    var decision: IdeaDecision
    var accent: IdeaAccent

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        customer: String = "",
        problem: String = "",
        businessModel: String = "",
        category: String = "Not sure yet",
        viabilityScore: Int = 68,
        founderFit: Int = 72,
        entryDifficulty: Int = 50,
        competitorCount: Int = 0,
        marketDirection: String = "→",
        lifecycle: IdeaLifecycle = .captured,
        validationProgress: Int = 0,
        businessPlanProgress: Int = 0,
        decision: IdeaDecision = .explore,
        accent: IdeaAccent = .orange,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.customer = customer
        self.problem = problem
        self.businessModel = businessModel
        self.category = category
        self.viabilityScore = viabilityScore
        self.founderFit = founderFit
        self.entryDifficulty = entryDifficulty
        self.competitorCount = competitorCount
        self.marketDirection = marketDirection
        self.lifecycle = lifecycle
        self.validationProgress = validationProgress
        self.businessPlanProgress = businessPlanProgress
        self.decision = decision
        self.accent = accent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension BusinessIdea {
    static let demoIdeas: [BusinessIdea] = [
        BusinessIdea(
            title: "AI Meal Planning",
            summary: "AI-powered meal planning for families based on budget, dietary needs, and groceries already at home.",
            customer: "Busy, budget-conscious families",
            problem: "Weekly meal planning, grocery overspending, and food waste",
            businessModel: "Monthly subscription",
            category: "Food Tech",
            viabilityScore: 84,
            founderFit: 76,
            entryDifficulty: 42,
            competitorCount: 18,
            marketDirection: "↑",
            lifecycle: .validating,
            validationProgress: 38,
            businessPlanProgress: 38,
            decision: .validate,
            accent: .coral
        ),
        BusinessIdea(
            title: "Mobile Car Detailing",
            summary: "A convenient mobile detailing service for busy households and professionals.",
            customer: "Busy vehicle owners",
            problem: "Traditional detailing takes too much time and coordination",
            businessModel: "Per-service fee + memberships",
            category: "Local Services",
            viabilityScore: 76,
            founderFit: 88,
            entryDifficulty: 28,
            competitorCount: 12,
            marketDirection: "→",
            lifecycle: .analyzed,
            validationProgress: 16,
            decision: .validate,
            accent: .blue
        ),
        BusinessIdea(
            title: "Vintage Goods Marketplace",
            summary: "A curated marketplace for independent vintage sellers and collectors.",
            category: "Marketplace",
            viabilityScore: 69,
            founderFit: 58,
            entryDifficulty: 64,
            competitorCount: 27,
            marketDirection: "↑",
            lifecycle: .analyzed,
            validationProgress: 10,
            decision: .watch,
            accent: .orange
        ),
        BusinessIdea(
            title: "Creator CRM",
            summary: "A lightweight relationship and sponsorship CRM built for independent creators.",
            category: "Creator Tools",
            viabilityScore: 54,
            founderFit: 70,
            entryDifficulty: 71,
            competitorCount: 34,
            marketDirection: "↓",
            lifecycle: .captured,
            validationProgress: 0,
            decision: .watch,
            accent: .green
        ),
        BusinessIdea(
            title: "Microlearning Studio",
            summary: "A studio for producing short, outcome-focused learning products for niche audiences.",
            category: "Education",
            viabilityScore: 81,
            founderFit: 81,
            entryDifficulty: 49,
            competitorCount: 16,
            marketDirection: "↑",
            lifecycle: .planning,
            validationProgress: 54,
            businessPlanProgress: 67,
            decision: .pursue,
            accent: .pink
        )
    ]
}


extension IdeaLifecycle {
    var next: IdeaLifecycle? {
        switch self {
        case .captured: return .analyzed
        case .analyzed: return .validating
        case .validating: return .planning
        case .planning: return .building
        case .building: return .launched
        case .launched: return nil
        }
    }

    var previous: IdeaLifecycle? {
        switch self {
        case .captured: return nil
        case .analyzed: return .captured
        case .validating: return .analyzed
        case .planning: return .validating
        case .building: return .planning
        case .launched: return .building
        }
    }

    var shortGuidance: String {
        switch self {
        case .captured:
            return "Shape the raw idea into something Kindling can analyze."
        case .analyzed:
            return "Review the opportunity and identify the assumptions that could kill it."
        case .validating:
            return "Collect real evidence before increasing commitment."
        case .planning:
            return "Turn validated evidence into an execution-ready plan."
        case .building:
            return "Build against measurable milestones, not feature lists."
        case .launched:
            return "Watch performance, market changes, and whether the original thesis still holds."
        }
    }
}
