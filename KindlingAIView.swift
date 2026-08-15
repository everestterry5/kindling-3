import SwiftUI
import UIKit

struct KindlingAIView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kindlingDarkMode") private var isDarkMode = false

    @State private var inputText = ""
    @State private var messages: [KindlingMessage] = KindlingMessage.sampleConversation
    @State private var isThinking = false
    @State private var showContext = false
    @State private var selectedPrompt: String?

    @FocusState private var inputFocused: Bool

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

    private var quickPrompts: [String] {
        [
            "What worries you most?",
            "What should I validate next?",
            "What would you do with $5k?",
            "Which competitor matters most?",
            "Does this still fit me?",
            "What changed recently?"
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        contextHeader
                        quickPromptSection
                        conversation(proxy: proxy)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
                }
                .background(background)

                inputBar(proxy: proxy)
            }
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
                    .overlay(
                        Circle()
                            .stroke(border)
                    )
            }
            .buttonStyle(KindlingAIButtonStyle())

            Spacer()

            VStack(spacing: 1) {
                Text("KINDLING AI")
                    .font(.system(size: 15, weight: .black))
                    .tracking(1.7)
                    .foregroundStyle(ink)

                HStack(spacing: 4) {
                    Circle()
                        .fill(green)
                        .frame(width: 6, height: 6)

                    Text("Using idea context")
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(secondary)
                }
            }

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
                    .overlay(
                        Circle()
                            .stroke(border)
                    )
            }
            .buttonStyle(KindlingAIButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(background)
    }

    // MARK: - Context

    private var contextHeader: some View {
        VStack(spacing: 0) {
            Button {
                haptic(.selection)

                withAnimation(
                    .spring(response: 0.36, dampingFraction: 0.86)
                ) {
                    showContext.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(orange)
                        .frame(width: 46, height: 46)
                        .overlay(
                            VStack(spacing: 0) {
                                Text("84")
                                    .font(.system(size: 16, weight: .black))

                                Text("/100")
                                    .font(.system(size: 6, weight: .black))
                            }
                            .foregroundStyle(ink)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("AI MEAL PLANNING")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.9)
                            .foregroundStyle(secondary)

                        Text("Ask about this idea")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(ink)
                    }

                    Spacer()

                    Text("CONTEXT")
                        .font(.system(size: 7, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(secondary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(ink)
                        .rotationEffect(.degrees(showContext ? 180 : 0))
                }
                .padding(13)
                .background(paper)
            }
            .buttonStyle(KindlingAIButtonStyle())

            if showContext {
                Divider()
                    .overlay(border)

                VStack(alignment: .leading, spacing: 10) {
                    contextGrid

                    VStack(alignment: .leading, spacing: 6) {
                        Text("WHAT KINDLING IS USING")
                            .font(.system(size: 7, weight: .black))
                            .tracking(0.8)
                            .foregroundStyle(secondary)

                        ContextSourceRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Idea Report",
                            detail: "Viability, momentum, competitors",
                            ink: ink,
                            secondary: secondary
                        )

                        ContextSourceRow(
                            icon: "checklist",
                            title: "Validation",
                            detail: "4 interviews · 2 strong signals",
                            ink: ink,
                            secondary: secondary
                        )

                        ContextSourceRow(
                            icon: "person.crop.circle",
                            title: "Founder Profile",
                            detail: "$12k budget · 15 hrs/week",
                            ink: ink,
                            secondary: secondary
                        )

                        ContextSourceRow(
                            icon: "doc.text",
                            title: "Business Plan",
                            detail: "38% complete",
                            ink: ink,
                            secondary: secondary
                        )
                    }
                }
                .padding(14)
                .background(raisedPaper)
                .transition(
                    .opacity.combined(with: .move(edge: .top))
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(border)
        )
    }

    private var contextGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 7),
                GridItem(.flexible(), spacing: 7)
            ],
            spacing: 7
        ) {
            ContextMetric(
                title: "VIABILITY",
                value: "84",
                color: orange,
                ink: ink
            )

            ContextMetric(
                title: "FOUNDER FIT",
                value: "76",
                color: pink,
                ink: ink
            )

            ContextMetric(
                title: "COMPETITION",
                value: "71",
                color: blue,
                ink: ink
            )

            ContextMetric(
                title: "VALIDATION",
                value: "38%",
                color: green,
                ink: ink
            )
        }
    }

    // MARK: - Quick Prompts

    private var quickPromptSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("ASK KINDLING")
                .font(.system(size: 8, weight: .black))
                .tracking(1.1)
                .foregroundStyle(secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button {
                            selectedPrompt = prompt
                            haptic(.selection)
                            sendPrompt(prompt)
                        } label: {
                            Text(prompt)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    selectedPrompt == prompt
                                    ? orange
                                    : paper
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedPrompt == prompt
                                            ? ink.opacity(0.55)
                                            : border
                                        )
                                )
                        }
                        .buttonStyle(KindlingAIButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Conversation

    private func conversation(
        proxy: ScrollViewProxy
    ) -> some View {
        VStack(spacing: 12) {
            ForEach(messages) { message in
                MessageBubble(
                    message: message,
                    paper: paper,
                    raisedPaper: raisedPaper,
                    ink: ink,
                    secondary: secondary,
                    orange: orange,
                    blue: blue,
                    green: green,
                    coral: coral,
                    border: border
                )
                .id(message.id)
            }

            if isThinking {
                ThinkingBubble(
                    paper: paper,
                    ink: ink,
                    secondary: secondary,
                    border: border
                )
                .id("thinking")
                .transition(.opacity)
            }
        }
        .onChange(of: messages.count) { _ in
            guard let last = messages.last else { return }

            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
        .onChange(of: isThinking) { thinking in
            if thinking {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("thinking", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Composer

    private func inputBar(
        proxy: ScrollViewProxy
    ) -> some View {
        HStack(alignment: .bottom, spacing: 9) {
            Button {
                haptic(.light)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 39, height: 39)
                    .background(raisedPaper)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(border)
                    )
            }
            .buttonStyle(KindlingAIButtonStyle())

            TextField(
                "Ask Kindling about this idea...",
                text: $inputText,
                axis: .vertical
            )
            .font(.system(size: 12))
            .foregroundStyle(ink)
            .lineLimit(1...5)
            .focused($inputFocused)
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(border)
            )

            Button {
                let trimmed = inputText
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                guard !trimmed.isEmpty else {
                    return
                }

                inputText = ""
                inputFocused = false
                sendPrompt(trimmed)

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.05
                ) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    }
                }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(
                        isDarkMode
                        ? ink
                        : Color.white.opacity(0.92)
                    )
                    .frame(width: 39, height: 39)
                    .background(
                        inputText.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                        ? raisedPaper
                        : (
                            isDarkMode
                            ? raisedPaper
                            : Color(
                                red: 0.09,
                                green: 0.09,
                                blue: 0.08
                            )
                        )
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(KindlingAIButtonStyle())
            .disabled(
                inputText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(background)
    }

    // MARK: - Fake AI Logic

    private func sendPrompt(
        _ prompt: String
    ) {
        guard !isThinking else {
            return
        }

        haptic(.light)

        let userMessage = KindlingMessage(
            role: .user,
            text: prompt
        )

        withAnimation(
            .spring(response: 0.32, dampingFraction: 0.90)
        ) {
            messages.append(userMessage)
            isThinking = true
        }

        let response = fakeResponse(for: prompt)

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.85
        ) {
            withAnimation(
                .spring(response: 0.36, dampingFraction: 0.90)
            ) {
                isThinking = false

                messages.append(
                    KindlingMessage(
                        role: .assistant,
                        text: response.text,
                        insight: response.insight,
                        action: response.action,
                        signal: response.signal
                    )
                )
            }

            haptic(.success)
        }
    }

    private func fakeResponse(
        for prompt: String
    ) -> KindlingResponse {
        let lower = prompt.lowercased()

        if lower.contains("worr") ||
            lower.contains("risk") ||
            lower.contains("scare") {

            return KindlingResponse(
                text:
                    "The biggest risk is not whether people dislike meal planning. That pain is already showing up. The bigger risk is whether the problem is painful enough for families to pay every month instead of using free recipes, spreadsheets, or existing apps.",
                insight:
                    "Your current evidence supports the problem more strongly than the willingness-to-pay assumption.",
                action:
                    "Run the $12 pricing test before adding more product scope.",
                signal:
                    .risk
            )
        }

        if lower.contains("validate") ||
            lower.contains("next") {

            return KindlingResponse(
                text:
                    "I would validate willingness to pay next. You already have enough early evidence that meal planning is frustrating. The next decision-changing question is whether grocery savings creates enough perceived value to support a subscription.",
                insight:
                    "Current validation confidence: 38%. Pricing remains the highest-impact unknown.",
                action:
                    "Collect 10 pricing responses using a fake checkout or purchase-intent test.",
                signal:
                    .action
            )
        }

        if lower.contains("5k") ||
            lower.contains("budget") ||
            lower.contains("money") {

            return KindlingResponse(
                text:
                    "With $5,000, I would not build the full app. I’d spend the first portion validating the positioning, then build only enough product to prove repeat usage.",
                insight:
                    "Suggested allocation: 10% research, 20% prototype, 50% narrow MVP, 20% acquisition testing.",
                action:
                    "Do not spend heavily on integrations until customers prove they value the core planning loop.",
                signal:
                    .opportunity
            )
        }

        if lower.contains("competitor") {

            return KindlingResponse(
                text:
                    "Mealime matters most as a behavioral benchmark because it overlaps with family planning. Samsung Food matters strategically because it can bundle features into a much larger ecosystem. I would not try to beat either on generic recipe discovery.",
                insight:
                    "The cleaner opening remains budget + pantry intelligence.",
                action:
                    "Study how Mealime communicates convenience, then position Kindling around measurable household savings.",
                signal:
                    .research
            )
        }

        if lower.contains("fit") ||
            lower.contains("me") {

            return KindlingResponse(
                text:
                    "This still looks like a workable founder fit for you, but distribution is the weak point. Your current budget and weekly time are enough to validate and prototype. What you do not yet have is a low-cost path to the first few hundred relevant families.",
                insight:
                    "Founder Fit: 76/100. Distribution remains the lowest sub-score.",
                action:
                    "Treat audience-building as part of validation, not something to solve after the product exists.",
                signal:
                    .personal
            )
        }

        if lower.contains("changed") ||
            lower.contains("recent") ||
            lower.contains("week") {

            return KindlingResponse(
                text:
                    "The main change is positive: search interest in the broader AI meal-planning space increased, while your strongest niche still appears less crowded than generic meal planning. Competition is rising too, so the opportunity improved slightly rather than dramatically.",
                insight:
                    "Viability moved from 81 → 84 in the current prototype.",
                action:
                    "Keep the niche narrow and re-check pricing pressure before committing to the MVP.",
                signal:
                    .change
            )
        }

        return KindlingResponse(
            text:
                "Based on the current idea report, founder profile, validation evidence, and business-plan progress, I would keep this in validation rather than moving straight to a full build.",
            insight:
                "The idea is promising, but the strongest remaining uncertainty is still customer willingness to pay.",
            action:
                "Ask me about risk, pricing, competitors, founder fit, or what to validate next.",
            signal:
                .action
        )
    }

    // MARK: - Haptics

    private enum HapticKind {
        case selection
        case light
        case success
    }

    private func haptic(
        _ kind: HapticKind
    ) {
        switch kind {
        case .selection:
            UISelectionFeedbackGenerator()
                .selectionChanged()

        case .light:
            UIImpactFeedbackGenerator(
                style: .light
            )
            .impactOccurred()

        case .success:
            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        }
    }
}

// MARK: - Models

enum KindlingMessageRole {
    case user
    case assistant
}

enum KindlingAISignal {
    case risk
    case action
    case opportunity
    case research
    case personal
    case change
}

struct KindlingMessage: Identifiable {
    let id = UUID()
    let role: KindlingMessageRole
    let text: String
    var insight: String?
    var action: String?
    var signal: KindlingAISignal?

    static let sampleConversation: [KindlingMessage] = [
        KindlingMessage(
            role: .assistant,
            text:
                "I’m looking at your AI Meal Planning idea, the current market analysis, your founder profile, and the validation work you’ve logged so far.",
            insight:
                "Viability is 84/100, but only 38% of the important assumptions have meaningful validation evidence.",
            action:
                "Ask me what worries me most, what to validate next, or how I’d approach this with your current budget.",
            signal:
                .action
        )
    ]
}

struct KindlingResponse {
    let text: String
    let insight: String
    let action: String
    let signal: KindlingAISignal
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: KindlingMessage

    let paper: Color
    let raisedPaper: Color
    let ink: Color
    let secondary: Color
    let orange: Color
    let blue: Color
    let green: Color
    let coral: Color
    let border: Color

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 44)
            }

            VStack(
                alignment:
                    message.role == .user
                    ? .trailing
                    : .leading,
                spacing: 8
            ) {
                if message.role == .assistant {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .black))

                        Text("KINDLING")
                            .font(.system(size: 7, weight: .black))
                            .tracking(0.9)
                    }
                    .foregroundStyle(secondary)
                }

                Text(message.text)
                    .font(.system(size: 12))
                    .foregroundStyle(ink)
                    .lineSpacing(4)
                    .multilineTextAlignment(
                        message.role == .user
                        ? .trailing
                        : .leading
                    )

                if message.role == .assistant {
                    if let insight = message.insight {
                        InsightStrip(
                            title: "WHY THIS MATTERS",
                            text: insight,
                            color: signalColor,
                            ink: ink
                        )
                    }

                    if let action = message.action {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("NEXT MOVE")
                                .font(.system(size: 7, weight: .black))
                                .tracking(0.8)
                                .foregroundStyle(secondary)

                            Text(action)
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(ink)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(raisedPaper)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 13
                            )
                        )
                    }
                }
            }
            .padding(13)
            .background(
                message.role == .user
                ? raisedPaper
                : paper
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(border)
            )

            if message.role == .assistant {
                Spacer(minLength: 22)
            }
        }
    }

    private var signalColor: Color {
        switch message.signal {
        case .risk:
            return coral

        case .research:
            return blue

        case .opportunity:
            return orange

        case .personal:
            return Color(
                red: 0.91,
                green: 0.54,
                blue: 0.68
            )

        case .change:
            return green

        case .action, .none:
            return orange
        }
    }
}

