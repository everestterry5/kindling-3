import SwiftUI
import UIKit

struct AppFlowOverviewView: View {
    @EnvironmentObject private var store: KindlingStore
    @EnvironmentObject private var router: KindlingRouter

    let onRestartOnboarding: () -> Void

    private let background =
        Color(red: 0.982, green: 0.965, blue: 0.925)

    private let paper =
        Color(red: 0.998, green: 0.992, blue: 0.975)

    private let ink =
        Color(red: 0.075, green: 0.075, blue: 0.065)

    private let secondary =
        Color(red: 0.25, green: 0.24, blue: 0.21)

    private let orange =
        Color(red: 1.00, green: 0.60, blue: 0.03)

    private let blue =
        Color(red: 0.43, green: 0.68, blue: 0.96)

    private let green =
        Color(red: 0.63, green: 0.84, blue: 0.36)

    private let pink =
        Color(red: 0.92, green: 0.65, blue: 0.75)

    private let coral =
        Color(red: 0.98, green: 0.42, blue: 0.32)

    private var idea: BusinessIdea? {
        store.ideas.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                topBar
                header
                singleFlow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 34)
        }
        .background(background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
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
            }

            Spacer()

            Text("APP FLOW")
                .font(.system(size: 8, weight: .black))
                .tracking(1.5)
                .foregroundStyle(secondary)
        }
        .padding(.top, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ONE FLOW · ALL SCREENS")
                .font(.system(size: 8, weight: .black))
                .tracking(1.4)
                .foregroundStyle(secondary)

            Text("Everything in\none place.")
                .font(.system(size: 39, weight: .black))
                .tracking(-2)
                .lineSpacing(-5)
                .foregroundStyle(ink)

            Text(
                "Use this single screen while we build. Tap any page to jump straight there."
            )
            .font(.system(size: 11))
            .foregroundStyle(secondary)
            .lineSpacing(4)
        }
    }

    private var singleFlow: some View {
        VStack(spacing: 0) {
            flowRow(
                number: "01",
                title: "Welcome / Login",
                subtitle: "First-time entry",
                color: paper,
                action: onRestartOnboarding
            )

            connector

            flowRow(
                number: "02",
                title: "Founder Questionnaire",
                subtitle: "10-question setup",
                color: orange,
                action: onRestartOnboarding
            )

            connector

            flowRow(
                number: "03",
                title: "Home",
                subtitle: "Idea archive + priorities",
                color: green,
                action: {
                    router.popToRoot()
                }
            )

            connector

            flowRow(
                number: "04",
                title: "Log New Idea",
                subtitle: "Capture + shape",
                color: orange,
                action: {
                    router.push(.logIdea)
                }
            )

            connector

            flowRow(
                number: "05",
                title: "Idea Report",
                subtitle: "Score + market reality",
                color: coral,
                action: ideaAction { .report($0) }
            )

            connector

            flowRow(
                number: "06",
                title: "Validation",
                subtitle: "Assumptions → evidence",
                color: green,
                action: ideaAction { .validation($0) }
            )

            connector

            flowRow(
                number: "07",
                title: "Business Plan",
                subtitle: "Evidence → execution",
                color: pink,
                action: ideaAction { .businessPlan($0) }
            )

            connector

            flowRow(
                number: "08",
                title: "Pitch Deck",
                subtitle: "Plan → investor story",
                color: blue,
                action: ideaAction { .pitchDeck($0) }
            )

            connector

            flowRow(
                number: "09",
                title: "Portfolio Ranking",
                subtitle: "Where should I focus?",
                color: orange,
                action: {
                    router.push(.portfolio)
                }
            )

            connector

            flowRow(
                number: "10",
                title: "Founder Brief",
                subtitle: "What matters this week?",
                color: blue,
                action: {
                    router.push(.founderBrief)
                }
            )

            connector

            flowRow(
                number: "11",
                title: "What Changed",
                subtitle: "Market updates",
                color: green,
                action: {
                    router.push(.whatChanged)
                }
            )

            connector

            flowRow(
                number: "12",
                title: "Kindling AI",
                subtitle: "Context-aware guidance",
                color: ink,
                inverted: true,
                action: ideaAction { .ai($0) }
            )
        }
        .padding(12)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.08))
        )
    }

    private func flowRow(
        number: String,
        title: String,
        subtitle: String,
        color: Color,
        inverted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()
            action()
        } label: {
            HStack(spacing: 13) {
                Text(number)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(
                        inverted ? paper : ink
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(
                                inverted
                                ? paper.opacity(0.35)
                                : ink.opacity(0.18)
                            )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .black))

                    Text(subtitle)
                        .font(.system(size: 9))
                        .opacity(0.70)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .black))
            }
            .foregroundStyle(
                inverted ? paper : ink
            )
            .padding(14)
            .background(color)
            .clipShape(
                RoundedRectangle(cornerRadius: 15)
            )
        }
        .buttonStyle(.plain)
    }

    private var connector: some View {
        Rectangle()
            .fill(ink.opacity(0.20))
            .frame(width: 1, height: 15)
    }

    private func ideaAction(
        _ route: @escaping (UUID) -> KindlingRoute
    ) -> () -> Void {
        {
            guard let id = idea?.id else { return }
            router.push(route(id))
        }
    }
}

#Preview {
    NavigationStack {
        AppFlowOverviewView(
            onRestartOnboarding: {}
        )
        .environmentObject(KindlingStore())
        .environmentObject(KindlingRouter())
    }
}
