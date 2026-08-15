import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage("kindlingDarkMode") private var isDarkMode = false
    @EnvironmentObject private var store: KindlingStore
    @EnvironmentObject private var router: KindlingRouter

    @State private var selectedIdeaIndex = 0
    @State private var selectedMarketUpdate: WhatChangedItem?
    @State private var showAllMarketUpdates = false

    // MARK: - Kindling palette

    private var background: Color {
        isDarkMode
        ? Color(red: 0.055, green: 0.053, blue: 0.049)
        : Color(red: 0.982, green: 0.965, blue: 0.925)
    }

    private var paper: Color {
        isDarkMode
        ? Color(red: 0.095, green: 0.091, blue: 0.084)
        : Color(red: 0.998, green: 0.992, blue: 0.975)
    }

    private var raisedPaper: Color {
        isDarkMode
        ? Color(red: 0.125, green: 0.119, blue: 0.110)
        : Color(red: 0.955, green: 0.930, blue: 0.875)
    }

    private var ink: Color {
        isDarkMode
        ? Color(red: 0.955, green: 0.945, blue: 0.920)
        : Color(red: 0.075, green: 0.075, blue: 0.065)
    }

    private var secondaryText: Color {
        isDarkMode
        ? Color(red: 0.72, green: 0.69, blue: 0.64)
        : Color(red: 0.25, green: 0.24, blue: 0.21)
    }

    private var line: Color {
        isDarkMode
        ? Color.white.opacity(0.14)
        : Color.black.opacity(0.18)
    }

    private var orange: Color {
        isDarkMode
        ? Color(red: 0.70, green: 0.43, blue: 0.04)
        : Color(red: 1.00, green: 0.60, blue: 0.03)
    }

    private var blue: Color {
        isDarkMode
        ? Color(red: 0.23, green: 0.43, blue: 0.70)
        : Color(red: 0.43, green: 0.68, blue: 0.96)
    }

    private var green: Color {
        isDarkMode
        ? Color(red: 0.23, green: 0.48, blue: 0.27)
        : Color(red: 0.63, green: 0.84, blue: 0.36)
    }

    private var pink: Color {
        isDarkMode
        ? Color(red: 0.58, green: 0.32, blue: 0.43)
        : Color(red: 0.92, green: 0.65, blue: 0.75)
    }

    private var coral: Color {
        isDarkMode
        ? Color(red: 0.66, green: 0.27, blue: 0.22)
        : Color(red: 0.98, green: 0.42, blue: 0.32)
    }

    private var yellow: Color {
        isDarkMode
        ? Color(red: 0.68, green: 0.59, blue: 0.06)
        : Color(red: 0.98, green: 0.88, blue: 0.24)
    }

    private var ideas: [HomeIdea] {
        store.ideas.map { idea in
            HomeIdea(
                sourceID: idea.id,
                category: idea.category.uppercased(),
                title: idea.title,
                score: idea.viabilityScore,
                market: idea.marketDirection,
                fit: idea.founderFit,
                entry: idea.entryDifficulty,
                status: lifecycleStatus(for: idea),
                detail: lifecycleDetail(for: idea),
                color: accentColor(for: idea.accent)
            )
        }
    }

    private var selectedBusinessIdea: BusinessIdea? {
        guard !store.ideas.isEmpty else { return nil }
        let safeIndex = min(selectedIdeaIndex, store.ideas.count - 1)
        return store.ideas[safeIndex]
    }

    private var marketUpdates: [WhatChangedItem] {
        WhatChangedItem.prototypeUpdates(for: store.ideas)
    }

    private var portfolioLeader: BusinessIdea? {
        store.ideas.max {
            portfolioPreviewScore($0) < portfolioPreviewScore($1)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                topBar
                hero
                activeFiles
                focusDesk
                nextBestAction
                whatChanged
                aiStrip
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 34)
        }
        .background(
            ZStack {
                background

                LinearGradient(
                    colors: [
                        Color.white.opacity(isDarkMode ? 0.00 : 0.20),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(item: $selectedMarketUpdate) { update in
            WhatChangedDetailView(update: update)
                .environmentObject(store)
                .environmentObject(router)
        }
        .sheet(isPresented: $showAllMarketUpdates) {
            WhatChangedFeedView(updates: marketUpdates)
                .environmentObject(store)
                .environmentObject(router)
        }
    }

    // MARK: - Header

    private var topBar: some View {
        HStack(spacing: 12) {
            Text("KINDLING")
                .font(.system(size: 16, weight: .black))
                .tracking(2.5)
                .foregroundStyle(ink)

            Text("IDEA ARCHIVE")
                .font(.system(size: 7, weight: .black))
                .tracking(1.1)
                .foregroundStyle(secondaryText)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .overlay(
                    Capsule()
                        .stroke(line, lineWidth: 1)
                )

            Spacer()

            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.easeInOut(duration: 0.22)) {
                    isDarkMode.toggle()
                }
            } label: {
                Image(systemName: isDarkMode ? "sun.max" : "moon")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(HomePressStyle())

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                router.push(.flowOverview)
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(HomePressStyle())

            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(HomePressStyle())
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("TODAY / YOUR DESK")
                .font(.system(size: 8, weight: .black))
                .tracking(1.6)
                .foregroundStyle(secondaryText)
                .frame(maxWidth: .infinity)

            Image("KindlingTagline")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(maxWidth: 330)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel("Never let a good idea go cold")
                .padding(.vertical, 4)

            HStack(alignment: .bottom, spacing: 14) {
                Text("Capture the spark. Test the market. Keep only what earns your attention.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryText)
                    .lineSpacing(4)
                    .frame(maxWidth: 245, alignment: .leading)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    router.push(.logIdea)
                } label: {
                    ZStack {
                        Circle()
                            .fill(ink)
                            .frame(width: 58, height: 58)

                        Image(systemName: "plus")
                            .font(.system(size: 21, weight: .black))
                            .foregroundStyle(background)
                    }
                }
                .buttonStyle(HomePressStyle())
            }

            Rectangle()
                .fill(ink)
                .frame(height: 2)
                .padding(.top, 2)
        }
    }

    // MARK: - Active files

    private var activeFiles: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                index: "01",
                eyebrow: "ACTIVE FILES",
                title: "Pick up where you left off.",
                action: "\(String(format: "%02d", selectedIdeaIndex + 1)) / \(String(format: "%02d", max(ideas.count, 1)))"
            )

            if ideas.isEmpty {
                emptyArchive
            } else {
                HomeHorizontalCarousel(
                    ideas: ideas,
                    selectedIndex: $selectedIdeaIndex,
                    ink: ink,
                    secondary: secondaryText,
                    line: line,
                    paper: paper,
                    onOpen: { id in
                        router.push(.report(id))
                    }
                )
                .frame(height: 340)

                Text("SWIPE THE FILES · TAP TO OPEN")
                    .font(.system(size: 7, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var emptyArchive: some View {
        Button {
            router.push(.logIdea)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "folder")
                        .font(.system(size: 27, weight: .black))

                    Spacer()

                    Text("EMPTY")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)
                }

                Spacer()

                Text("Your first idea\nstarts the archive.")
                    .font(.system(size: 28, weight: .black))
                    .tracking(-1)
                    .multilineTextAlignment(.leading)

                Text("LOG AN IDEA  →")
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.8)
            }
            .foregroundStyle(ink)
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 245, alignment: .leading)
            .background(yellow)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(HomePressStyle())
    }

    // MARK: - Focus desk

    private var focusDesk: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                index: "02",
                eyebrow: "FOCUS DESK",
                title: "Two things worth opening.",
                action: nil
            )

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                router.push(.portfolio)
            } label: {
                HStack(alignment: .top, spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PORTFOLIO / PRIORITY")
                            .font(.system(size: 8, weight: .black))
                            .tracking(1.15)

                        Text(portfolioHeadline)
                            .font(.system(size: 27, weight: .black))
                            .tracking(-1.0)
                            .lineSpacing(-3)
                            .multilineTextAlignment(.leading)

                        Text(portfolioDetail)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ink.opacity(0.72))
                            .lineSpacing(3)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Text("OPEN RANKING  →")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.8)
                    }

                    Spacer(minLength: 4)

                    ZStack {
                        Circle()
                            .fill(ink)
                            .frame(width: 78, height: 78)

                        VStack(spacing: -2) {
                            Text(portfolioLeader.map { "\(Int(portfolioPreviewScore($0).rounded()))" } ?? "—")
                                .font(.system(size: 29, weight: .black))
                            Text("PRIORITY")
                                .font(.system(size: 6, weight: .black))
                                .tracking(0.8)
                        }
                        .foregroundStyle(orange)
                    }
                    .rotationEffect(.degrees(5))
                }
                .foregroundStyle(ink)
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
                .background(orange)
                .clipShape(IndexCardShape())
            }
            .buttonStyle(HomePressStyle())

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                router.push(.founderBrief)
            } label: {
                ZStack(alignment: .topTrailing) {
                    MemoPaperShape()
                        .fill(paper)
                        .overlay(
                            MemoPaperShape()
                                .stroke(line, lineWidth: 1)
                        )

                    Rectangle()
                        .fill(blue)
                        .frame(width: 72, height: 18)
                        .rotationEffect(.degrees(5))
                        .offset(x: -18, y: -4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("WEEKLY FOUNDER BRIEF")
                            .font(.system(size: 8, weight: .black))
                            .tracking(1.2)
                            .foregroundStyle(secondaryText)

                        Text("Your week, distilled.")
                            .font(.system(size: 27, weight: .black))
                            .tracking(-1.0)
                            .foregroundStyle(ink)

                        Text(founderBriefPreview)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(secondaryText)
                            .lineSpacing(3)

                        HStack {
                            Text("OPEN THE BRIEF  →")
                                .font(.system(size: 8, weight: .black))
                                .tracking(0.8)

                            Spacer()

                            Text("03")
                                .font(.system(size: 22, weight: .black))
                        }
                        .foregroundStyle(ink)
                    }
                    .padding(18)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .rotationEffect(.degrees(-0.7))
            }
            .buttonStyle(HomePressStyle())
        }
    }

    // MARK: - Next action

    private var nextBestAction: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                index: "03",
                eyebrow: "NEXT MOVE",
                title: "Do the useful thing.",
                action: nil
            )

            if let idea = selectedBusinessIdea {
                Button {
                    openNextAction(for: idea)
                } label: {
                    ZStack {
                        TicketShape()
                            .fill(pink)

                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(idea.lifecycle.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .black))
                                    .tracking(1.2)

                                Spacer()

                                Text(progressLabel(for: idea))
                                    .font(.system(size: 23, weight: .black))
                            }

                            Text(nextActionTitle(for: idea))
                                .font(.system(size: 29, weight: .black))
                                .tracking(-1.1)
                                .multilineTextAlignment(.leading)

                            Text(nextActionDetail(for: idea))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ink.opacity(0.70))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)

                            Rectangle()
                                .fill(ink.opacity(0.22))
                                .frame(height: 1)

                            HStack {
                                Text(nextActionButton(for: idea).uppercased())
                                    .font(.system(size: 8, weight: .black))
                                    .tracking(0.8)

                                Spacer()

                                HStack(spacing: 4) {
                                    ForEach(0..<6, id: \.self) { index in
                                        Circle()
                                            .fill(
                                                Double(index + 1) / 6.0 <= progressValue(for: idea)
                                                ? ink
                                                : ink.opacity(0.18)
                                            )
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }
                        .foregroundStyle(ink)
                        .padding(.horizontal, 27)
                        .padding(.vertical, 18)
                    }
                    .frame(maxWidth: .infinity, minHeight: 230)
                }
                .buttonStyle(HomePressStyle())
            }
        }
    }

    // MARK: - What changed

    private var whatChanged: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                index: "04",
                eyebrow: "MARKET CHATTER",
                title: "What changed while you were away.",
                action: marketUpdates.isEmpty ? nil : "SEE ALL"
            )

            if marketUpdates.isEmpty {
                Text("No new signals yet.")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(ink)
                    .padding(18)
                    .background(green)
                    .clipShape(SpeechBubbleShape(tailSide: .left))
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(marketUpdates.prefix(3).enumerated()), id: \.element.id) { index, update in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedMarketUpdate = update
                        } label: {
                            HStack {
                                if index % 2 == 1 {
                                    Spacer(minLength: 44)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(update.ideaTitle.uppercased())
                                            .font(.system(size: 7, weight: .black))
                                            .tracking(0.9)

                                        Spacer()

                                        Text(update.scoreDeltaText)
                                            .font(.system(size: 18, weight: .black))
                                    }

                                    Text(update.signal)
                                        .font(.system(size: 15, weight: .black))
                                        .tracking(-0.2)
                                        .multilineTextAlignment(.leading)

                                    HStack {
                                        Text(update.timeLabel.uppercased())
                                            .font(.system(size: 7, weight: .black))
                                            .tracking(0.8)
                                            .opacity(0.60)

                                        Spacer()

                                        Text("OPEN  →")
                                            .font(.system(size: 7, weight: .black))
                                            .tracking(0.8)
                                    }
                                }
                                .foregroundStyle(ink)
                                .padding(.horizontal, 17)
                                .padding(.top, 15)
                                .padding(.bottom, 22)
                                .frame(maxWidth: 315, alignment: .leading)
                                .background(updateBubbleColor(update, index: index))
                                .clipShape(
                                    SpeechBubbleShape(
                                        tailSide: index % 2 == 0 ? .left : .right
                                    )
                                )

                                if index % 2 == 0 {
                                    Spacer(minLength: 44)
                                }
                            }
                        }
                        .buttonStyle(HomePressStyle())
                    }
                }

                Button {
                    showAllMarketUpdates = true
                } label: {
                    HStack {
                        Text("OPEN THE FULL MARKET FILE")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.9)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(ink)
                    .padding(.top, 4)
                }
                .buttonStyle(HomePressStyle())
            }
        }
    }

    // MARK: - AI

    private var aiStrip: some View {
        Button {
            if let idea = selectedBusinessIdea {
                router.push(.ai(idea.id))
            }
        } label: {
            HStack(spacing: 12) {
                Text("05")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(background)

                Rectangle()
                    .fill(background.opacity(0.35))
                    .frame(width: 1, height: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text("KINDLING AI")
                        .font(.system(size: 7, weight: .black))
                        .tracking(1.3)
                        .foregroundStyle(background.opacity(0.70))

                    Text("Ask the archive anything.")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(background)
                }

                Spacer()

                Text("ASK  →")
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.7)
                    .foregroundStyle(background)
            }
            .padding(.horizontal, 18)
            .frame(height: 74)
            .background(ink)
            .clipShape(Capsule())
        }
        .buttonStyle(HomePressStyle())
    }

    private func updateBubbleColor(
        _ update: WhatChangedItem,
        index: Int
    ) -> Color {
        switch update.kind {
        case .positive:
            return green
        case .negative:
            return coral
        case .opportunity:
            return blue
        case .neutral:
            return index.isMultiple(of: 2) ? yellow : orange
        }
    }

    // MARK: - Small pieces

    private func sectionHeader(
        index: String,
        eyebrow: String,
        title: String,
        action: String?
    ) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(index)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(ink)

                    Text(eyebrow)
                        .font(.system(size: 8, weight: .black))
                        .tracking(1.35)
                        .foregroundStyle(secondaryText)
                }

                Text(title)
                    .font(.system(size: 25, weight: .black))
                    .tracking(-0.9)
                    .foregroundStyle(ink)
            }

            Spacer()

            if let action {
                Text(action)
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var portfolioHeadline: String {
        guard let leader = portfolioLeader else {
            return "Your next best bet."
        }

        return "\(leader.title)\nis leading."
    }

    private var portfolioDetail: String {
        guard let leader = portfolioLeader else {
            return "Rank your ideas by opportunity, fit, evidence, momentum, and effort."
        }

        return "Kindling currently sees this as the strongest use of your next focused block of time."
    }

    private var founderBriefPreview: String {
        guard let leader = portfolioLeader else {
            return "A weekly synthesis of what changed and what deserves your attention."
        }

        if leader.validationProgress < 45 {
            return "\(leader.title) leads the portfolio. This week, prove purchase intent before adding scope."
        }

        return "\(leader.title) leads the portfolio. Review what changed and move the next milestone."
    }

    private func accentColor(for accent: IdeaAccent) -> Color {
        switch accent {
        case .coral: return coral
        case .blue: return blue
        case .orange: return orange
        case .green: return green
        case .pink: return pink
        }
    }

    private func lifecycleStatus(for idea: BusinessIdea) -> String {
        if idea.decision == .pause {
            return "Paused"
        }

        switch idea.lifecycle {
        case .captured: return "Captured"
        case .analyzed: return "Analyzed"
        case .validating: return "Validating \(idea.validationProgress)%"
        case .planning: return "Planning \(idea.businessPlanProgress)%"
        case .building: return "Building"
        case .launched: return "Launched"
        }
    }

    private func lifecycleDetail(for idea: BusinessIdea) -> String {
        switch idea.lifecycle {
        case .captured: return "Shape the file"
        case .analyzed: return "Review the report"
        case .validating: return "Continue experiments"
        case .planning: return "Continue the plan"
        case .building: return "Review milestone"
        case .launched: return "Watch performance"
        }
    }

    private func progressLabel(for idea: BusinessIdea) -> String {
        switch idea.lifecycle {
        case .validating: return "\(idea.validationProgress)%"
        case .planning: return "\(idea.businessPlanProgress)%"
        case .captured: return "NEW"
        default: return "\(idea.viabilityScore)"
        }
    }

    private func progressValue(for idea: BusinessIdea) -> Double {
        switch idea.lifecycle {
        case .validating: return Double(idea.validationProgress) / 100
        case .planning: return Double(idea.businessPlanProgress) / 100
        case .captured: return 0.12
        default: return Double(idea.viabilityScore) / 100
        }
    }

    private func nextActionTitle(for idea: BusinessIdea) -> String {
        switch idea.lifecycle {
        case .captured: return "Turn the note into an analysis."
        case .analyzed: return "Prove the riskiest assumption."
        case .validating: return "Keep collecting real evidence."
        case .planning: return "Turn evidence into a plan."
        case .building: return "Review the next build milestone."
        case .launched: return "Compare reality with the thesis."
        }
    }

    private func nextActionDetail(for idea: BusinessIdea) -> String {
        switch idea.lifecycle {
        case .captured:
            return "\(idea.title) is captured. Structure it enough for Kindling to evaluate."
        case .analyzed:
            return "The report is ready. Move from research to direct evidence before committing more time."
        case .validating:
            return "Keep testing the assumptions that could actually change your decision."
        case .planning:
            return "Use the strongest evidence to make the business plan specific and executable."
        case .building:
            return "Keep the build tied to measurable milestones rather than expanding the feature list."
        case .launched:
            return "Use real customer behavior to update the score, plan, and next decision."
        }
    }

    private func nextActionButton(for idea: BusinessIdea) -> String {
        switch idea.lifecycle {
        case .captured: return "Analyze idea  →"
        case .analyzed: return "Start validation  →"
        case .validating: return "Open validation  →"
        case .planning: return "Continue plan  →"
        case .building: return "Open idea  →"
        case .launched: return "Review idea  →"
        }
    }

    private func openNextAction(for idea: BusinessIdea) {
        switch idea.lifecycle {
        case .captured:
            router.push(.report(idea.id))
        case .analyzed, .validating:
            router.push(.validation(idea.id))
        case .planning:
            router.push(.businessPlan(idea.id))
        case .building, .launched:
            router.push(.report(idea.id))
        }
    }

    private func portfolioPreviewScore(
        _ idea: BusinessIdea
    ) -> Double {
        let momentum: Double

        switch idea.marketDirection {
        case "↑": momentum = 100
        case "↓": momentum = 30
        default: momentum = 65
        }

        let competition = max(
            0,
            min(100, 100 - Double(idea.competitorCount) * 2.2)
        )

        let ease = max(
            0,
            min(100, 100 - Double(idea.entryDifficulty))
        )

        var score =
            Double(idea.viabilityScore) * 0.34
            + Double(idea.founderFit) * 0.24
            + Double(idea.validationProgress) * 0.14
            + momentum * 0.10
            + competition * 0.08
            + ease * 0.10

        if idea.decision == .pause {
            score *= 0.55
        }

        return score
    }
}

