
import SwiftUI

struct IdeaReportView: View {
    let idea: BusinessIdea
    private let background = Color(red: 0.972, green: 0.955, blue: 0.925)
    private let ink = Color(red: 0.09, green: 0.09, blue: 0.08)
    private let secondaryText = Color(red: 0.24, green: 0.23, blue: 0.21)

    private let orange = Color(red: 0.96, green: 0.62, blue: 0.04)
    private let blue = Color(red: 0.34, green: 0.56, blue: 0.88)
    private let green = Color(red: 0.20, green: 0.66, blue: 0.36)
    private let purple = Color(red: 0.91, green: 0.54, blue: 0.68)

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: KindlingStore
    @EnvironmentObject private var router: KindlingRouter
    @State private var expandedMetric: IdeaMetric?
    @State private var markerPosition = CGPoint(x: 0.72, y: 0.73)
    @State private var selectedCompetitor: IdeaCompetitor?

    @State private var scenarioBudget: Double = 12
    @State private var scenarioPrice: Double = 12
    @State private var scenarioAudience: Int = 0

    @State private var founderBudget: Double = 12
    @State private var founderHours: Double = 15
    @State private var founderSkill: Int = 2
    @State private var founderAudience: Int = 0

    @State private var selectedPlanSection: IdeaPlanSection = .summary
    @State private var planText = IdeaPlanSection.summary.draft
    @State private var planProgress = 38
    @State private var openSections: Set<IdeaReportSection> = [.niche, .verdict]

