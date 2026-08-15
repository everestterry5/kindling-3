
import SwiftUI

struct BusinessPlanView: View {
    private let background = Color(red: 0.972, green: 0.955, blue: 0.925)
    private let ink = Color(red: 0.09, green: 0.09, blue: 0.08)
    private let secondaryText = Color(red: 0.24, green: 0.23, blue: 0.21)

    private let orange = Color(red: 0.96, green: 0.62, blue: 0.04)
    private let blue = Color(red: 0.34, green: 0.56, blue: 0.88)
    private let green = Color(red: 0.20, green: 0.66, blue: 0.36)
    private let pink = Color(red: 0.91, green: 0.54, blue: 0.68)
    private let coral = Color(red: 0.98, green: 0.38, blue: 0.33)

    @Environment(\.dismiss) private var dismiss

    let idea: BusinessIdea?

    init(idea: BusinessIdea? = nil) {
        self.idea = idea
    }

    @State private var showPitchDeck = false
    @State private var openSection: PlanBuilderSection? = .summary
    @State private var completedSections: Set<PlanBuilderSection> = [.summary]

    @State private var executiveSummary = """
    AI Meal Planning helps budget-conscious families reduce grocery waste and spending through personalized weekly meal planning. The product combines pantry awareness, dietary preferences, and grocery budgeting into one simple experience.
    """

    @State private var targetCustomer = """
    Primary customer: busy, budget-conscious households with recurring grocery-planning stress.

    Early adopter profile:
    • Ages 28–45
    • Shops for a household of 2–5
    • Uses digital planning tools
    • Wants to reduce food waste
    • Feels grocery prices are difficult to control
    """

    @State private var positioning = """
    Position the product around one measurable outcome: helping families spend less on groceries while reducing food waste.

    Core promise:
    “Plan meals around what you already have, what your family likes, and what you can afford.”
    """

    @State private var revenueModel = """
    Primary model: monthly subscription.

    Suggested starting price:
    $9.99–$14.99 / month

    Possible future revenue:
    • Annual subscription
    • Grocery affiliate partnerships
    • Premium family features
    • B2B wellness partnerships
    """

    @State private var goToMarket = """
    Start narrow and validate before paid growth.

    Initial channels:
    • Budget-conscious family communities
    • Parenting creators
    • Grocery-saving content
    • SEO around meal planning and grocery budgets
    • Referral loops from household savings results
    """

    @State private var operations = """
    MVP team:
    • Founder / product
    • Contract iOS or Flutter developer
    • AI / backend support
    • Part-time design

    Initial infrastructure:
    • Supabase or Firebase
    • OpenAI API through backend
    • Analytics
    • Subscription billing
    """

    @State private var financialPlan = """
    Estimated MVP cost: $8,000–$20,000
    Target monthly price: $12
    Estimated gross margin: 78%
    Early CAC assumption: $32
    Estimated break-even users: 420

    These numbers should be treated as validation assumptions, not guarantees.
    """

    @State private var risks = """
    Highest risks:
    1. Customer acquisition cost is too high
    2. Users prefer free meal-planning alternatives
    3. Grocery integrations add too much complexity
    4. AI planning quality is inconsistent
    5. Users do not perceive enough monthly value to subscribe
    """