// MARK: - Home model

struct HomeIdea: Identifiable {
    let id = UUID()
    let sourceID: UUID
    let category: String
    let title: String
    let score: Int
    let market: String
    let fit: Int
    let entry: Int
    let status: String
    let detail: String
    let color: Color
}

// MARK: - Filing-card carousel

struct HomeHorizontalCarousel: View {
    let ideas: [HomeIdea]
    @Binding var selectedIndex: Int

    let ink: Color
    let secondary: Color
    let line: Color
    let paper: Color
    let onOpen: (UUID) -> Void

    @State private var centeredCarouselID: String?
    @State private var isRecentering = false

    private struct CarouselItem: Identifiable {
        let id: String
        let copy: Int
        let baseIndex: Int
        let idea: HomeIdea
    }

    private var carouselItems: [CarouselItem] {
        guard !ideas.isEmpty else { return [] }

        return (0..<3).flatMap { copy in
            ideas.enumerated().map { index, idea in
                CarouselItem(
                    id: "\(copy)-\(idea.sourceID.uuidString)",
                    copy: copy,
                    baseIndex: index,
                    idea: idea
                )
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = max(276, geometry.size.width - 54)

            ScrollView(.horizontal) {
                LazyHStack(spacing: -34) {
                    ForEach(carouselItems) { item in
                        HomeFileCard(
                            idea: item.idea,
                            ink: ink,
                            secondary: secondary,
                            line: line,
                            paper: paper
                        )
                        .frame(width: cardWidth, height: 308)
                        .id(item.id)
                        .zIndex(centeredCarouselID == item.id ? 10 : 1)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                                .opacity(phase.isIdentity ? 1.0 : 0.90)
                                .rotationEffect(
                                    .degrees(phase.value * 5.0)
                                )
                                .offset(
                                    x: phase.value * 6.0,
                                    y: phase.isIdentity ? 0.0 : 24.0
                                )
                        }
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onOpen(item.idea.sourceID)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 34, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $centeredCarouselID, anchor: .center)
            .sensoryFeedback(.selection, trigger: centeredCarouselID)
            .onAppear {
                moveToMiddleCopy(index: selectedIndex, animated: false)
            }
            .onChange(of: centeredCarouselID) {
                handleCenteredItemChange()
            }
            .onChange(of: selectedIndex) {
                guard ideas.indices.contains(selectedIndex) else { return }
                guard let current = currentCarouselItem,
                      current.baseIndex != selectedIndex else { return }
                moveToMiddleCopy(index: selectedIndex, animated: true)
            }
            .onChange(of: ideas.count) {
                moveToMiddleCopy(
                    index: min(selectedIndex, max(ideas.count - 1, 0)),
                    animated: false
                )
            }
        }
    }

    private var currentCarouselItem: CarouselItem? {
        guard let centeredCarouselID else { return nil }
        return carouselItems.first { $0.id == centeredCarouselID }
    }

    private func handleCenteredItemChange() {
        guard !isRecentering, let current = currentCarouselItem else { return }

        selectedIndex = current.baseIndex

        if current.copy != 1 {
            isRecentering = true

            DispatchQueue.main.async {
                centeredCarouselID = middleID(for: current.baseIndex)

                DispatchQueue.main.async {
                    isRecentering = false
                }
            }
        }
    }

    private func moveToMiddleCopy(
        index: Int,
        animated: Bool
    ) {
        guard ideas.indices.contains(index) else {
            centeredCarouselID = nil
            return
        }

        let id = middleID(for: index)

        if animated {
            withAnimation(.snappy(duration: 0.25, extraBounce: 0.01)) {
                centeredCarouselID = id
            }
        } else {
            centeredCarouselID = id
        }
    }

    private func middleID(for index: Int) -> String {
        "1-\(ideas[index].sourceID.uuidString)"
    }
}

struct HomeFileCard: View {
    let idea: HomeIdea
    let ink: Color
    let secondary: Color
    let line: Color
    let paper: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            FolderCardShape()
                .fill(idea.color)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FILE / \(idea.category)")
                            .font(.system(size: 7, weight: .black))
                            .tracking(1.1)

                        Text(idea.status.uppercased())
                            .font(.system(size: 7, weight: .black))
                            .tracking(0.7)
                            .foregroundStyle(ink.opacity(0.62))
                    }

                    Spacer()

                    Text("\(idea.score)")
                        .font(.system(size: 42, weight: .black))
                        .tracking(-1.5)
                }
                .padding(.top, 42)

