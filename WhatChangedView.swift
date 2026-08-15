import SwiftUI
import UIKit

enum WhatChangedKind: String, Hashable {
    case positive
    case negative
    case opportunity
    case neutral

    var icon: String {
        switch self {
        case .positive:
            return "arrow.up.right"
        case .negative:
            return "exclamationmark"
        case .opportunity:
            return "sparkles"
        case .neutral:
            return "waveform.path.ecg"
        }
    }

    var label: String {
        switch self {
        case .positive:
            return "POSITIVE SIGNAL"
        case .negative:
            return "WATCH CLOSELY"
        case .opportunity:
            return "OPPORTUNITY"
        case .neutral:
            return "MARKET SIGNAL"
        }
    }
}

struct WhatChangedItem: Identifiable, Hashable {
    let id: UUID
    let ideaID: UUID
    let ideaTitle: String
    let kind: WhatChangedKind
    let signal: String
    let impact: String
    let recommendedMove: String
    let evidence: [String]
    let scoreDelta: Int
    let timeLabel: String
    let confidence: Int

    var scoreDeltaText: String {
        if scoreDelta > 0 {
            return "+\(scoreDelta)"
        }

        if scoreDelta < 0 {
            return "\(scoreDelta)"
        }

        return "0"
    }

    static func prototypeUpdates(
        for ideas: [BusinessIdea]
    ) -> [WhatChangedItem] {
        guard !ideas.isEmpty else {
            return []
        }

        var updates: [WhatChangedItem] = []

        let first = ideas[0]
        updates.append(
            WhatChangedItem(
                id: UUID(uuidString: "A1D30C6B-8C21-49EA-93D2-3C15A9F70B11")!,
                ideaID: first.id,
                ideaTitle: first.title,
                kind: .positive,
                signal: "Demand momentum strengthened.",
                impact: "Interest around the problem is moving in the right direction. That improves the opportunity, but it does not remove the need to prove willingness to pay.",
                recommendedMove: "Keep validation moving. Use your next interviews to test purchase intent instead of asking whether people simply like the concept.",
                evidence: [
                    "Related search activity is trending upward.",
                    "More products are entering adjacent categories.",
                    "Customer language is becoming more specific around the problem."
                ],
                scoreDelta: 2,
                timeLabel: "Today",
                confidence: 82
            )
        )

        if ideas.count > 1 {
            let second = ideas[1]
            updates.append(
                WhatChangedItem(
                    id: UUID(uuidString: "BB38BC62-1E38-4E74-A87F-8F5D41F2E630")!,
                    ideaID: second.id,
                    ideaTitle: second.title,
                    kind: .negative,
                    signal: "A new competitor entered the category.",
                    impact: "The market is getting more crowded. The idea is still viable, but a generic version of the product becomes harder to defend.",
                    recommendedMove: "Do not compete feature-for-feature. Tighten the customer segment and identify one distribution advantage the new entrant cannot easily copy.",
                    evidence: [
                        "One new direct competitor was detected.",
                        "The entrant is positioning around convenience.",
                        "Pricing is close to the current market median."
                    ],
                    scoreDelta: -3,
                    timeLabel: "2h ago",
                    confidence: 76
                )
            )
        }

        if ideas.count > 2 {
            let third = ideas[2]
            updates.append(
                WhatChangedItem(
                    id: UUID(uuidString: "D4552DFA-58D0-4A56-BA0A-066455A9FD52")!,
                    ideaID: third.id,
                    ideaTitle: third.title,
                    kind: .opportunity,
                    signal: "A narrower niche is opening up.",
                    impact: "The broad market remains competitive, but one underserved customer cluster appears less saturated and better aligned with a focused launch.",
                    recommendedMove: "Rewrite the offer for the narrower niche and run a small landing-page test before expanding the product scope.",
                    evidence: [
                        "Competitor density is lower in the niche.",
                        "Existing products serve the segment indirectly.",
                        "The niche has clearer problem-specific language."
                    ],
                    scoreDelta: 3,
                    timeLabel: "Yesterday",
                    confidence: 71
                )
            )
        }

        if ideas.count > 3 {
            let fourth = ideas[3]
            updates.append(
                WhatChangedItem(
                    id: UUID(uuidString: "1FCB551B-60D7-435D-99FB-DC1AD2216C97")!,
                    ideaID: fourth.id,
                    ideaTitle: fourth.title,
                    kind: .neutral,
                    signal: "Pricing pressure is increasing.",
                    impact: "More competitors are clustering around similar subscription pricing. The market is not necessarily weaker, but differentiation matters more.",
                    recommendedMove: "Test value-based positioning before lowering price. A cheaper offer is only useful if price is actually the adoption barrier.",
                    evidence: [
                        "Competitor pricing is converging.",
                        "Free trials are becoming more common.",
                        "Premium tiers are adding service-based features."
                    ],
                    scoreDelta: -1,
                    timeLabel: "2d ago",
                    confidence: 68
                )
            )
        }

        return updates
    }
}