    @State private var milestones = """
    30 days:
    • 15 customer interviews
    • Test pricing
    • Launch waitlist

    60 days:
    • Build clickable prototype
    • Reach 100 waitlist users
    • Run purchase-intent test

    90 days:
    • Build MVP only if validation thresholds are met
    """

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                topBar
                header
                progressCard
                planSections
                aiCoach
                milestoneSummary
                pitchDeckBuilder
                finalActions
            }
            .padding(16)
        }
        .background(background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPitchDeck) {
            PitchDeckPreviewView(
                idea: idea,
                executiveSummary: executiveSummary,
                targetCustomer: targetCustomer,
                positioning: positioning,
                revenueModel: revenueModel,
                goToMarket: goToMarket,
                operations: operations,
                financialPlan: financialPlan,
                risks: risks,
                milestones: milestones,
                planProgress: planProgress
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("KINDLING®")
                .font(.system(size: 17, weight: .black))
                .tracking(2.2)
                .foregroundStyle(ink)

            Spacer()

            Button {
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("BUSINESS PLAN · \((idea?.title ?? "AI MEAL PLANNING").uppercased())")
                .planEyebrow()

            Text("Turn the idea\ninto a plan.")
                .font(.system(size: 39, weight: .black))
                .tracking(-2)
                .lineSpacing(-5)
                .foregroundStyle(ink)

            Text("Build the plan section by section. Kindling uses your market research, founder fit, and validation data to help draft each part.")
                .font(.system(size: 13))
                .foregroundStyle(secondaryText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    // MARK: - Progress

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PLAN PROGRESS")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)

                    Text("\(planProgress)%")
                        .font(.system(size: 34, weight: .black))
                }

                Spacer()

                Text("\(completedSections.count) / \(PlanBuilderSection.allCases.count) sections")
                    .font(.system(size: 9, weight: .black))
            }

            ProgressView(value: Double(planProgress) / 100)
                .tint(ink)

            Text(progressMessage)
                .font(.system(size: 10))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)
        }
        .padding(16)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var planProgress: Int {
        Int(
            (Double(completedSections.count) /
             Double(PlanBuilderSection.allCases.count)) * 100
        )
    }

    private var progressMessage: String {
        if planProgress >= 100 {
            return "Your first complete draft is ready for review."
        } else if planProgress >= 60 {
            return "The foundation is strong. Finish the remaining execution and risk sections."
        } else {
            return "Keep building the core sections before worrying about polish."
        }
    }

    // MARK: - Sections

    private var planSections: some View {
        VStack(spacing: 8) {
            ForEach(PlanBuilderSection.allCases) { section in
                PlanBuilderSectionCard(
                    section: section,
                    accent: accentColor(for: section),
                    isOpen: openSection == section,
                    isComplete: completedSections.contains(section),
                    onToggle: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            openSection = openSection == section ? nil : section
                        }
                    }
                ) {
                    sectionEditor(for: section)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionEditor(for section: PlanBuilderSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KindlingPlanInsight(
                title: section.aiTitle,
                text: section.aiInsight
            )

            TextEditor(text: binding(for: section))
                .font(.system(size: 11))
                .foregroundStyle(ink)
                .frame(minHeight: 180)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(Color.black.opacity(0.08))
                )

            Button {
                improve(section)
            } label: {
                Text("✦ Improve with Kindling")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)

            Button {
                toggleComplete(section)
            } label: {
                HStack {
                    Image(
                        systemName:
                            completedSections.contains(section)
                            ? "checkmark.circle.fill"
                            : "circle"
                    )

                    Text(
                        completedSections.contains(section)
                        ? "Section complete"
                        : "Mark section complete"
                    )
                }
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(
                    completedSections.contains(section)
                    ? ink
                    : Color.gray
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    completedSections.contains(section)
                    ? green
                    : ink
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func binding(for section: PlanBuilderSection) -> Binding<String> {
        switch section {
        case .summary:
            return $executiveSummary
        case .customer:
            return $targetCustomer
        case .positioning:
            return $positioning
        case .revenue:
            return $revenueModel
        case .goToMarket:
            return $goToMarket
        case .operations:
            return $operations
        case .financials:
            return $financialPlan
        case .risks:
            return $risks
        case .milestones:
            return $milestones
        }
    }

    private func toggleComplete(_ section: PlanBuilderSection) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            if completedSections.contains(section) {
                completedSections.remove(section)
            } else {
                completedSections.insert(section)
            }
        }
    }

    private func improve(_ section: PlanBuilderSection) {
        let addition = "\n\nKindling suggestion: add one measurable outcome, one assumption, and one sentence explaining what would make this section wrong."

        switch section {
        case .summary:
            executiveSummary += addition
        case .customer:
            targetCustomer += addition
        case .positioning:
            positioning += addition
        case .revenue:
            revenueModel += addition
        case .goToMarket:
            goToMarket += addition
        case .operations:
            operations += addition
        case .financials:
            financialPlan += addition
        case .risks:
            risks += addition
        case .milestones:
            milestones += addition
        }
    }

    private func accentColor(for section: PlanBuilderSection) -> Color {
        switch section {
        case .summary:
            return orange
        case .customer:
            return blue
        case .positioning:
            return pink
        case .revenue:
            return green
        case .goToMarket:
            return coral
        case .operations:
            return blue
        case .financials:
            return orange
        case .risks:
            return coral
        case .milestones:
            return green
        }
    }

    // MARK: - AI Coach

    private var aiCoach: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.35))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("KINDLING PLAN COACH")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)

                    Text("Pressure-test the whole plan.")
                        .font(.system(size: 18, weight: .black))
                }

                Spacer()
            }

            Text("Kindling can look across the entire plan and point out contradictions, weak assumptions, missing proof, and sections that do not match the market analysis.")
                .font(.system(size: 10))
                .lineSpacing(3)

            Button {
            } label: {
                Text("✦ Review my full plan →")
                    .font(.system(size: 9, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .foregroundStyle(Color(red: 0.72, green: 0.70, blue: 0.66))
        .background(ink)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Milestones

    private var milestoneSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EXECUTION ROADMAP")
                .planEyebrow()

            Text("What happens after the plan?")
                .font(.system(size: 24, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(ink)

            HStack(spacing: 7) {
                MilestoneCard(
                    number: "01",
                    title: "Validate",
                    detail: "15 interviews",
                    color: orange
                )

                MilestoneCard(
                    number: "02",
                    title: "Prototype",
                    detail: "Test the UX",
                    color: blue
                )

                MilestoneCard(
                    number: "03",
                    title: "Launch MVP",
                    detail: "Only if validated",
                    color: green
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(Color.black.opacity(0.07))
        )
    }


    // MARK: - Pitch Deck

    private var pitchDeckBuilder: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("PITCH DECK")
                        .planEyebrow()

                    Text("Turn this plan into a deck.")
                        .font(.system(size: 25, weight: .black))
                        .tracking(-0.9)
                        .foregroundStyle(ink)

                    Text("Kindling converts the business plan into an investor-style narrative: problem, customer, solution, market, model, traction, roadmap, risks, and the ask.")
                        .font(.system(size: 11))
                        .foregroundStyle(secondaryText)
                        .lineSpacing(4)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(blue)
                        .frame(width: 54, height: 68)
                        .rotationEffect(.degrees(-5))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(orange)
                        .frame(width: 54, height: 68)
                        .rotationEffect(.degrees(4))
                        .offset(x: 10, y: 8)

                    Text("10")
                        .font(.system(size: 23, weight: .black))
                        .foregroundStyle(ink)
                        .offset(x: 6, y: 6)
                }
                .padding(.trailing, 8)
            }

            HStack(spacing: 7) {
                PitchDeckMiniStat(
                    label: "SLIDES",
                    value: "10",
                    color: orange
                )

                PitchDeckMiniStat(
                    label: "READY",
                    value: "\(planProgress)%",
                    color: green
                )

                PitchDeckMiniStat(
                    label: "FORMAT",
                    value: "PREVIEW",
                    color: blue
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                PitchDeckOutlineRow(number: "01", title: "Hook + Problem")
                PitchDeckOutlineRow(number: "02", title: "Customer + Solution")
                PitchDeckOutlineRow(number: "03", title: "Market + Business Model")
                PitchDeckOutlineRow(number: "04", title: "Roadmap + Ask")
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showPitchDeck = true
            } label: {
                HStack {
                    Text("BUILD PITCH DECK")
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.8)

                    Spacer()

                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 12, weight: .black))
                }
                .foregroundStyle(Color.gray)
                .padding(.horizontal, 15)
                .frame(height: 48)
                .background(ink)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Text(
                planProgress < 100
                ? "Draft deck available now. Complete the plan sections to improve the generated slides."
                : "Your plan is complete. The deck is ready for a cleaner final review."
            )
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(secondaryText)
            .lineSpacing(3)
        }
        .padding(17)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(Color.black.opacity(0.07))
        )
    }

    // MARK: - Final Actions

    private var finalActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                planProgress >= 100
                ? "Your first draft is ready."
                : "Finish the plan before export."
            )
            .font(.system(size: 23, weight: .black))
            .tracking(-0.8)
            .foregroundStyle(ink)

            Text(
                planProgress >= 100
                ? "Review the assumptions, validate the highest-risk claims, then turn this into an execution document."
                : "Kindling will unlock a clean export once all core sections have been reviewed."
            )
            .font(.system(size: 11))
            .foregroundStyle(secondaryText)
            .lineSpacing(3)

            Button {
            } label: {
                Text(
                    planProgress >= 100
                    ? "Export business plan →"
                    : "Complete remaining sections"
                )
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ink)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(planProgress < 100)
            .opacity(planProgress < 100 ? 0.55 : 1)
        }
        .padding(17)
        .background(pink)
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }
}