    private let nicheCompetitors: [IdeaCompetitor] = [
        IdeaCompetitor(
            name: "Mealime",
            x: 0.18,
            y: 0.25,
            pressure: 68,
            overlap: "Medium",
            price: "Freemium",
            space: "Family",
            verdict: "Compete nearby, not head-on.",
            detail: "Move toward grocery savings and pantry intelligence rather than matching broad family meal planning."
        ),
        IdeaCompetitor(
            name: "PlateJoy",
            x: 0.72,
            y: 0.23,
            pressure: 79,
            overlap: "Medium",
            price: "Premium",
            space: "Nutrition",
            verdict: "Avoid copying its core position.",
            detail: "The more attractive whitespace is around household economics rather than nutrition-first personalization."
        ),
        IdeaCompetitor(
            name: "Samsung",
            x: 0.18,
            y: 0.78,
            pressure: 84,
            overlap: "High",
            price: "Free",
            space: "Recipes",
            verdict: "Poor place for a direct fight.",
            detail: "Its ecosystem advantage makes generic recipe discovery an unfavorable battleground."
        ),
        IdeaCompetitor(
            name: "Eat This Much",
            x: 0.75,
            y: 0.42,
            pressure: 74,
            overlap: "Medium",
            price: "Subscription",
            space: "Automation",
            verdict: "Differentiate on the outcome.",
            detail: "Automation already exists here. Savings and pantry utilization give you clearer separation."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                topBar
                ideaHeader
                viabilityCard
                metricGrid
                confidenceCard

                CollapsibleReportSection(
                    title: "NICHE EXPLORER",
                    subtitle: "Positioning, competitors & open market space",
                    isOpen: binding(for: .niche)
                ) {
                    VStack(spacing: 10) {
                        nicheExplorer
                        competitorBreakdown
                    }
                }

                CollapsibleReportSection(
                    title: "KINDLING VERDICT",
                    subtitle: "What Kindling thinks you should do next",
                    isOpen: binding(for: .verdict)
                ) {
                    verdictCard
                }

                CollapsibleReportSection(
                    title: "ASSUMPTIONS",
                    subtitle: "What still has to be true",
                    isOpen: binding(for: .assumptions)
                ) {
                    assumptionsSection
                }

                CollapsibleReportSection(
                    title: "SCORE HISTORY",
                    subtitle: "How the idea is changing over time",
                    isOpen: binding(for: .history)
                ) {
                    scoreHistorySection
                }

                CollapsibleReportSection(
                    title: "SCENARIO LAB",
                    subtitle: "Test different budgets, prices & resources",
                    isOpen: binding(for: .scenario)
                ) {
                    scenarioLab
                }

                CollapsibleReportSection(
                    title: "UNIT ECONOMICS",
                    subtitle: "Price, CAC, margin & break-even",
                    isOpen: binding(for: .economics)
                ) {
                    unitEconomicsSection
                }

                CollapsibleReportSection(
                    title: "VALIDATION",
                    subtitle: "Prove the risky assumptions first",
                    isOpen: binding(for: .validation)
                ) {
                    validationSection
                }

                CollapsibleReportSection(
                    title: "YOUR FIT",
                    subtitle: "Budget, time, skills & distribution",
                    isOpen: binding(for: .fit)
                ) {
                    founderFitSection
                }

                CollapsibleReportSection(
                    title: "BUSINESS PLAN",
                    subtitle: "Turn the idea into an execution plan",
                    isOpen: binding(for: .plan)
                ) {
                    businessPlanSection
                }

                CollapsibleReportSection(
                    title: "COMPARE IDEAS",
                    subtitle: "See how this opportunity stacks up",
                    isOpen: binding(for: .compare)
                ) {
                    compareIdeasSection
                }
            }
            .padding(16)
        }
        .background(background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            reportActionDock
        }
    }

    private var reportSummary: String {
        if idea.viabilityScore >= 80 {
            return "Kindling sees a strong opportunity, but the score is only useful if the highest-risk assumptions survive validation."
        }

        if idea.viabilityScore >= 65 {
            return "The idea looks promising enough to validate. Focus on the assumptions most likely to change the decision before you build."
        }

        return "There may be an opportunity here, but the current version needs sharper positioning and stronger evidence before committing resources."
    }

    private var reportActionDock: some View {
        HStack(spacing: 7) {
            Button {
                store.updateLifecycle(id: idea.id, lifecycle: .validating)
                router.push(.validation(idea.id))
            } label: {
                Label("Validate", systemImage: "checklist")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(green)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                store.updateLifecycle(id: idea.id, lifecycle: .planning)
                router.push(.businessPlan(idea.id))
            } label: {
                Label("Plan", systemImage: "doc.text")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(purple)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                router.push(.ai(idea.id))
            } label: {
                Label("Ask AI", systemImage: "sparkles")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ink)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(background.opacity(0.97))
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

    private var ideaHeader: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("IDEA REPORT · \(idea.category.uppercased())")
                .ideaEyebrow()

            Text(idea.title)
                .font(.system(size: 39, weight: .black))
                .tracking(-2)
                .lineSpacing(-5)
                .foregroundStyle(ink)

            Text(idea.summary)
                .font(.system(size: 13))
                .foregroundStyle(secondaryText)
                .lineSpacing(4)

            HStack(spacing: 6) {
                Text("ANALYZED JUST NOW")
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.9)

                Circle()
                    .fill(green)
                    .frame(width: 7, height: 7)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.07))
            )
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    // MARK: - Viability

    private var viabilityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VIABILITY SCORE")
                .font(.system(size: 8, weight: .black))
                .tracking(1.2)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(idea.viabilityScore)")
                    .font(.system(size: 76, weight: .black))
                    .tracking(-4)

                Text("/100")
                    .font(.system(size: 14, weight: .black))
            }

            Text("STRONG OPPORTUNITY ↑")
                .font(.system(size: 9, weight: .black))
                .tracking(0.9)

            Text(reportSummary)
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    // MARK: - Expandable Metrics

    private var metricGrid: some View {
        VStack(spacing: 7) {
            if let expandedMetric {
                expandedMetricView(expandedMetric)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 7),
                        GridItem(.flexible(), spacing: 7)
                    ],
                    spacing: 7
                ) {
                    ForEach(IdeaMetric.allCases.filter { $0 != expandedMetric }, id: \.self) { metric in
                        compactMetricView(metric)
                    }
                }
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 7),
                        GridItem(.flexible(), spacing: 7)
                    ],
                    spacing: 7
                ) {
                    ForEach(IdeaMetric.allCases, id: \.self) { metric in
                        compactMetricView(metric)
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.38, dampingFraction: 0.86),
            value: expandedMetric
        )
    }

    @ViewBuilder
    private func compactMetricView(_ metric: IdeaMetric) -> some View {
        switch metric {
        case .entry:
            CompactMetricCard(
                title: "ENTRY",
                value: "\(idea.entryDifficulty)%",
                subtitle: "Moderate",
                color: orange
            ) {
                toggle(.entry)
            }

        case .competitors:
            CompactMetricCard(
                title: "COMPETITORS",
                value: "\(idea.competitorCount)",
                subtitle: "Relevant players",
                color: blue
            ) {
                toggle(.competitors)
            }

        case .momentum:
            CompactMetricCard(
                title: "MOMENTUM",
                value: "+31%",
                subtitle: "3-year interest",
                color: green
            ) {
                toggle(.momentum)
            }

        case .fit:
            CompactMetricCard(
                title: "YOUR FIT",
                value: "\(idea.founderFit)",
                subtitle: "Current match",
                color: purple
            ) {
                toggle(.fit)
            }
        }
    }

    @ViewBuilder
    private func expandedMetricView(_ metric: IdeaMetric) -> some View {
        switch metric {
        case .entry:
            ExpandedMetricCard(
                title: "ENTRY",
                value: "\(idea.entryDifficulty)%",
                subtitle: "Moderate",
                color: orange,
                onCollapse: { expandedMetric = nil }
            ) {
                Text("ENTRY DIFFICULTY")
                    .ideaEyebrow()

                Text("Buildable.\nDistribution is harder.")
                    .ideaHeading()

                StatGrid(items: [
                    ("STARTUP CAPITAL", "$8K–$20K"),
                    ("MVP TIMELINE", "8–12 wks"),
                    ("TECH COMPLEXITY", "Medium"),
                    ("REGULATORY", "Low")
                ])

                EvidenceBar(
                    label: "CUSTOMER ACQUISITION",
                    value: "High",
                    progress: 0.78
                )

                KindlingInsight(
                    label: "✦ KINDLING AI",
                    title: "Customer acquisition is the real barrier.",
                    text: "Existing AI tooling makes an MVP relatively achievable. Reaching families at a sustainable acquisition cost is the harder problem.",
                    dark: false
                )

                TwoWayStat(
                    leftTitle: "BIGGEST BARRIER",
                    leftValue: "Customer acquisition",
                    rightTitle: "EASIEST PART",
                    rightValue: "Building the MVP"
                )

                SourceButton(title: "14 signals · 82% confidence →")
            }

        case .competitors:
            ExpandedMetricCard(
                title: "COMPETITORS",
                value: "18",
                subtitle: "Relevant players",
                color: blue,
                onCollapse: { expandedMetric = nil }
            ) {
                Text("COMPETITIVE LANDSCAPE")
                    .ideaEyebrow()

                Text("Crowded, but not\nconsolidated.")
                    .ideaHeading()

                StatGrid(items: [
                    ("DIRECT", "7"),
                    ("INDIRECT", "11"),
                    ("NEW · 12 MONTHS", "+4"),
                    ("MEDIAN PRICE", "$9.99/mo")
                ])

                EvidenceBar(
                    label: "COMPETITIVE PRESSURE",
                    value: "71 / 100",
                    progress: 0.71
                )

                VStack(spacing: 0) {
                    CompetitorMiniRow(name: "Mealime", position: "General planning")
                    Divider()
                    CompetitorMiniRow(name: "Samsung Food", position: "Recipe ecosystem")
                    Divider()
                    CompetitorMiniRow(name: "Eat This Much", position: "Automation")
                    Divider()
                    CompetitorMiniRow(name: "PlateJoy", position: "Nutrition")
                }

                KindlingInsight(
                    label: "✦ OPENING DETECTED",
                    title: "Budget + pantry intelligence.",
                    text: "No leading player clearly owns the combination of family budgeting, pantry awareness, and AI meal planning.",
                    dark: true
                )

                SourceButton(title: "Explore all 18 competitors →")
            }

        case .momentum:
            ExpandedMetricCard(
                title: "MOMENTUM",
                value: "+31%",
                subtitle: "3-year interest",
                color: green,
                onCollapse: { expandedMetric = nil }
            ) {
                Text("MARKET MOMENTUM")
                    .ideaEyebrow()

                Text("Interest is still\naccelerating.")
                    .ideaHeading()

                MomentumChart()

                StatGrid(items: [
                    ("SEARCH INTEREST", "+31%"),
                    ("RELATED SEARCHES", "+46%"),
                    ("COMPETITOR GROWTH", "+18%"),
                    ("NEW PRODUCTS", "+12")
                ])

                KindlingInsight(
                    label: "✦ KINDLING SIGNAL",
                    title: "The window may still be open.",
                    text: "Interest appears to be growing faster than category consolidation, but competitor creation is also accelerating.",
                    dark: false
                )

                TwoWayStat(
                    leftTitle: "WATCH",
                    leftValue: "Search growth ↑",
                    rightTitle: "RISK",
                    rightValue: "Competition ↑"
                )

                SourceButton(title: "Updated 2h ago · 11 signals →")
            }

        case .fit:
            ExpandedMetricCard(
                title: "YOUR FIT",
                value: "\(idea.founderFit)",
                subtitle: "Current match",
                color: purple,
                onCollapse: { expandedMetric = nil }
            ) {
                Text("FOUNDER FIT")
                    .ideaEyebrow()

                Text("Good fit with one\nimportant weakness.")
                    .ideaHeading()

                FitProgressRow(label: "Budget fit", value: 82)
                FitProgressRow(label: "Time fit", value: 74)
                FitProgressRow(label: "Skill fit", value: 68)
                FitProgressRow(label: "Experience fit", value: 71)
                FitProgressRow(label: "Distribution fit", value: 54)

                StatGrid(items: [
                    ("BUDGET", "$12K"),
                    ("TIME", "15 hrs/wk"),
                    ("TECHNICAL", "Intermediate"),
                    ("AUDIENCE", "None")
                ])

                KindlingInsight(
                    label: "✦ YOUR BIGGEST ADVANTAGE",
                    title: "You can realistically validate this.",
                    text: "Your available capital and weekly time are sufficient for an MVP validation cycle.",
                    dark: false
                )

                KindlingWarning(
                    title: "Distribution",
                    text: "You do not yet have an established audience in this market."
                )

                VStack(spacing: 0) {
                    ImprovementRow(title: "Interview 20 target customers", score: "+3")
                    Divider()
                    ImprovementRow(title: "Build a 500-person waitlist", score: "+5")
                    Divider()
                    ImprovementRow(title: "Add a technical cofounder", score: "+7")
                }

                SourceButton(title: "Update my resources →")
            }
        }
    }

    private func toggle(_ metric: IdeaMetric) {
        expandedMetric = expandedMetric == metric ? nil : metric
    }

    // MARK: - Confidence

    private var confidenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ANALYSIS CONFIDENCE")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)

                    Text("82%")
                        .font(.system(size: 28, weight: .black))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("14 current signals")
                        .font(.system(size: 9, weight: .black))

                    Text("Last analyzed 2 hours ago")
                        .font(.system(size: 8))
                }
            }

            Button {
            } label: {
                Text("View sources & methodology →")
                    .font(.system(size: 8, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(Color(red: 0.72, green: 0.70, blue: 0.66))
                    .background(Color.white.opacity(0.05))
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

    private func binding(for section: IdeaReportSection) -> Binding<Bool> {
        Binding(
            get: {
                openSections.contains(section)
            },
            set: { shouldOpen in
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    if shouldOpen {
                        openSections.insert(section)
                    } else {
                        openSections.remove(section)
                    }
                }
            }
        )
    }

    // MARK: - Niche Explorer

    private var nicheExplorer: some View {
        IdeaSectionCard {
            Text("NICHE EXPLORER")
                .ideaEyebrow()

            Text("Find the space worth owning.")
                .ideaHeading()

            Text("Move your business around the market and Kindling will evaluate each position.")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.985, green: 0.968, blue: 0.940))

                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(width: 1)

                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(height: 1)

                    NicheZoneLabel(title: "FAMILY PLANNING", subtitle: "moderate")
                        .position(
                            x: proxy.size.width * 0.24,
                            y: proxy.size.height * 0.24
                        )

                    NicheZoneLabel(title: "PERSONALIZED\nNUTRITION", subtitle: "crowded")
                        .position(
                            x: proxy.size.width * 0.74,
                            y: proxy.size.height * 0.24
                        )

                    NicheZoneLabel(title: "RECIPE DISCOVERY", subtitle: "very crowded")
                        .position(
                            x: proxy.size.width * 0.24,
                            y: proxy.size.height * 0.75
                        )

                    NicheZoneLabel(title: "BUDGET + PANTRY", subtitle: "open ★")
                        .position(
                            x: proxy.size.width * 0.74,
                            y: proxy.size.height * 0.75
                        )

                    ForEach(nicheCompetitors) { competitor in
                        Button {
                            selectedCompetitor = competitor
                        } label: {
                            Text(competitor.name)
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.93, green: 0.90, blue: 0.84))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .position(
                            x: proxy.size.width * competitor.x,
                            y: proxy.size.height * competitor.y
                        )
                    }

                    Text("YOUR\nBUSINESS")
                        .font(.system(size: 8, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ink)
                        .frame(width: 58, height: 58)
                        .background(orange)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                        .overlay(
                            RoundedRectangle(cornerRadius: 17)
                                .stroke(ink, lineWidth: 2)
                        )
                        .rotationEffect(.degrees(-4))
                        .position(
                            x: proxy.size.width * markerPosition.x,
                            y: proxy.size.height * markerPosition.y
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    markerPosition = CGPoint(
                                        x: min(max(value.location.x / proxy.size.width, 0.08), 0.92),
                                        y: min(max(value.location.y / proxy.size.height, 0.08), 0.92)
                                    )
                                }
                        )
                }
            }
            .frame(height: 340)

            Text("DRAG YOUR BUSINESS AROUND THE MAP")
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundStyle(secondaryText)
                .frame(maxWidth: .infinity)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NICHE FIT")
                        .font(.system(size: 8, weight: .black))

                    Text("\(currentNiche.score)")
                        .font(.system(size: 31, weight: .black))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentNiche.name)
                        .font(.system(size: 12, weight: .black))

                    Text(currentNiche.summary)
                        .font(.system(size: 10))
                        .foregroundStyle(secondaryText)
                        .lineSpacing(2)
                }
            }
            .padding(12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 15))

            FullWidthButton(title: "✦ Find my strongest niche →", dark: true) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    markerPosition = CGPoint(x: 0.72, y: 0.73)
                }
            }
        }
    }

    private var currentNiche: IdeaNicheResult {
        let x = markerPosition.x
        let y = markerPosition.y

        if y < 0.5 && x < 0.5 {
            return IdeaNicheResult(
                name: "Family Planning",
                score: 81,
                summary: "Healthy demand, but more direct competition."
            )
        } else if y < 0.5 {
            return IdeaNicheResult(
                name: "Personalized Nutrition",
                score: 68,
                summary: "Strong demand, but more crowded and trust-intensive."
            )
        } else if x < 0.5 {
            return IdeaNicheResult(
                name: "Recipe Discovery",
                score: 57,
                summary: "Large market, but heavily commoditized."
            )
        } else {
            return IdeaNicheResult(
                name: "Budget + Pantry",
                score: 91,
                summary: "Strong demand, thinner competition, and a measurable customer outcome."
            )
        }
    }

    @ViewBuilder
    private var competitorBreakdown: some View {
        if let competitor = selectedCompetitor {
            IdeaSectionCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("COMPETITOR BREAKDOWN")
                            .ideaEyebrow()

                        Text(competitor.name)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(ink)
                    }

                    Spacer()

                    Button {
                        selectedCompetitor = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 34, height: 34)
                            .background(background)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                StatGrid(items: [
                    ("PRESSURE", "\(competitor.pressure)/100"),
                    ("OVERLAP", competitor.overlap),
                    ("PRICE", competitor.price),
                    ("SPACE", competitor.space)
                ])

                KindlingInsight(
                    label: "✦ KINDLING AI",
                    title: competitor.verdict,
                    text: competitor.detail,
                    dark: true
                )
            }
        }
    }

    // MARK: - Verdict

    private var verdictCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KINDLING VERDICT")
                .ideaEyebrow()

            Text("VALIDATE")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Color(red: 0.72, green: 0.70, blue: 0.66))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(ink)
                .clipShape(Capsule())

            Text("Promising enough to test.\nNot ready to build.")
                .font(.system(size: 24, weight: .black))
                .tracking(-0.8)
                .lineSpacing(-2)
                .foregroundStyle(ink)

            Text("The market looks attractive and your founder fit is workable, but willingness to pay remains unproven.")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)

            VStack(spacing: 6) {
                VerdictStat(title: "NEXT MILESTONE", value: "15 customer interviews")
                VerdictStat(title: "REASSESS AFTER", value: "10 qualified interviews")
                VerdictStat(title: "KILL CRITERIA", value: "<3 strong purchase signals")
            }

            FullWidthButton(title: "Start validation →", dark: true) {}
        }
        .padding(17)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }

    // MARK: - Assumptions

    private var assumptionsSection: some View {
        IdeaSectionCard {
            Text("ASSUMPTIONS")
                .ideaEyebrow()

            Text("What still has to be true?")
                .ideaHeading()

            AssumptionRow(
                color: orange,
                title: "Families will pay $12/month",
                subtitle: "Untested · highest risk"
            )

            Divider()

            AssumptionRow(
                color: purple,
                title: "Grocery savings is the strongest hook",
                subtitle: "Weak evidence · 3 signals"
            )

            Divider()

            AssumptionRow(
                color: green,
                title: "Meal planning is a recurring pain",
                subtitle: "Validated · strong evidence"
            )

            FullWidthButton(title: "+ Add assumption", dark: false) {}
        }
    }

    // MARK: - Score History

    private var scoreHistorySection: some View {
        IdeaSectionCard {
            Text("SCORE HISTORY")
                .ideaEyebrow()

            Text("How the idea is changing.")
                .ideaHeading()

            HStack(spacing: 6) {
                ScoreHistoryBox(month: "APR", score: 72)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .black))
                ScoreHistoryBox(month: "MAY", score: 76)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .black))
                ScoreHistoryBox(month: "JUN", score: 81)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .black))
                ScoreHistoryBox(month: "NOW", score: 84, highlighted: true)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 0) {
                ScoreChangeRow(symbol: "↑", text: "+3  Search demand increased")
                Divider()
                ScoreChangeRow(symbol: "✦", text: "+2  New niche opportunity detected")
                Divider()
                ScoreChangeRow(symbol: "+", text: "-2  Two competitors entered")
            }
        }
    }

    // MARK: - Scenario Lab

    private var scenarioLab: some View {
        IdeaSectionCard {
            Text("SCENARIO LAB")
                .ideaEyebrow()

            Text("What if things change?")
                .ideaHeading()

            Text("Test a different budget, price, or distribution advantage without changing the original idea.")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)

            IdeaSliderField(
                title: "Available budget",
                valueText: "$\(Int(scenarioBudget))k",
                value: $scenarioBudget,
                range: 2...40
            )

            IdeaSliderField(
                title: "Monthly price",
                valueText: "$\(Int(scenarioPrice))",
                value: $scenarioPrice,
                range: 5...30
            )

            IdeaPickerField(
                title: "Distribution",
                selection: $scenarioAudience,
                options: [
                    (0, "No audience"),
                    (1, "Small audience"),
                    (2, "Established audience")
                ]
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("PROJECTED FOUNDER FIT")
                    .font(.system(size: 8, weight: .black))

                Text("\(scenarioFit)")
                    .font(.system(size: 35, weight: .black))

                Text(
                    scenarioFit >= 84
                    ? "Stronger scenario"
                    : scenarioFit >= 70
                    ? "Workable scenario"
                    : "Resource constrained"
                )
                .font(.system(size: 9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(purple)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }

    private var scenarioFit: Int {
        let score =
            58
            + (scenarioBudget * 0.45)
            + (scenarioPrice * 0.25)
            + (Double(scenarioAudience) * 8)

        return min(94, max(50, Int(score.rounded())))
    }

    // MARK: - Unit Economics

    private var unitEconomicsSection: some View {
        IdeaSectionCard {
            Text("UNIT ECONOMICS")
                .ideaEyebrow()

            Text("Can the business work financially?")
                .ideaHeading()

            StatGrid(items: [
                ("EST. PRICE", "$12/mo"),
                ("EST. CAC", "$32"),
                ("GROSS MARGIN", "78%"),
                ("BREAK-EVEN", "420 users")
            ])

            KindlingInsight(
                label: "✦ KINDLING AI",
                title: "The model can work — if CAC stays controlled.",
                text: "At a $12 monthly subscription, customer acquisition becomes the most important financial assumption to validate.",
                dark: false
            )
        }
    }

    // MARK: - Validation

    private var validationSection: some View {
        IdeaSectionCard {
            Text("VALIDATION WORKSPACE")
                .ideaEyebrow()

            Text("Prove the risky parts first.")
                .ideaHeading()

            VStack(alignment: .leading, spacing: 4) {
                Text("VALIDATION COMPLETE")
                    .font(.system(size: 8, weight: .black))

                Text("20%")
                    .font(.system(size: 28, weight: .black))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .foregroundStyle(Color.gray)
            .background(ink)
            .clipShape(RoundedRectangle(cornerRadius: 15))

            VStack(spacing: 0) {
                ValidationTaskRow(
                    number: "01",
                    title: "Customer interviews",
                    subtitle: "0 / 15 complete"
                )

                Divider()

                ValidationTaskRow(
                    number: "02",
                    title: "Pricing test",
                    subtitle: "Not started"
                )

                Divider()

                ValidationTaskRow(
                    number: "03",
                    title: "Waitlist landing page",
                    subtitle: "Draft ready"
                )

                Divider()

                ValidationTaskRow(
                    number: "04",
                    title: "Purchase-intent test",
                    subtitle: "Not started"
                )
            }

            FullWidthButton(title: "Generate validation plan →", dark: true) {}
        }
    }

    // MARK: - Founder Fit

    private var founderFitSection: some View {
        IdeaSectionCard {
            Text("YOUR FIT")
                .ideaEyebrow()

            Text("Is this a good business for you?")
                .ideaHeading()

            IdeaSliderField(
                title: "Startup budget",
                valueText: "$\(Int(founderBudget))k",
                value: $founderBudget,
                range: 1...50
            )

            IdeaSliderField(
                title: "Hours available",
                valueText: "\(Int(founderHours)) hrs",
                value: $founderHours,
                range: 3...40
            )

            IdeaPickerField(
                title: "Technical skill",
                selection: $founderSkill,
                options: [
                    (1, "Beginner"),
                    (2, "Intermediate"),
                    (3, "Advanced")
                ]
            )

            IdeaPickerField(
                title: "Existing distribution",
                selection: $founderAudience,
                options: [
                    (0, "None yet"),
                    (1, "Small audience"),
                    (2, "Established audience")
                ]
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("FOUNDER FIT")
                    .font(.system(size: 8, weight: .black))

                Text("\(founderFitScore)")
                    .font(.system(size: 38, weight: .black))

                Text(founderFitText)
                    .font(.system(size: 10))
                    .foregroundStyle(secondaryText)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(purple)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var founderFitScore: Int {
        let score =
            45
            + (founderBudget * 0.6)
            + (founderHours * 0.45)
            + (Double(founderSkill) * 6)
            + (Double(founderAudience) * 8)

        return min(95, max(45, Int(score.rounded())))
    }

    private var founderFitText: String {
        if founderFitScore >= 84 {
            return "Strong fit. Your current resources align well."
        } else if founderFitScore >= 68 {
            return "Good fit, but distribution is your biggest gap."
        } else {
            return "Possible, but your current resources are constrained."
        }
    }

    // MARK: - Business Plan

    private var businessPlanSection: some View {
        IdeaSectionCard {
            Text("BUSINESS PLAN BUILDER")
                .ideaEyebrow()

            Text("Turn the idea into a plan.")
                .ideaHeading()

            VStack(alignment: .leading, spacing: 4) {
                Text("PLAN COMPLETE")
                    .font(.system(size: 8, weight: .black))

                Text("\(planProgress)%")
                    .font(.system(size: 28, weight: .black))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .foregroundStyle(Color.gray)
            .background(ink)
            .clipShape(RoundedRectangle(cornerRadius: 15))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(IdeaPlanSection.allCases) { section in
                        Button {
                            selectedPlanSection = section
                            planText = section.draft
                        } label: {
                            Text(section.shortTitle)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(ink)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 8)
                                .background(
                                    selectedPlanSection == section
                                    ? orange
                                    : background
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.black.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(selectedPlanSection.title)
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(ink)

                    Spacer()

                    Text("✦ AI DRAFT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(ink)
                        .clipShape(Capsule())
                }

                Text(selectedPlanSection.draft)
                    .font(.system(size: 10))
                    .foregroundStyle(secondaryText)
                    .lineSpacing(3)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 11))

                TextEditor(text: $planText)
                    .font(.system(size: 11))
                    .foregroundStyle(ink)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.black.opacity(0.08))
                    )

                FullWidthButton(title: "✦ Improve with Kindling", dark: false) {
                    planText += "\n\nKindling suggestion: add one measurable customer outcome and one assumption that still needs validation."
                }

                FullWidthButton(title: "Save section →", dark: true) {
                    planProgress = min(100, planProgress + 14)
                }
            }
            .padding(12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }

    // MARK: - Compare Ideas

    private var compareIdeasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMPARE IDEAS")
                .ideaEyebrow()

            Text("Is this still your best opportunity?")
                .ideaHeading()

            Text("Compare viability, founder fit, startup cost, time to revenue, and downside risk against another idea in your portfolio.")
                .font(.system(size: 11))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)

            FullWidthButton(title: "Compare ideas →", dark: true) {}
        }
        .padding(17)
        .background(blue)
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }
}

// MARK: - Models

enum IdeaMetric: CaseIterable {
    case entry
    case competitors
    case momentum
    case fit
}

enum IdeaReportSection: Hashable {
    case niche
    case verdict
    case assumptions
    case history
    case scenario
    case economics
    case validation
    case fit
    case plan
    case compare
}

struct IdeaCompetitor: Identifiable {
    let id = UUID()
    let name: String
    let x: CGFloat
    let y: CGFloat
    let pressure: Int
    let overlap: String
    let price: String
    let space: String
    let verdict: String
    let detail: String
}

struct IdeaNicheResult {
    let name: String
    let score: Int
    let summary: String
}

enum IdeaPlanSection: String, CaseIterable, Identifiable {
    case summary
    case customer
    case positioning
    case revenue

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .summary: return "Summary"
        case .customer: return "Customer"
        case .positioning: return "Positioning"
        case .revenue: return "Revenue"
        }
    }

    var title: String {
        switch self {
        case .summary: return "Executive summary"
        case .customer: return "Target customer"
        case .positioning: return "Offer & positioning"
        case .revenue: return "Revenue model"
        }
    }

    var draft: String {
        switch self {
        case .summary:
            return "AI Meal Planning helps budget-conscious families reduce grocery waste and spending through personalized weekly meal planning."
        case .customer:
            return "Start with budget-conscious families who already feel weekly grocery-planning stress."
        case .positioning:
            return "Own the measurable outcome of lowering grocery spending and food waste."
        case .revenue:
            return "Test a recurring subscription tied to measurable savings and convenience."
        }
    }
}

// MARK: - Metric Cards

struct CompactMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let onTap: () -> Void

    init(
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 8, weight: .black))
                        .tracking(0.9)

                    Text(value)
                        .font(.system(size: 28, weight: .black))

                    Text(subtitle)
                        .font(.system(size: 9))
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .black))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.12))
                    )
            }
            .foregroundStyle(
                Color(red: 0.09, green: 0.09, blue: 0.08)
            )
            .frame(
                maxWidth: .infinity,
                minHeight: 108,
                alignment: .topLeading
            )
            .padding(13)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