                Rectangle()
                    .fill(ink.opacity(0.22))
                    .frame(height: 1)
                    .padding(.vertical, 14)

                Text(idea.title)
                    .font(.system(size: 31, weight: .black))
                    .tracking(-1.25)
                    .lineSpacing(-3)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 0) {
                    fileMetric(label: "FIT", value: "\(idea.fit)")
                    fileMetric(label: "ENTRY", value: "\(idea.entry)")
                    fileMetric(label: "MARKET", value: idea.market)
                }

                HStack {
                    Text(idea.detail.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .tracking(0.8)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .black))
                }
                .padding(.top, 14)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 19)
            .padding(.bottom, 18)
        }
        .overlay(
            FolderCardShape()
                .stroke(ink.opacity(0.12), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 6
        )
    }

    private func fileMetric(
        label: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 6, weight: .black))
                .tracking(0.9)
                .foregroundStyle(secondary)

            Text(value)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FolderCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let bodyTop: CGFloat = 34
        let tabWidth = rect.width * 0.34
        let tabSlope: CGFloat = 28

        var path = Path()

        // One continuous left wall: the folder tab begins directly
        // from the same left edge as the body, with no shoulder/bump.
        path.move(to: CGPoint(x: 0, y: radius))
        path.addQuadCurve(
            to: CGPoint(x: radius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        // Flat tab, then the classic folder drop into the body top.
        path.addLine(to: CGPoint(x: tabWidth, y: 0))
        path.addLine(to: CGPoint(x: tabWidth + tabSlope, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.width - radius, y: bodyTop))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: bodyTop + radius),
            control: CGPoint(x: rect.width, y: bodyTop)
        )

        // Clean right wall and bottom edge.
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - radius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )
        path.addLine(to: CGPoint(x: radius, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - radius),
            control: CGPoint(x: 0, y: rect.height)
        )
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.closeSubpath()

        return path
    }
}