// MARK: - Plan Section Model

enum PlanBuilderSection: String, CaseIterable, Identifiable {
    case summary
    case customer
    case positioning
    case revenue
    case goToMarket
    case operations
    case financials
    case risks
    case milestones

    var id: String { rawValue }

    var number: String {
        switch self {
        case .summary: return "01"
        case .customer: return "02"
        case .positioning: return "03"
        case .revenue: return "04"
        case .goToMarket: return "05"
        case .operations: return "06"
        case .financials: return "07"
        case .risks: return "08"
        case .milestones: return "09"
        }
    }

    var title: String {
        switch self {
        case .summary: return "Executive Summary"
        case .customer: return "Target Customer"
        case .positioning: return "Offer & Positioning"
        case .revenue: return "Revenue Model"
        case .goToMarket: return "Go-to-Market"
        case .operations: return "Operations"
        case .financials: return "Financial Plan"
        case .risks: return "Risks & Assumptions"
        case .milestones: return "Milestones"
        }
    }

    var subtitle: String {
        switch self {
        case .summary: return "What the business is and why it matters"
        case .customer: return "Who feels the pain most strongly"
        case .positioning: return "Why customers should choose you"
        case .revenue: return "How the business makes money"
        case .goToMarket: return "How the first customers find you"
        case .operations: return "What it takes to deliver"
        case .financials: return "Costs, margins, CAC and break-even"
        case .risks: return "What could make the plan fail"
        case .milestones: return "What happens over the next 90 days"
        }
    }