struct ExpandedMetricCard<Content: View>: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let onCollapse: () -> Void

    private let content: Content

    init(
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        onCollapse: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.onCollapse = onCollapse
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onCollapse) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.9)

                        Text(value)
                            .font(.system(size: 28, weight: .black))

                        Text(subtitle)
                            .font(.system(size: 9))
                    }

                    Spacer()

                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .black))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.12))
                        )
                }
                .foregroundStyle(
                    Color(red: 0.09, green: 0.09, blue: 0.08)
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: 92,
                    alignment: .topLeading
                )
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            Divider()
                .overlay(Color.black.opacity(0.15))

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(.top, 14)

            Button(action: onCollapse) {
                Text("Collapse ↑")
                    .font(.system(size: 8, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(
                        Color(red: 0.11, green: 0.11, blue: 0.10)
                    )
                    .background(Color.white.opacity(0.35))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Reusable Components

struct StatGrid: View {
    let items: [(String, String)]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ],
            spacing: 6
        ) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.0)
                        .font(.system(size: 7, weight: .black))
                        .tracking(0.6)

                    Text(item.1)
                        .font(.system(size: 14, weight: .black))
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 58,
                    alignment: .topLeading
                )
                .padding(10)
                .background(Color.white.opacity(0.33))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct EvidenceBar: View {
    let label: String
    let value: String
    let progress: Double

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text(value)
            }
            .font(.system(size: 8, weight: .black))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.13))

                    Capsule()
                        .fill(Color.black)
                        .frame(
                            width: proxy.size.width * progress
                        )
                }
            }
            .frame(height: 7)
        }
    }
}

