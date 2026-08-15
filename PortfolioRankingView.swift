import SwiftUI
import UIKit

struct PortfolioRankingView: View {
    @EnvironmentObject private var store: KindlingStore
    @EnvironmentObject private var router: KindlingRouter
    @AppStorage("kindlingDarkMode") private var isDarkMode = false

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

    private var rankings: [PortfolioRankedIdea] {
        store.ideas
            .map(PortfolioRankedIdea.make)
            .sorted {
                if $0.priorityScore == $1.priorityScore {
                    return $0.idea.viabilityScore > $1.idea.viabilityScore
                }

                return $0.priorityScore > $1.priorityScore
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let first = rankings.first {
                    focusRecommendation(first)
                }

                rankingExplanation

                VStack(spacing: 12) {
                    ForEach(
                        Array(rankings.enumerated()),
                        id: \.element.idea.id
                    ) { index, ranked in
                        rankingCard(
                            ranked,
                            rank: index + 1
                        )
                    }
                }

                methodology
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .background(background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(ink)
                        .frame(width: 40, height: 40)
                        .background(paper)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(border)
                        )
                }
                .buttonStyle(PortfolioPressStyle())

                Spacer()

                Text("PORTFOLIO")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(secondary)
            }

            Text("Where should\nyou focus?")
                .font(.system(size: 40, weight: .black))
                .tracking(-1.8)
                .foregroundStyle(ink)

            Text("Kindling ranks your ideas by opportunity, founder fit, evidence, momentum, competition, and effort — then tells you where your next 10 hours are most valuable.")
                .font(.system(size: 12))
                .foregroundStyle(secondary)
                .lineSpacing(4)
        }
    }

    private func focusRecommendation(
        _ ranked: PortfolioRankedIdea
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("YOUR NEXT 10 HOURS")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.3)

                Spacer()

                Text("FOCUS NOW")
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.9)
                    .padding(.horizontal, 9)
                    .frame(height: 27)
                    .background(ink.opacity(isDarkMode ? 0.13 : 0.08))
                    .clipShape(Capsule())
            }

            Text(ranked.idea.title)
                .font(.system(size: 28, weight: .black))
                .tracking(-1)
                .lineLimit(2)

            Text(ranked.recommendation)
                .font(.system(size: 12, weight: .semibold))
                .lineSpacing(4)

            Divider()
                .overlay(ink.opacity(0.15))

            HStack(spacing: 8) {
                focusStat(
                    label: "PRIORITY",
                    value: "\(ranked.priorityScore)"
                )

                focusStat(
                    label: "VIABILITY",
                    value: "\(ranked.idea.viabilityScore)"
                )

                focusStat(
                    label: "VALIDATION",
                    value: "\(ranked.idea.validationProgress)%"
                )
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                openNextMove(for: ranked.idea)
            } label: {
                HStack {
                    Text(ranked.actionTitle.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .black))
                }
                .foregroundStyle(ink)
                .padding(.horizontal, 15)
                .frame(height: 48)
                .background(
                    Color.white.opacity(
                        isDarkMode ? 0.10 : 0.32
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
            }
            .buttonStyle(PortfolioPressStyle())
        }
        .foregroundStyle(ink)
        .padding(17)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func focusStat(
        label: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .tracking(0.9)
                .opacity(0.65)

            Text(value)
                .font(.system(size: 18, weight: .black))
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private var rankingExplanation: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("RANKED PORTFOLIO")
                .font(.system(size: 8, weight: .black))
                .tracking(1.3)
                .foregroundStyle(secondary)

            Text("Not every good idea deserves your time right now.")
                .font(.system(size: 22, weight: .black))
                .tracking(-0.6)
                .foregroundStyle(ink)

            Text("A high rank means the idea has a strong combination of upside, founder fit, evidence, and realistic execution — not simply the highest market score.")
                .font(.system(size: 11))
                .foregroundStyle(secondary)
                .lineSpacing(4)
        }
        .padding(.top, 4)
    }

    private func rankingCard(
        _ ranked: PortfolioRankedIdea,
        rank: Int
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()

            router.push(.report(ranked.idea.id))
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", rank))
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(
                            accent(for: ranked.idea.accent)
                        )
                        .frame(width: 34, alignment: .leading)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(ranked.idea.title)
                            .font(.system(size: 18, weight: .black))
                            .tracking(-0.35)
                            .foregroundStyle(ink)
                            .multilineTextAlignment(.leading)

                        Text(ranked.statusLabel.uppercased())
                            .font(.system(size: 7, weight: .black))
                            .tracking(1)
                            .foregroundStyle(secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(ranked.priorityScore)")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(ink)

                        Text("PRIORITY")
                            .font(.system(size: 6, weight: .black))
                            .tracking(0.8)
                            .foregroundStyle(secondary)
                    }
                }

                Text(ranked.why)
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    portfolioChip(
                        label: "FIT",
                        value: "\(ranked.idea.founderFit)"
                    )

                    portfolioChip(
                        label: "EVIDENCE",
                        value: "\(ranked.idea.validationProgress)%"
                    )

                    portfolioChip(
                        label: "EFFORT",
                        value: ranked.effortLabel
                    )
                }

                HStack {
                    Text(ranked.actionTitle)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(ink)

                    Spacer()

                    Text("OPEN IDEA")
                        .font(.system(size: 7, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(secondary)
                }
            }
            .padding(16)
            .background(
                rank == 1
                ? raisedPaper
                : paper
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 22)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        rank == 1
                        ? accent(for: ranked.idea.accent)
                            .opacity(0.48)
                        : border
                    )
            )
        }
        .buttonStyle(PortfolioPressStyle())
    }

    private func portfolioChip(
        label: String,
        value: String
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 6, weight: .black))
                .tracking(0.6)
                .foregroundStyle(secondary)

            Text(value)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(ink)
        }
        .padding(.horizontal, 8)
        .frame(height: 25)
        .background(raisedPaper)
        .clipShape(Capsule())
    }

    private var methodology: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW KINDLING RANKS")
                .font(.system(size: 8, weight: .black))
                .tracking(1.3)
                .foregroundStyle(secondary)

            Text("Priority is not another viability score.")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(ink)

            Text("It answers a different question: given your current ideas and constraints, where is your attention most likely to create useful evidence or progress right now?")
                .font(.system(size: 11))
                .foregroundStyle(secondary)
                .lineSpacing(4)

            HStack(spacing: 6) {
                methodologyPill("Opportunity")
                methodologyPill("Founder fit")
                methodologyPill("Evidence")
            }

            HStack(spacing: 6) {
                methodologyPill("Momentum")
                methodologyPill("Competition")
                methodologyPill("Effort")
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

    private func methodologyPill(
        _ title: String
    ) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(ink)
            .padding(.horizontal, 9)
            .frame(height: 28)
            .background(raisedPaper)
            .clipShape(Capsule())
    }

    private func openNextMove(
        for idea: BusinessIdea
    ) {
        if idea.validationProgress < 45 {
            router.push(.validation(idea.id))
            return
        }

        if idea.businessPlanProgress < 65 {
            router.push(.businessPlan(idea.id))
            return
        }

        router.push(.report(idea.id))
    }

    private func accent(
        for accent: IdeaAccent
    ) -> Color {
        switch accent {
        case .coral:
            return coral
        case .blue:
            return blue
        case .orange:
            return orange
        case .green:
            return green
        case .pink:
            return pink
        }
    }
}