struct WhatChangedFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kindlingDarkMode") private var isDarkMode = false

    let updates: [WhatChangedItem]

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("MARKET INTELLIGENCE")
                            .font(.system(size: 9, weight: .black))
                            .tracking(1.6)
                            .foregroundStyle(secondary)

                        Text("What changed.")
                            .font(.system(size: 38, weight: .black))
                            .tracking(-1.8)
                            .foregroundStyle(ink)

                        Text("Changes that could affect your next decision.")
                            .font(.system(size: 13))
                            .foregroundStyle(secondary)
                    }

                    ForEach(updates) { update in
                        NavigationLink {
                            WhatChangedDetailView(update: update)
                        } label: {
                            WhatChangedFeedCard(
                                update: update,
                                paper: paper,
                                ink: ink,
                                secondary: secondary,
                                border: border
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(ink)
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

private struct WhatChangedFeedCard: View {
    let update: WhatChangedItem
    let paper: Color
    let ink: Color
    let secondary: Color
    let border: Color

    private var accent: Color {
        switch update.kind {
        case .positive:
            return Color(red: 0.20, green: 0.66, blue: 0.36)
        case .negative:
            return Color(red: 0.98, green: 0.38, blue: 0.33)
        case .opportunity:
            return Color(red: 0.34, green: 0.56, blue: 0.88)
        case .neutral:
            return Color(red: 0.96, green: 0.62, blue: 0.04)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text(update.kind.label)
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.1)

                Spacer()

                Text(update.timeLabel.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.7)
            }
            .foregroundStyle(secondary)

            Text(update.signal)
                .font(.system(size: 20, weight: .black))
                .tracking(-0.5)
                .foregroundStyle(ink)

            HStack {
                Text(update.ideaTitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(secondary)

                Spacer()

                Text("\(update.scoreDeltaText) SCORE")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)
                    .padding(.horizontal, 9)
                    .frame(height: 27)
                    .background(accent)
                    .clipShape(Capsule())
            }

            Text(update.recommendedMove)
                .font(.system(size: 11))
                .foregroundStyle(secondary)
                .lineSpacing(3)
                .lineLimit(3)
        }
        .padding(16)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }
}

struct WhatChangedDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: KindlingRouter
    @AppStorage("kindlingDarkMode") private var isDarkMode = false

    let update: WhatChangedItem

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

    private var accent: Color {
        switch update.kind {
        case .positive:
            return isDarkMode
            ? Color(red: 0.12, green: 0.41, blue: 0.24)
            : Color(red: 0.20, green: 0.66, blue: 0.36)

        case .negative:
            return isDarkMode
            ? Color(red: 0.63, green: 0.22, blue: 0.20)
            : Color(red: 0.98, green: 0.38, blue: 0.33)

        case .opportunity:
            return isDarkMode
            ? Color(red: 0.20, green: 0.36, blue: 0.61)
            : Color(red: 0.34, green: 0.56, blue: 0.88)

        case .neutral:
            return isDarkMode
            ? Color(red: 0.62, green: 0.37, blue: 0.02)
            : Color(red: 0.96, green: 0.62, blue: 0.04)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 38, height: 38)
                            .background(paper)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(update.timeLabel.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)
                        .foregroundStyle(secondary)
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text(update.kind.label)
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(secondary)

                    Text(update.ideaTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(secondary)

                    Text(update.signal)
                        .font(.system(size: 34, weight: .black))
                        .tracking(-1.4)
                        .foregroundStyle(ink)
                }

                HStack(spacing: 10) {
                    metric(
                        label: "SCORE IMPACT",
                        value: update.scoreDeltaText,
                        background: accent
                    )

                    metric(
                        label: "CONFIDENCE",
                        value: "\(update.confidence)%",
                        background: paper
                    )
                }

                sectionCard(
                    kicker: "WHY IT MATTERS",
                    title: "The impact",
                    body: update.impact
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("KINDLING'S MOVE")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1.4)
                        .foregroundStyle(secondary)

                    Text(update.recommendedMove)
                        .font(.system(size: 18, weight: .black))
                        .tracking(-0.35)
                        .foregroundStyle(ink)
                        .lineSpacing(4)
                }
                .padding(17)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 13) {
                    Text("SIGNALS BEHIND THIS")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1.4)
                        .foregroundStyle(secondary)

                    ForEach(update.evidence, id: \.self) { evidence in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(ink)
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)

                            Text(evidence)
                                .font(.system(size: 12))
                                .foregroundStyle(ink)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding(17)
                .background(paper)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(border)
                )

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()

                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.18
                    ) {
                        router.push(.ai(update.ideaID))
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .black))

                        Text("ASK KINDLING AI ABOUT THIS")
                            .font(.system(size: 10, weight: .black))
                            .tracking(0.5)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundStyle(
                        isDarkMode
                        ? Color.black
                        : Color.white
                    )
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(ink)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .background(background.ignoresSafeArea())
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private func metric(
        label: String,
        value: String,
        background: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .tracking(1)
                .foregroundStyle(secondary)

            Text(value)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(border)
        )
    }

    private func sectionCard(
        kicker: String,
        title: String,
        body: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(kicker)
                .font(.system(size: 8, weight: .black))
                .tracking(1.4)
                .foregroundStyle(secondary)

            Text(title)
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(ink)

            Text(body)
                .font(.system(size: 12))
                .foregroundStyle(secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }
}