struct KindlingInsight: View {
    let label: String
    let title: String
    let text: String
    let dark: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .tracking(0.8)

            Text(title)
                .font(.system(size: 16, weight: .black))

            Text(text)
                .font(.system(size: 10))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .foregroundStyle(
            dark
            ? Color(red: 0.76, green: 0.74, blue: 0.70)
            : Color(red: 0.12, green: 0.12, blue: 0.11)
        )
        .background(
            dark
            ? Color(red: 0.09, green: 0.09, blue: 0.08)
            : Color.white.opacity(0.36)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct KindlingWarning: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("⚠ BIGGEST GAP")
                .font(.system(size: 7, weight: .black))
                .tracking(0.8)

            Text(title)
                .font(.system(size: 16, weight: .black))

            Text(text)
                .font(.system(size: 10))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            Color(red: 0.98, green: 0.38, blue: 0.33)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct TwoWayStat: View {
    let leftTitle: String
    let leftValue: String
    let rightTitle: String
    let rightValue: String

    var body: some View {
        HStack(spacing: 6) {
            SmallStat(title: leftTitle, value: leftValue)
            SmallStat(title: rightTitle, value: rightValue)
        }
    }
}

struct SmallStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 7, weight: .black))
                .tracking(0.6)

            Text(value)
                .font(.system(size: 10, weight: .black))
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 58,
            alignment: .topLeading
        )
        .padding(10)
        .background(Color.white.opacity(0.33))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SourceButton: View {
    let title: String

    var body: some View {
        Button {
        } label: {
            Text(title)
                .font(.system(size: 8, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(
                    Color(red: 0.11, green: 0.11, blue: 0.10)
                )
                .background(Color.white.opacity(0.24))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.13))
                )
        }
        .buttonStyle(.plain)
    }
}