enum BubbleTailSide {
    case left
    case right
}

struct SpeechBubbleShape: Shape {
    let tailSide: BubbleTailSide

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 22
        let tailWidth: CGFloat = 20
        let tailHeight: CGFloat = 16
        let bubbleBottom = rect.maxY - tailHeight

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: bubbleBottom - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: bubbleBottom),
            control: CGPoint(x: rect.maxX, y: bubbleBottom)
        )

        if tailSide == .right {
            path.addLine(to: CGPoint(x: rect.maxX - 36, y: bubbleBottom))
            path.addLine(to: CGPoint(x: rect.maxX - 15, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - 62, y: bubbleBottom))
        }

        path.addLine(to: CGPoint(x: rect.minX + radius, y: bubbleBottom))

        if tailSide == .left {
            path.addLine(to: CGPoint(x: rect.minX + 62, y: bubbleBottom))
            path.addLine(to: CGPoint(x: rect.minX + 15, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + 36, y: bubbleBottom))
        }

        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: bubbleBottom - radius),
            control: CGPoint(x: rect.minX, y: bubbleBottom)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct IndexCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cut: CGFloat = 34
        let radius: CGFloat = 12
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct MemoPaperShape: Shape {
    func path(in rect: CGRect) -> Path {
        let fold: CGFloat = 28
        let radius: CGFloat = 8
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 10
        let notch: CGFloat = 14
        let midY = rect.midY
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: midY - notch))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: midY + notch),
            control: CGPoint(x: rect.maxX - notch, y: midY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: midY + notch))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: midY - notch),
            control: CGPoint(x: rect.minX + notch, y: midY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct HomePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.978 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
        .environmentObject(KindlingStore())
        .environmentObject(KindlingRouter())
}
