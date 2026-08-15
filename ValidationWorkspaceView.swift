import SwiftUI
import UIKit

struct ValidationWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kindlingDarkMode") private var isDarkMode = false

    @State private var selectedTab: ValidationTab = .overview
    @State private var openExperiment: ValidationExperiment?
    @State private var completedTasks: Set<String> = ["landing-copy"]
    @State private var interviewCount: Int = 4
    @State private var strongSignals: Int = 2
    @State private var pricingResponses: Int = 6
    @State private var selectedPrice: Int = 12
    @State private var waitlistSignups: Int = 38
    @State private var purchaseIntent: Int = 7

    // MARK: - Adaptive Theme

    private var background: Color {
        isDarkMode
        ? Color(red: 0.055, green: 0.053, blue: 0.049)
        : Color(red: 0.988, green: 0.984, blue: 0.970)
    }

    private var paper: Color {
        isDarkMode
        ? Color(red: 0.095, green: 0.091, blue: 0.084)
        : Color.white
    }

    private var raisedPaper: Color {
        isDarkMode
        ? Color(red: 0.125, green: 0.119, blue: 0.110)
        : Color(red: 0.975, green: 0.965, blue: 0.945)
    }

    private var ink: Color {
        isDarkMode
        ? Color(red: 0.955, green: 0.945, blue: 0.920)
        : Color(red: 0.09, green: 0.09, blue: 0.08)
    }

    private var secondary: Color {
        isDarkMode
        ? Color(red: 0.74, green: 0.71, blue: 0.66)
        : Color(red: 0.24, green: 0.23, blue: 0.21)
    }

    private var border: Color {
        isDarkMode
        ? Color.white.opacity(0.10)
        : Color.black.opacity(0.07)
    }

    private var orange: Color {
        isDarkMode
        ? Color(red: 0.62, green: 0.37, blue: 0.02)
        : Color(red: 0.96, green: 0.62, blue: 0.04)
    }

    private var blue: Color {
        isDarkMode
        ? Color(red: 0.20, green: 0.36, blue: 0.61)
        : Color(red: 0.34, green: 0.56, blue: 0.88)
    }

    private var green: Color {
        isDarkMode
        ? Color(red: 0.12, green: 0.41, blue: 0.24)
        : Color(red: 0.20, green: 0.66, blue: 0.36)
    }

    private var pink: Color {
        isDarkMode
        ? Color(red: 0.56, green: 0.29, blue: 0.39)
        : Color(red: 0.91, green: 0.54, blue: 0.68)
    }

    private var coral: Color {
        isDarkMode
        ? Color(red: 0.63, green: 0.22, blue: 0.20)
        : Color(red: 0.98, green: 0.38, blue: 0.33)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 14) {
                    header
                    scoreCard
                    tabBar

                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .experiments:
                        experimentsContent
                    case .evidence:
                        evidenceContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
            .background(background)
        }
        .background(background.ignoresSafeArea())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.28), value: isDarkMode)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(paper)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(border))
            }
            .buttonStyle(ValidationPressStyle())

            Spacer()

            Text("KINDLING®")
                .font(.system(size: 16, weight: .black))
                .tracking(2.0)
                .foregroundStyle(ink)

            Spacer()

            Button {
                haptic(.selection)
                withAnimation(.easeInOut(duration: 0.28)) {
                    isDarkMode.toggle()
                }
            } label: {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(paper)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(border))
            }
            .buttonStyle(ValidationPressStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(background)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            eyebrow("VALIDATION · AI MEAL PLANNING")

            Text("Prove the risky\nparts first.")
                .font(.system(size: 39, weight: .black))
                .tracking(-2)
                .lineSpacing(-5)
                .foregroundStyle(ink)

            Text("Kindling tracks what you believe, what you’ve actually proven, and what still has to be true before you spend real time or money.")
                .font(.system(size: 12))
                .foregroundStyle(secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - Score

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VALIDATION CONFIDENCE")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(validationConfidence)")
                            .font(.system(size: 54, weight: .black))
                            .tracking(-3)

                        Text("%")
                            .font(.system(size: 13, weight: .black))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("VIABILITY")
                        .font(.system(size: 7, weight: .black))
                        .tracking(0.8)

                    Text("\(updatedViability)")
                        .font(.system(size: 24, weight: .black))

                    Text(scoreDeltaText)
                        .font(.system(size: 8, weight: .black))
                }
            }

            ProgressView(value: Double(validationConfidence) / 100)
                .tint(ink)

            Text(validationSummary)
                .font(.system(size: 10))
                .foregroundStyle(secondary)
                .lineSpacing(3)
        }
        .foregroundStyle(ink)
        .padding(18)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var validationConfidence: Int {
        let interviewScore = min(interviewCount * 3, 30)
        let strongSignalScore = min(strongSignals * 5, 20)
        let pricingScore = min(pricingResponses * 2, 20)
        let waitlistScore = min(waitlistSignups / 4, 15)
        let purchaseScore = min(purchaseIntent * 2, 15)

        return min(
            100,
            interviewScore
            + strongSignalScore
            + pricingScore
            + waitlistScore
            + purchaseScore
        )
    }

    private var updatedViability: Int {
        var score = 79

        if strongSignals >= 3 { score += 3 }
        if waitlistSignups >= 50 { score += 2 }
        if pricingResponses >= 10 { score += 2 }
        if purchaseIntent >= 10 { score += 3 }

        if interviewCount >= 10 && strongSignals < 3 { score -= 5 }

        return min(95, max(50, score))
    }

    private var scoreDeltaText: String {
        let delta = updatedViability - 84

        if delta > 0 {
            return "+\(delta) from original"
        } else if delta < 0 {
            return "\(delta) from original"
        } else {
            return "unchanged"
        }
    }

    private var validationSummary: String {
        if validationConfidence < 35 {
            return "Too many core assumptions are still untested. Keep validating before you build."
        } else if validationConfidence < 70 {
            return "Evidence is forming, but willingness to pay and purchase intent still need stronger proof."
        } else {
            return "You now have enough evidence to make a more confident build / pivot / stop decision."
        }
    }

    // MARK: - Tabs

    private var tabBar: some View {
        HStack(spacing: 7) {
            ForEach(ValidationTab.allCases) { tab in
                Button {
                    haptic(.selection)
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                            ? raisedPaper
                            : paper
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTab == tab
                                    ? ink.opacity(0.65)
                                    : border
                                )
                        )
                }
                .buttonStyle(ValidationPressStyle())
            }
        }
    }

    // MARK: - Overview

    private var overviewContent: some View {
        VStack(spacing: 12) {
            decisionCard
            assumptionsCard
            validationProgressCard
            nextExperimentCard
            killCriteriaCard
        }
    }

    private var decisionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("CURRENT DECISION")

            Text(currentDecisionTitle)
                .font(.system(size: 24, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(ink)

            Text(currentDecisionExplanation)
                .font(.system(size: 10))
                .foregroundStyle(secondary)
                .lineSpacing(3)

            HStack(spacing: 7) {
                DecisionChip(
                    title: "BUILD",
                    active: currentDecision == .build,
                    color: green,
                    ink: ink
                )

                DecisionChip(
                    title: "VALIDATE",
                    active: currentDecision == .validate,
                    color: orange,
                    ink: ink
                )

                DecisionChip(
                    title: "PIVOT",
                    active: currentDecision == .pivot,
                    color: blue,
                    ink: ink
                )

                DecisionChip(
                    title: "STOP",
                    active: currentDecision == .stop,
                    color: coral,
                    ink: ink
                )
            }
        }
        .padding(16)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }

    private var currentDecision: ValidationDecision {
        if interviewCount >= 10 && strongSignals < 3 {
            return .stop
        }

        if purchaseIntent >= 10 && strongSignals >= 3 {
            return .build
        }

        if interviewCount >= 8 && strongSignals >= 2 && pricingResponses < 10 {
            return .pivot
        }

        return .validate
    }

    private var currentDecisionTitle: String {
        switch currentDecision {
        case .build:
            return "Evidence is strong enough to consider an MVP."
        case .validate:
            return "Keep validating before you build."
        case .pivot:
            return "The problem looks real. The offer still needs work."
        case .stop:
            return "The current evidence says stop or radically rethink it."
        }
    }

    private var currentDecisionExplanation: String {
        switch currentDecision {
        case .build:
            return "Purchase intent and customer signals have crossed your current validation threshold."
        case .validate:
            return "You still need stronger proof that customers will actually pay, not just say the idea sounds useful."
        case .pivot:
            return "Customer pain is showing up, but pricing or positioning has not yet earned enough confidence."
        case .stop:
            return "Your interview volume is high enough that weak purchase signals now matter."
        }
    }

    private var assumptionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("HIGHEST-RISK ASSUMPTIONS")

            Text("What still has to be true?")
                .font(.system(size: 23, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(ink)

            VStack(spacing: 0) {
                ValidationAssumptionRow(
                    color: coral,
                    title: "Families will pay $12 / month",
                    status: pricingResponses >= 10 ? "Evidence forming" : "Untested",
                    impact: "Critical",
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                ValidationAssumptionRow(
                    color: orange,
                    title: "Grocery savings is the strongest hook",
                    status: strongSignals >= 3 ? "Supported" : "Weak evidence",
                    impact: "High",
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                ValidationAssumptionRow(
                    color: green,
                    title: "Meal planning is a recurring pain",
                    status: interviewCount >= 5 ? "Validated" : "Testing",
                    impact: "High",
                    ink: ink,
                    secondary: secondary
                )
            }
        }
        .padding(16)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }

    private var validationProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            eyebrow("EXPERIMENT PROGRESS")

            HStack(spacing: 7) {
                ValidationProgressTile(
                    label: "INTERVIEWS",
                    value: "\(interviewCount)/15",
                    color: blue,
                    ink: ink
                )

                ValidationProgressTile(
                    label: "PRICE TEST",
                    value: "\(pricingResponses)/10",
                    color: pink,
                    ink: ink
                )

                ValidationProgressTile(
                    label: "WAITLIST",
                    value: "\(waitlistSignups)",
                    color: green,
                    ink: ink
                )
            }

            Button {
                selectedTab = .experiments
                haptic(.light)
            } label: {
                Text("Open experiments →")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(raisedPaper)
                    .clipShape(Capsule())
            }
            .buttonStyle(ValidationPressStyle())
        }
        .padding(16)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }

    private var nextExperimentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("NEXT BEST EXPERIMENT")

            Text("Test willingness to pay.")
                .font(.system(size: 23, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(ink)

            Text("The biggest remaining uncertainty is whether families will pay enough for this to become a real business.")
                .font(.system(size: 10))
                .foregroundStyle(secondary)
                .lineSpacing(3)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TARGET")
                        .font(.system(size: 7, weight: .black))
                    Text("10 pricing responses")
                        .font(.system(size: 11, weight: .black))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("TIME")
                        .font(.system(size: 7, weight: .black))
                    Text("1–2 days")
                        .font(.system(size: 11, weight: .black))
                }
            }
            .foregroundStyle(ink)
            .padding(11)
            .background(orange.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                selectedTab = .experiments
                openExperiment = .pricing
                haptic(.medium)
            } label: {
                Text("Start pricing test →")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(
                        isDarkMode ? ink : Color.white.opacity(0.90)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        isDarkMode
                        ? raisedPaper
                        : Color(red: 0.09, green: 0.09, blue: 0.08)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(ValidationPressStyle())
        }
        .padding(16)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var killCriteriaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("KILL CRITERIA")

            Text("Know when to stop.")
                .font(.system(size: 23, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(ink)

            Text("Kindling should help protect you from rationalizing weak evidence after you become emotionally attached to the idea.")
                .font(.system(size: 10))
                .foregroundStyle(secondary)
                .lineSpacing(3)

            VStack(spacing: 0) {
                KillCriteriaRow(
                    title: "Customer interviews",
                    criterion: "< 3 strong signals after 10 interviews",
                    triggered: interviewCount >= 10 && strongSignals < 3,
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                KillCriteriaRow(
                    title: "Pricing",
                    criterion: "< 20% choose $12+",
                    triggered: false,
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                KillCriteriaRow(
                    title: "Purchase intent",
                    criterion: "< 10% strong intent",
                    triggered: purchaseIntent < 3 && waitlistSignups >= 30,
                    ink: ink,
                    secondary: secondary
                )
            }
        }
        .padding(16)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }

    // MARK: - Experiments

    private var experimentsContent: some View {
        VStack(spacing: 10) {
            experimentCard(.interviews)
            experimentCard(.pricing)
            experimentCard(.waitlist)
            experimentCard(.purchaseIntent)
        }
    }

    private func experimentCard(
        _ experiment: ValidationExperiment
    ) -> some View {
        let isOpen = openExperiment == experiment

        return VStack(spacing: 0) {
            Button {
                haptic(.selection)

                withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                    openExperiment = isOpen ? nil : experiment
                }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(experimentColor(experiment))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: experiment.icon)
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(ink)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(experiment.title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(ink)

                        Text(experiment.subtitle)
                            .font(.system(size: 9))
                            .foregroundStyle(secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(ink)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(14)
                .background(paper)
            }
            .buttonStyle(ValidationPressStyle())

            if isOpen {
                Divider().overlay(border)

                experimentDetail(experiment)
                    .padding(14)
                    .background(raisedPaper)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .overlay(
            RoundedRectangle(cornerRadius: 19)
                .stroke(border)
        )
    }

    @ViewBuilder
    private func experimentDetail(
        _ experiment: ValidationExperiment
    ) -> some View {
        switch experiment {
        case .interviews:
            VStack(alignment: .leading, spacing: 12) {
                metricStepper(
                    title: "Interviews completed",
                    value: $interviewCount,
                    range: 0...15,
                    color: blue
                )

                metricStepper(
                    title: "Strong purchase signals",
                    value: $strongSignals,
                    range: 0...15,
                    color: green
                )

                ValidationInsight(
                    title: "Don’t ask if they like the idea.",
                    text: "Ask what they do today, what it costs them, and whether they have already tried to solve it.",
                    ink: ink,
                    secondary: secondary,
                    paper: paper
                )

                experimentTask(
                    id: "interview-script",
                    title: "Generate interview script"
                )

                experimentTask(
                    id: "interview-log",
                    title: "Log interview notes"
                )
            }

        case .pricing:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRICE TO TEST")
                        .font(.system(size: 8, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(secondary)

                    HStack(spacing: 7) {
                        ForEach([8, 12, 16, 20], id: \.self) { price in
                            Button {
                                selectedPrice = price
                                haptic(.selection)
                            } label: {
                                Text("$\(price)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedPrice == price
                                        ? pink
                                        : paper
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(ValidationPressStyle())
                        }
                    }
                }

                metricStepper(
                    title: "Pricing responses",
                    value: $pricingResponses,
                    range: 0...20,
                    color: pink
                )

                ValidationInsight(
                    title: "Behavior beats opinions.",
                    text: "A fake checkout, refundable deposit, or purchase-intent test is stronger evidence than asking “Would you pay $12?”",
                    ink: ink,
                    secondary: secondary,
                    paper: paper
                )

                experimentTask(
                    id: "pricing-page",
                    title: "Create pricing test page"
                )
            }

        case .waitlist:
            VStack(alignment: .leading, spacing: 12) {
                metricStepper(
                    title: "Waitlist signups",
                    value: $waitlistSignups,
                    range: 0...200,
                    color: green
                )

                ValidationInsight(
                    title: "Traffic quality matters.",
                    text: "50 signups from highly relevant customers can be more valuable than 500 generic visitors.",
                    ink: ink,
                    secondary: secondary,
                    paper: paper
                )

                experimentTask(
                    id: "landing-copy",
                    title: "Landing page copy"
                )

                experimentTask(
                    id: "waitlist-channel",
                    title: "Choose first acquisition channel"
                )
            }

        case .purchaseIntent:
            VStack(alignment: .leading, spacing: 12) {
                metricStepper(
                    title: "Strong purchase-intent actions",
                    value: $purchaseIntent,
                    range: 0...50,
                    color: orange
                )

                ValidationInsight(
                    title: "Look for costly signals.",
                    text: "Deposits, booked demos, referrals, preorders, or giving up time are stronger than likes and survey enthusiasm.",
                    ink: ink,
                    secondary: secondary,
                    paper: paper
                )

                experimentTask(
                    id: "intent-test",
                    title: "Design purchase-intent test"
                )
            }
        }
    }

    private func metricStepper(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        color: Color
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 7, weight: .black))
                    .tracking(0.7)
                    .foregroundStyle(secondary)

                Text("\(value.wrappedValue)")
                    .font(.system(size: 27, weight: .black))
                    .foregroundStyle(ink)
            }

            Spacer()

            HStack(spacing: 7) {
                Button {
                    guard value.wrappedValue > range.lowerBound else { return }
                    value.wrappedValue -= 1
                    haptic(.selection)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(ink)
                        .frame(width: 36, height: 36)
                        .background(paper)
                        .clipShape(Circle())
                }
                .buttonStyle(ValidationPressStyle())

                Button {
                    guard value.wrappedValue < range.upperBound else { return }
                    value.wrappedValue += 1
                    haptic(.selection)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(ink)
                        .frame(width: 36, height: 36)
                        .background(color)
                        .clipShape(Circle())
                }
                .buttonStyle(ValidationPressStyle())
            }
        }
        .padding(12)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    private func experimentTask(
        id: String,
        title: String
    ) -> some View {
        Button {
            haptic(.success)

            if completedTasks.contains(id) {
                completedTasks.remove(id)
            } else {
                completedTasks.insert(id)
            }
        } label: {
            HStack {
                Image(
                    systemName:
                        completedTasks.contains(id)
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    completedTasks.contains(id)
                    ? green
                    : secondary
                )

                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(ink)

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(ValidationPressStyle())
    }

    private func experimentColor(
        _ experiment: ValidationExperiment
    ) -> Color {
        switch experiment {
        case .interviews: return blue
        case .pricing: return pink
        case .waitlist: return green
        case .purchaseIntent: return orange
        }
    }

    // MARK: - Evidence

    private var evidenceContent: some View {
        VStack(spacing: 12) {
            evidenceSummary
            evidenceTimeline
            confidenceExplanation
        }
    }

    private var evidenceSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("EVIDENCE LEDGER")

            Text("What does the evidence actually say?")
                .font(.system(size: 23, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(ink)

            HStack(spacing: 7) {
                EvidenceSummaryTile(
                    label: "SUPPORTS",
                    value: "\(supportingEvidence)",
                    color: green,
                    ink: ink
                )

                EvidenceSummaryTile(
                    label: "CONTRADICTS",
                    value: "\(contradictingEvidence)",
                    color: coral,
                    ink: ink
                )

                EvidenceSummaryTile(
                    label: "UNKNOWN",
                    value: "\(unknownEvidence)",
                    color: orange,
                    ink: ink
                )
            }
        }
        .padding(16)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }

    private var supportingEvidence: Int {
        min(8, 1 + strongSignals + (interviewCount >= 5 ? 1 : 0) + (waitlistSignups >= 40 ? 1 : 0))
    }

    private var contradictingEvidence: Int {
        interviewCount >= 10 && strongSignals < 3 ? 3 : 1
    }

    private var unknownEvidence: Int {
        max(1, 7 - supportingEvidence)
    }

    private var evidenceTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("RECENT EVIDENCE")

            VStack(spacing: 0) {
                EvidenceRow(
                    date: "TODAY",
                    title: "\(interviewCount) customer interviews logged",
                    detail: "\(strongSignals) strong purchase signals",
                    color: blue,
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                EvidenceRow(
                    date: "YESTERDAY",
                    title: "Landing page copy completed",
                    detail: "Budget + pantry positioning",
                    color: green,
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                EvidenceRow(
                    date: "3 DAYS",
                    title: "Pricing assumption created",
                    detail: "$12 / month remains unproven",
                    color: pink,
                    ink: ink,
                    secondary: secondary
                )
            }
        }
        .padding(16)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }

    private var confidenceExplanation: some View {
        VStack(alignment: .leading, spacing: 9) {
            eyebrow("✦ KINDLING AI")

            Text("Confidence should rise because of evidence — not because the AI sounds confident.")
                .font(.system(size: 19, weight: .black))
                .tracking(-0.5)
                .foregroundStyle(ink)

            Text("Kindling separates assumptions, observations, and real customer behavior. The score should only move meaningfully when the quality of evidence improves.")
                .font(.system(size: 10))
                .foregroundStyle(secondary)
                .lineSpacing(3)
        }
        .padding(16)
        .background(raisedPaper)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Shared

    private func eyebrow(
        _ text: String
    ) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .black))
            .tracking(1.2)
            .foregroundStyle(secondary)
    }

    private enum HapticKind {
        case selection
        case light
        case medium
        case success
    }

    private func haptic(
        _ kind: HapticKind
    ) {
        switch kind {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Models

enum ValidationTab: String, CaseIterable, Identifiable {
    case overview
    case experiments
    case evidence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .experiments: return "Experiments"
        case .evidence: return "Evidence"
        }
    }
}

enum ValidationDecision {
    case build
    case validate
    case pivot
    case stop
}

enum ValidationExperiment: String, CaseIterable, Identifiable {
    case interviews
    case pricing
    case waitlist
    case purchaseIntent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interviews: return "Customer Interviews"
        case .pricing: return "Pricing Test"
        case .waitlist: return "Waitlist / Landing Page"
        case .purchaseIntent: return "Purchase Intent"
        }
    }

    var subtitle: String {
        switch self {
        case .interviews: return "Do customers actually feel the pain?"
        case .pricing: return "Will people pay enough?"
        case .waitlist: return "Can you attract the right people?"
        case .purchaseIntent: return "Will interest turn into action?"
        }
    }

    var icon: String {
        switch self {
        case .interviews: return "person.2"
        case .pricing: return "dollarsign"
        case .waitlist: return "person.badge.plus"
        case .purchaseIntent: return "cart"
        }
    }
}

// MARK: - Supporting Views

struct DecisionChip: View {
    let title: String
    let active: Bool
    let color: Color
    let ink: Color

    var body: some View {
        Text(title)
            .font(.system(size: 7, weight: .black))
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(active ? color : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        active
                        ? ink.opacity(0.5)
                        : ink.opacity(0.12)
                    )
            )
    }
}

struct ValidationAssumptionRow: View {
    let color: Color
    let title: String
    let status: String
    let impact: String
    let ink: Color
    let secondary: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(ink)

                Text(status)
                    .font(.system(size: 8))
                    .foregroundStyle(secondary)
            }

            Spacer()

            Text(impact.uppercased())
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(secondary)
        }
        .padding(.vertical, 9)
    }
}