struct CollapseMetricButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Collapse ↑")
                .font(.system(size: 8, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(
                    Color(red: 0.11, green: 0.11, blue: 0.10)
                )
                .background(Color.white.opacity(0.35))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CompetitorMiniRow: View {
    let name: String
    let position: String

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 10, weight: .black))

            Spacer()

            Text(position)
                .font(.system(size: 8))
        }
        .padding(.vertical, 8)
    }
}

struct FitProgressRow: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value)")
            }
            .font(.system(size: 9, weight: .black))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.13))

                    Capsule()
                        .fill(Color.black)
                        .frame(
                            width: proxy.size.width
                            * CGFloat(value) / 100
                        )
                }
            }
            .frame(height: 7)
        }
    }
}

struct ImprovementRow: View {
    let title: String
    let score: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 9))

            Spacer()

            Text(score)
                .font(.system(size: 10, weight: .black))
        }
        .padding(.vertical, 8)
    }
}

struct MomentumChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("SEARCH INTEREST")
                    .font(.system(size: 7, weight: .black))

                Spacer()

                Text("+31%")
                    .font(.system(size: 20, weight: .black))
            }

            GeometryReader { proxy in
                Path { path in
                    let points: [CGPoint] = [
                        .init(x: 0.02, y: 0.82),
                        .init(x: 0.14, y: 0.79),
                        .init(x: 0.26, y: 0.71),
                        .init(x: 0.38, y: 0.75),
                        .init(x: 0.49, y: 0.58),
                        .init(x: 0.60, y: 0.52),
                        .init(x: 0.71, y: 0.40),
                        .init(x: 0.82, y: 0.26),
                        .init(x: 0.92, y: 0.20),
                        .init(x: 0.98, y: 0.08)
                    ]

                    guard let first = points.first else {
                        return
                    }

                    path.move(
                        to: CGPoint(
                            x: first.x * proxy.size.width,
                            y: first.y * proxy.size.height
                        )
                    )

                    for point in points.dropFirst() {
                        path.addLine(
                            to: CGPoint(
                                x: point.x * proxy.size.width,
                                y: point.y * proxy.size.height
                            )
                        )
                    }
                }
                .stroke(
                    Color.black,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(height: 90)

            HStack {
                Text("2023")
                Spacer()
                Text("2026")
            }
            .font(.system(size: 7, weight: .black))
        }
        .padding(11)
        .background(Color.white.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct CollapsibleReportSection<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var isOpen: Bool
    private let content: Content

    init(
        title: String,
        subtitle: String,
        isOpen: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isOpen = isOpen
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                isOpen.toggle()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 9, weight: .black))
                            .tracking(1.1)
                            .foregroundStyle(
                                Color(red: 0.15, green: 0.14, blue: 0.13)
                            )

                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(
                                Color(red: 0.30, green: 0.28, blue: 0.25)
                            )
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(
                            Color(red: 0.12, green: 0.12, blue: 0.11)
                        )
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .frame(width: 34, height: 34)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.08))
                        )
                }
                .padding(14)
                .background(
                    Color(red: 0.985, green: 0.968, blue: 0.940)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.black.opacity(0.06))
                )
            }
            .buttonStyle(.plain)

            if isOpen {
                content
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        )
                    )
            }
        }
    }
}