private struct PortfolioRankedIdea {
    let idea: BusinessIdea
    let priorityScore: Int
    let marketScore: Double
    let competitionScore: Double
    let easeScore: Double

    static func make(
        _ idea: BusinessIdea
    ) -> PortfolioRankedIdea {
        let marketScore: Double

        switch idea.marketDirection {
        case "↑":
            marketScore = 100
        case "↓":
            marketScore = 30
        default:
            marketScore = 65
        }

        let competitionScore = max(
            0,
            min(
                100,
                100 - Double(idea.competitorCount) * 2.2
            )
        )

        let easeScore = max(
            0,
            min(
                100,
                100 - Double(idea.entryDifficulty)
            )
        )

        var raw =
            Double(idea.viabilityScore) * 0.30
            + Double(idea.founderFit) * 0.22
            + Double(idea.validationProgress) * 0.17
            + marketScore * 0.11
            + competitionScore * 0.08
            + easeScore * 0.09
            + Double(idea.businessPlanProgress) * 0.03

        if idea.decision == .pause {
            raw *= 0.55
        }

        return PortfolioRankedIdea(
            idea: idea,
            priorityScore: Int(raw.rounded()),
            marketScore: marketScore,
            competitionScore: competitionScore,
            easeScore: easeScore
        )
    }

    var statusLabel: String {
        if idea.decision == .pause {
            return "Paused · \(idea.lifecycle.rawValue)"
        }

        return idea.lifecycle.rawValue
    }

    var effortLabel: String {
        if idea.entryDifficulty <= 35 {
            return "Low"
        }

        if idea.entryDifficulty <= 60 {
            return "Med"
        }

        return "High"
    }

    var actionTitle: String {
        if idea.validationProgress < 45 {
            return "Strengthen validation"
        }

        if idea.businessPlanProgress < 65 {
            return "Turn evidence into a plan"
        }

        return "Review the decision"
    }

    var recommendation: String {
        if idea.validationProgress < 45 {
            return "This idea has the strongest overall mix, but the biggest remaining uncertainty is still evidence. Spend the time proving purchase intent before adding product scope."
        }

        if idea.businessPlanProgress < 65 {
            return "The opportunity is strong enough to keep moving. Use the next block of time to convert what you have learned into a tighter execution plan."
        }

        return "This is currently your strongest portfolio bet. Review the latest evidence, confirm the decision, and move the next milestone forward."
    }

    var why: String {
        var strengths: [String] = []
        var constraints: [String] = []

        if idea.viabilityScore >= 75 {
            strengths.append("strong opportunity")
        }

        if idea.founderFit >= 78 {
            strengths.append("high founder fit")
        }

        if marketScore >= 90 {
            strengths.append("positive momentum")
        }

        if idea.validationProgress >= 45 {
            strengths.append("meaningful evidence")
        }

        if idea.validationProgress < 30 {
            constraints.append("validation is still thin")
        }

        if idea.entryDifficulty >= 65 {
            constraints.append("execution is demanding")
        }

        if idea.competitorCount >= 28 {
            constraints.append("competition is crowded")
        }

        if idea.founderFit < 65 {
            constraints.append("founder fit is weaker")
        }

        let strengthText =
            strengths.isEmpty
            ? "a balanced profile"
            : strengths.prefix(2).joined(separator: " + ")

        if let firstConstraint = constraints.first {
            return "Ranks here because of \(strengthText), but \(firstConstraint)."
        }

        return "Ranks here because of \(strengthText) with no major portfolio-level blocker right now."
    }
}

private struct PortfolioPressStyle: ButtonStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed
                ? 0.978
                : 1
            )
            .opacity(
                configuration.isPressed
                ? 0.90
                : 1
            )
            .animation(
                .easeOut(duration: 0.14),
                value: configuration.isPressed
            )
    }
}

#Preview {
    NavigationStack {
        PortfolioRankingView()
            .environmentObject(KindlingStore())
            .environmentObject(KindlingRouter())
    }
}