struct ValidationProgressTile: View {
    let label: String
    let value: String
    let color: Color
    let ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .tracking(0.6)

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .black))
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, minHeight: 85, alignment: .topLeading)
        .padding(10)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct KillCriteriaRow: View {
    let title: String
    let criterion: String
    let triggered: Bool
    let ink: Color
    let secondary: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(
                systemName:
                    triggered
                    ? "exclamationmark.triangle.fill"
                    : "circle"
            )
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(triggered ? Color.red : secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)

                Text(criterion)
                    .font(.system(size: 8))
                    .foregroundStyle(secondary)
            }

            Spacer()
        }
        .padding(.vertical, 9)
    }
}

struct ValidationInsight: View {
    let title: String
    let text: String
    let ink: Color
    let secondary: Color
    let paper: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✦ KINDLING AI")
                .font(.system(size: 7, weight: .black))
                .tracking(0.8)
                .foregroundStyle(secondary)

            Text(title)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(ink)

            Text(text)
                .font(.system(size: 9))
                .foregroundStyle(secondary)
                .lineSpacing(3)
        }
        .padding(12)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EvidenceSummaryTile: View {
    let label: String
    let value: String
    let color: Color
    let ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 7, weight: .black))

            Spacer()

            Text(value)
                .font(.system(size: 22, weight: .black))
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .padding(10)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EvidenceRow: View {
    let date: String
    let title: String
    let detail: String
    let color: Color
    let ink: Color
    let secondary: Color

    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(date)
                    .font(.system(size: 7, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(secondary)

                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)

                Text(detail)
                    .font(.system(size: 8))
                    .foregroundStyle(secondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }
}

struct ValidationPressStyle: ButtonStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed
                ? 0.975
                : 1
            )
            .opacity(
                configuration.isPressed
                ? 0.88
                : 1
            )
            .animation(
                .easeOut(duration: 0.14),
                value: configuration.isPressed
            )
    }
}

#Preview {
    ValidationWorkspaceView()
}