    var aiTitle: String {
        switch self {
        case .summary:
            return "Lead with the customer outcome."
        case .customer:
            return "Start narrower than feels comfortable."
        case .positioning:
            return "Own grocery savings, not generic meal planning."
        case .revenue:
            return "Tie the price to measurable value."
        case .goToMarket:
            return "Do not begin with broad paid acquisition."
        case .operations:
            return "Keep the MVP team small."
        case .financials:
            return "CAC is the number to watch."
        case .risks:
            return "Willingness to pay is still unproven."
        case .milestones:
            return "Validation should control the build decision."
        }
    }

    var aiInsight: String {
        switch self {
        case .summary:
            return "The summary should explain the customer, the problem, the measurable outcome, and why now."
        case .customer:
            return "Kindling sees the strongest early-adopter fit among budget-conscious families already experiencing grocery-planning stress."
        case .positioning:
            return "The strongest whitespace is around family grocery savings plus pantry intelligence."
        case .revenue:
            return "A recurring subscription makes sense only if users can clearly feel the savings or convenience every month."
        case .goToMarket:
            return "Community, creators, and high-intent content are more realistic early channels than expensive broad advertising."
        case .operations:
            return "The first version should avoid unnecessary grocery integrations and operational complexity."
        case .financials:
            return "The business can work on paper, but acquisition economics remain the highest-risk financial assumption."
        case .risks:
            return "List the assumptions that can actually kill the business, not generic startup risks."
        case .milestones:
            return "Do not treat the 90-day roadmap as fixed. Each phase should depend on evidence from the prior phase."
        }
    }
}

// MARK: - Reusable Views

struct PlanBuilderSectionCard<Content: View>: View {
    let section: PlanBuilderSection
    let accent: Color
    let isOpen: Bool
    let isComplete: Bool
    let onToggle: () -> Void
    private let content: Content

    init(
        section: PlanBuilderSection,
        accent: Color,
        isOpen: Bool,
        isComplete: Bool,
        onToggle: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.section = section
        self.accent = accent
        self.isOpen = isOpen
        self.isComplete = isComplete
        self.onToggle = onToggle
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Text(section.number)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))
                        .frame(width: 36, height: 36)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 11))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))

                        Text(section.subtitle)
                            .font(.system(size: 9))
                            .foregroundStyle(Color(red: 0.24, green: 0.23, blue: 0.21))
                    }

                    Spacer()

                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(red: 0.20, green: 0.66, blue: 0.36))
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(14)
                .background(Color.white)
            }
            .buttonStyle(.plain)

            if isOpen {
                Divider()

                content
                    .padding(14)
                    .background(Color(red: 0.985, green: 0.968, blue: 0.940))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.07))
        )
    }
}

struct KindlingPlanInsight: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✦ KINDLING AI")
                .font(.system(size: 7, weight: .black))
                .tracking(0.8)

            Text(title)
                .font(.system(size: 16, weight: .black))

            Text(text)
                .font(.system(size: 10))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.11))
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MilestoneCard: View {
    let number: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(number)
                .font(.system(size: 8, weight: .black))

            Spacer()

            Text(title)
                .font(.system(size: 13, weight: .black))

            Text(detail)
                .font(.system(size: 8))
        }
        .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(11)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


struct PitchDeckMiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 6, weight: .black))
                .tracking(0.8)

            Text(value)
                .font(.system(size: 13, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}

struct PitchDeckOutlineRow: View {
    let number: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))
                .frame(width: 30, height: 30)
                .background(Color(red: 0.985, green: 0.968, blue: 0.940))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))

            Spacer()
        }
    }
}

extension View {
    func planEyebrow() -> some View {
        self
            .font(.system(size: 8, weight: .black))
            .tracking(1.2)
            .foregroundStyle(Color(red: 0.18, green: 0.17, blue: 0.15))
    }
}

#Preview {
    NavigationStack {
        BusinessPlanView()
    }
}
