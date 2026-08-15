import SwiftUI

struct KindlingRootView: View {
    @StateObject private var store = KindlingStore()
    @StateObject private var router = KindlingRouter()

    @AppStorage("hasCompletedKindlingOnboarding")
    private var hasCompletedOnboarding = false

    @State private var isShowingQuestionnaire = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                NavigationStack(path: $router.path) {
                    HomeView()
                        .navigationDestination(for: KindlingRoute.self) { route in
                            destination(for: route)
                        }
                }
            } else if isShowingQuestionnaire {
                WelcomeQuestionnaireView {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        hasCompletedOnboarding = true
                        isShowingQuestionnaire = false
                    }
                }
            } else {
                KindlingWelcomeView(
                    onGetStarted: {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            isShowingQuestionnaire = true
                        }
                    },
                    onLogin: {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            hasCompletedOnboarding = true
                        }
                    }
                )
            }
        }
        .environmentObject(store)
        .environmentObject(router)
    }

    @ViewBuilder
    private func destination(
        for route: KindlingRoute
    ) -> some View {
        switch route {
        case .logIdea:
            LogIdeaView()

        case .report(let id):
            ideaDestination(id) { idea in
                IdeaReportView(idea: idea)
            }

        case .validation(let id):
            ideaDestination(id) { idea in
                ValidationWorkspaceView()
            }

        case .businessPlan(let id):
            ideaDestination(id) { idea in
                BusinessPlanView(idea: idea)
            }

        case .pitchDeck(let id):
            ideaDestination(id) { idea in
                PitchDeckPreviewView(
                    idea: idea,
                    executiveSummary:
                        "\(idea.title) is designed around a focused customer problem with a clear path from validation to execution.",
                    targetCustomer:
                        "Primary customer: \(idea.customer).\n• Feels the problem frequently\n• Is actively looking for a better solution",
                    positioning:
                        idea.problem.isEmpty
                        ? "Own one measurable customer outcome."
                        : "Solve this clearly: \(idea.problem)",
                    revenueModel:
                        idea.businessModel.isEmpty
                        ? "Use the simplest model that matches recurring value."
                        : "Primary model: \(idea.businessModel)",
                    goToMarket:
                        "Start narrow with direct conversations, focused communities, partnerships, and high-intent content.",
                    operations:
                        "Keep the first version lean and build only what proves the highest-risk assumptions.",
                    financialPlan:
                        "Treat cost, pricing, acquisition, margin, and break-even as assumptions until validated.",
                    risks:
                        "The largest risk is committing resources before demand and willingness to pay are proven.",
                    milestones:
                        "30 days: validate the problem.\n60 days: test the offer.\n90 days: build only if evidence clears the kill criteria.",
                    planProgress: idea.businessPlanProgress
                )
            }

        case .ai(let id):
            ideaDestination(id) { idea in
                KindlingAIView()
            }

        case .portfolio:
            PortfolioRankingView()

        case .founderBrief:
            FounderBriefView()

        case .whatChanged:
            WhatChangedFeedView(
                updates: WhatChangedItem.prototypeUpdates(
                    for: store.ideas
                )
            )

        case .flowOverview:
            AppFlowOverviewView(
                onRestartOnboarding: restartOnboarding
            )
        }
    }

    @ViewBuilder
    private func ideaDestination<Content: View>(
        _ id: UUID,
        @ViewBuilder content: (BusinessIdea) -> Content
    ) -> some View {
        if let idea = store.idea(withID: id) {
            content(idea)
        } else {
            VStack(spacing: 14) {
                Text("This idea is no longer available.")
                    .font(.headline)

                Button("Return Home") {
                    router.popToRoot()
                }
            }
            .padding(24)
        }
    }

    private func restartOnboarding() {
        router.popToRoot()

        withAnimation(.easeInOut(duration: 0.28)) {
            hasCompletedOnboarding = false
            isShowingQuestionnaire = false
        }
    }
}

#Preview {
    KindlingRootView()
}