struct IdeaSectionCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(Color.black.opacity(0.07))
        )
    }
}

struct NicheZoneLabel: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 7, weight: .black))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 7))
        }
        .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.08))
        .padding(7)
        .frame(width: 120, height: 75)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    Color.black.opacity(0.12),
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: [4]
                    )
                )
        )
    }
}

struct FullWidthButton: View {
    let title: String
    let dark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .foregroundStyle(
                    dark
                    ? Color(red: 0.68, green: 0.66, blue: 0.62)
                    : Color(red: 0.12, green: 0.12, blue: 0.11)
                )
                .background(
                    dark
                    ? Color(red: 0.09, green: 0.09, blue: 0.08)
                    : Color.white
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            dark
                            ? Color.clear
                            : Color.black.opacity(0.08)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct VerdictStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 7, weight: .black))
                .tracking(0.7)

            Text(value)
                .font(.system(size: 11, weight: .black))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AssumptionRow: View {
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .black))

                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundStyle(
                        Color(red: 0.30, green: 0.28, blue: 0.25)
                    )
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.vertical, 8)
    }
}

struct ScoreHistoryBox: View {
    let month: String
    let score: Int
    var highlighted: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text(month)
                .font(.system(size: 7, weight: .black))

            Text("\(score)")
                .font(.system(size: 19, weight: .black))
        }
        .padding(9)
        .background(
            highlighted
            ? Color(red: 0.96, green: 0.62, blue: 0.04)
            : Color(red: 0.972, green: 0.955, blue: 0.925)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ScoreChangeRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.system(size: 12, weight: .black))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 9))

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct IdeaSliderField: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
            }
            .font(.system(size: 10, weight: .black))

            Slider(value: $value, in: range)
        }
    }
}

struct IdeaPickerField: View {
    let title: String
    @Binding var selection: Int
    let options: [(Int, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 10, weight: .black))

            Picker(title, selection: $selection) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Text(option.1)
                        .tag(option.0)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color.black.opacity(0.08))
            )
        }
    }
}

struct ValidationTaskRow: View {
    let number: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.system(size: 8, weight: .black))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .black))

                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundStyle(
                        Color(red: 0.30, green: 0.28, blue: 0.25)
                    )
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.vertical, 9)
    }
}

// MARK: - Shared Text Styles

extension View {
    func ideaEyebrow() -> some View {
        self
            .font(.system(size: 8, weight: .black))
            .tracking(1.2)
            .foregroundStyle(
                Color(red: 0.18, green: 0.17, blue: 0.15)
            )
    }

    func ideaHeading() -> some View {
        self
            .font(.system(size: 24, weight: .black))
            .tracking(-0.8)
            .lineSpacing(-2)
            .foregroundStyle(
                Color(red: 0.09, green: 0.09, blue: 0.08)
            )
    }
}

#Preview {
    NavigationStack {
        IdeaReportView(idea: BusinessIdea.demoIdeas[0])
            .environmentObject(KindlingStore())
            .environmentObject(KindlingRouter())
    }
}
