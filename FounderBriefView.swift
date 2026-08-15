import SwiftUI
import UIKit

struct FounderBriefView: View {
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

    private var coral: Color {
        isDarkMode
        ? Color(red: 0.63, green: 0.22, blue: 0.20)
        : Color(red: 0.98, green: 0.38, blue: 0.33)
    }

    private var rankedIdeas: [BusinessIdea] {
        store.ideas.sorted {
            priorityScore($0) > priorityScore($1)
        }
    }

    private var leader: BusinessIdea? {
        rankedIdeas.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                executiveSummary
                whatChanged
                whatMoved
                biggestThing
                thisWeek
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
                        .overlay(Circle().stroke(border))
                }
                .buttonStyle(FounderBriefPressStyle())

                Spacer()

                Text("WEEKLY FOUNDER BRIEF")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(secondary)
            }

            Text("Your week,\ndistilled.")
                .font(.system(size: 40, weight: .black))
                .tracking(-1.8)
                .foregroundStyle(ink)

            Text("One view of what changed, what moved, and what deserves your attention next.")
                .font(.system(size: 12))
                .foregroundStyle(secondary)
                .lineSpacing(4)
        }
    }

    private var executiveSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THIS WEEK IN KINDLING")
                .font(.system(size: 8, weight: .black))
                .tracking(1.3)

            if let leader {
                Text("\(leader.title) is your strongest current bet.")
                    .font(.system(size: 26, weight: .black))
                    .tracking(-0.8)

                Text(summaryText(for: leader))
                    .font(.system(size: 12, weight: .semibold))
                    .lineSpacing(4)
            } else {
                Text("Add an idea to start your weekly brief.")
                    .font(.system(size: 24, weight: .black))
            }
        }
        .foregroundStyle(ink)
        .padding(17)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var whatChanged: some View {
        section(kicker: "WHAT CHANGED", title: "Signals worth knowing.") {
            VStack(spacing: 0) {
                briefRow(icon: "arrow.up.right", color: green, title: "Demand signal strengthened", subtitle: leader?.title ?? "Your leading idea", trailing: "+2")
                Divider().overlay(border)
                briefRow(icon: "person.2.fill", color: coral, title: "Competition increased", subtitle: rankedIdeas.dropFirst().first?.title ?? "Portfolio", trailing: "-3")
                Divider().overlay(border)
                briefRow(icon: "sparkles", color: blue, title: "A narrower niche looks more attractive", subtitle: rankedIdeas.count > 2 ? rankedIdeas[2].title : "Portfolio", trailing: "NEW")
            }
            .background(paper)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(border))
        }
    }

    private var whatMoved: some View {
        section(kicker: "WHAT MOVED", title: "Portfolio changes.") {
            VStack(spacing: 10) {
                ForEach(Array(rankedIdeas.prefix(3).enumerated()), id: \.element.id) { index, idea in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(index == 0 ? orange : ink)
                            .frame(width: 26, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(idea.title)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(ink)
                            Text(rankReason(for: idea))
                                .font(.system(size: 9))
                                .foregroundStyle(secondary)
                        }

                        Spacer()

                        Text("\(Int(priorityScore(idea).rounded()))")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(ink)
                    }
                    .padding(14)
                    .background(paper)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border))
                }
            }
        }
    }

    private var biggestThing: some View {
        section(kicker: "WHAT MATTERS", title: "The biggest unresolved issue.") {
            VStack(alignment: .leading, spacing: 10) {
                Text(biggestRiskTitle)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(ink)

                Text(biggestRiskBody)
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
                    .lineSpacing(4)

                Button {
                    guard let leader else { return }
                    router.push(.validation(leader.id))
                } label: {
                    HStack {
                        Text("OPEN VALIDATION")
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.6)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(ink)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(raisedPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(FounderBriefPressStyle())
                .disabled(leader == nil)
            }
            .padding(16)
            .background(paper)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(border))
        }
    }

    private var thisWeek: some View {
        section(kicker: "YOUR WEEK", title: "Three moves. No busywork.") {
            VStack(spacing: 10) {
                actionRow(number: "01", title: firstActionTitle, detail: firstActionDetail)
                actionRow(number: "02", title: secondActionTitle, detail: secondActionDetail)
                actionRow(number: "03", title: "Leave one idea alone", detail: "Protect focus. Do not advance every idea at the same time.")
            }
        }
    }

    private func section<Content: View>(
        kicker: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(kicker)
                .font(.system(size: 8, weight: .black))
                .tracking(1.3)
                .foregroundStyle(secondary)
            Text(title)
                .font(.system(size: 23, weight: .black))
                .tracking(-0.6)
                .foregroundStyle(ink)
            content()
        }
    }

    private func briefRow(icon: String, color: Color, title: String, subtitle: String, trailing: String) -> some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(ink)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(ink)
                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundStyle(secondary)
            }
            Spacer()
            Text(trailing)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(ink)
        }
        .padding(13)
    }

    private func actionRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(orange)
                .frame(width: 28, alignment: .leading)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(ink)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(secondary)
                    .lineSpacing(3)
            }
            Spacer()
        }
        .padding(15)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(border))
    }

    private func priorityScore(_ idea: BusinessIdea) -> Double {
        let momentum: Double
        switch idea.marketDirection {
        case "↑": momentum = 100
        case "↓": momentum = 30
        default: momentum = 65
        }

        let competition = max(0, min(100, 100 - Double(idea.competitorCount) * 2.2))
        let ease = max(0, min(100, 100 - Double(idea.entryDifficulty)))

        return Double(idea.viabilityScore) * 0.30
            + Double(idea.founderFit) * 0.22
            + Double(idea.validationProgress) * 0.17
            + momentum * 0.11
            + competition * 0.08
            + ease * 0.09
            + Double(idea.businessPlanProgress) * 0.03
    }

    private func rankReason(for idea: BusinessIdea) -> String {
        if idea.validationProgress < 30 { return "Strong upside, but evidence is still thin." }
        if idea.founderFit >= 80 { return "High fit and solid opportunity." }
        if idea.entryDifficulty >= 65 { return "Promising, but execution is demanding." }
        return "Balanced opportunity with manageable next steps."
    }

    private func summaryText(for idea: BusinessIdea) -> String {
        if idea.validationProgress < 45 {
            return "The market picture is encouraging, but validation still trails the opportunity. The best use of your week is proving purchase intent — not adding product scope."
        }
        return "The idea has enough evidence to keep moving. Your week should focus on converting what you know into a tighter plan and next milestone."
    }

    private var biggestRiskTitle: String {
        guard let leader else { return "Not enough information yet." }
        if leader.validationProgress < 45 { return "You still know more about the market than the buyer." }
        if leader.entryDifficulty >= 65 { return "Execution is becoming the real constraint." }
        return "Focus is now the main risk."
    }

    private var biggestRiskBody: String {
        guard let leader else { return "Add and analyze an idea to generate a founder brief." }
        if leader.validationProgress < 45 {
            return "Market demand is useful, but it cannot substitute for direct evidence that the right customer will pay. That is the biggest gap in the portfolio right now."
        }
        if leader.entryDifficulty >= 65 {
            return "The opportunity remains attractive, but complexity can consume time quickly. Keep the next milestone narrow and measurable."
        }
        return "The portfolio has multiple reasonable options. The risk is splitting attention across all of them instead of creating meaningful evidence in one."
    }

    private var firstActionTitle: String {
        guard let leader else { return "Add your first idea" }
        return leader.validationProgress < 45 ? "Run 5 purchase-intent conversations" : "Move \(leader.title) to its next milestone"
    }

    private var firstActionDetail: String {
        guard let leader else { return "Capture an idea and let Kindling build the first report." }
        return leader.validationProgress < 45
        ? "Ask about actual behavior, current workarounds, and willingness to pay. Avoid asking whether people simply like the idea."
        : "Use the existing evidence to advance the plan without expanding scope."
    }

    private var secondActionTitle: String {
        rankedIdeas.count > 1 ? "Tighten \(rankedIdeas[1].title)" : "Review the next strongest idea"
    }

    private var secondActionDetail: String {
        rankedIdeas.count > 1
        ? "Clarify the positioning or biggest unknown, but keep it secondary to the portfolio leader."
        : "Use the ranking view to decide what deserves attention after the current focus."
    }
}

private struct FounderBriefPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.978 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        FounderBriefView()
            .environmentObject(KindlingStore())
            .environmentObject(KindlingRouter())
    }
}