// MARK: - Thinking Bubble

struct ThinkingBubble: View {
    let paper: Color
    let ink: Color
    let secondary: Color
    let border: Color

    @State private var pulse = false

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(secondary)

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(secondary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(
                                pulse
                                ? 1.0
                                : 0.65
                            )
                            .animation(
                                .easeInOut(duration: 0.55)
                                .repeatForever()
                                .delay(
                                    Double(index) * 0.12
                                ),
                                value: pulse
                            )
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(paper)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(border)
            )

            Spacer()
        }
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - Context Components

struct ContextMetric: View {
    let title: String
    let value: String
    let color: Color
    let ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 7, weight: .black))
                .tracking(0.6)

            Text(value)
                .font(.system(size: 19, weight: .black))
        }
        .foregroundStyle(ink)
        .frame(
            maxWidth: .infinity,
            minHeight: 67,
            alignment: .topLeading
        )
        .padding(10)
        .background(color)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 13
            )
        )
    }
}

struct ContextSourceRow: View {
    let icon: String
    let title: String
    let detail: String
    let ink: Color
    let secondary: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(ink)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)

                Text(detail)
                    .font(.system(size: 8))
                    .foregroundStyle(secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(secondary)
        }
        .padding(.vertical, 4)
    }
}

struct InsightStrip: View {
    let title: String
    let text: String
    let color: Color
    let ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 7, weight: .black))
                .tracking(0.7)

            Text(text)
                .font(.system(size: 9, weight: .black))
                .lineSpacing(3)
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 13
            )
        )
    }
}

// MARK: - Press Style

struct KindlingAIButtonStyle: ButtonStyle {
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
    KindlingAIView()
}
