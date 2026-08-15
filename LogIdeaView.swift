import SwiftUI
import UIKit

struct LogIdeaView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kindlingDarkMode") private var isDarkMode = false

    @State private var stage: LogIdeaStage = .capture
    @State private var captureMode: IdeaCaptureMode = .text

    @State private var ideaText = ""
    @State private var customer = ""
    @State private var problem = ""
    @State private var businessModel = ""
    @State private var notes = ""

    @State private var selectedCategory = "Not sure yet"
    @State private var selectedUrgency = "Just exploring"

    @FocusState private var ideaFieldFocused: Bool

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
        ZStack {
            background.ignoresSafeArea()

            switch stage {
            case .capture:
                captureScreen
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            case .shape:
                shapeScreen
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .ready:
                readyScreen
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.spring(response: 0.40, dampingFraction: 0.88), value: stage)
    }

    private var captureScreen: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 9) {
                        eyebrow("IDEA INBOX")

                        Text("What’s on\nyour mind?")
                            .font(.system(size: 42, weight: .black))
                            .tracking(-2.2)
                            .lineSpacing(-6)
                            .foregroundStyle(ink)

                        Text("Drop the idea exactly as it exists in your head. It does not need to be polished yet.")
                            .font(.system(size: 13))
                            .foregroundStyle(secondary)
                            .lineSpacing(4)
                    }

                    captureModePicker
                    captureInput

                    if !ideaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        kindlingPreview
                    }

                    recentInbox
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 130)
            }

            captureBottomBar
        }
    }

    private var captureModePicker: some View {
        HStack(spacing: 7) {
            ForEach(IdeaCaptureMode.allCases) { mode in
                Button {
                    selectCaptureMode(mode)
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 15, weight: .bold))

                        Text(mode.title)
                            .font(.system(size: 8, weight: .black))
                    }
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(captureMode == mode ? color(for: mode) : paper)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17)
                            .stroke(
                                captureMode == mode ? ink.opacity(0.75) : border,
                                lineWidth: captureMode == mode ? 1.5 : 1
                            )
                    )
                }
                .buttonStyle(LogIdeaPressStyle())
            }
        }
    }

    @ViewBuilder
    private var captureInput: some View {
        switch captureMode {
        case .text:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("QUICK CAPTURE")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)

                    Spacer()

                    Text("\(ideaText.count) characters")
                        .font(.system(size: 8))
                        .foregroundStyle(secondary)
                }

                TextEditor(text: $ideaText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ink)
                    .scrollContentBackground(.hidden)
                    .focused($ideaFieldFocused)
                    .frame(minHeight: 180)
                    .padding(13)
                    .background(paper)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(border)
                    )
                    .overlay(alignment: .topLeading) {
                        if ideaText.isEmpty {
                            Text("Example: I keep seeing families overspend on groceries because meal planning apps don’t use what they already have at home...")
                                .font(.system(size: 14))
                                .foregroundStyle(secondary.opacity(0.60))
                                .lineSpacing(4)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 21)
                                .allowsHitTesting(false)
                        }
                    }

                Text("TIP · Problems are usually more valuable than polished solutions.")
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.7)
                    .foregroundStyle(secondary)
            }

        case .voice:
            capturePlaceholder(
                icon: "waveform",
                title: "Talk it out.",
                text: "In the real app, hold to record. Kindling will transcribe the thought and pull out the problem, customer, and possible business model.",
                button: "Hold to record",
                color: coral
            )

        case .link:
            capturePlaceholder(
                icon: "link",
                title: "Save something that sparked the idea.",
                text: "Paste an article, product, competitor, or website. Kindling can later connect it to an idea in your inbox.",
                button: "Paste link",
                color: blue
            )

        case .photo:
            capturePlaceholder(
                icon: "camera",
                title: "Capture what you noticed.",
                text: "Save a photo or screenshot of a problem, product, storefront, conversation, or anything that triggered the idea.",
                button: "Choose photo",
                color: pink
            )
        }
    }

    private func capturePlaceholder(
        icon: String,
        title: String,
        text: String,
        button: String,
        color: Color
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(ink)
                .frame(width: 76, height: 76)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 23))

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)

                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                haptic(.light)
            } label: {
                Text(button)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(raisedPaper)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(border))
            }
            .buttonStyle(LogIdeaPressStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(border)
        )
    }

    private var kindlingPreview: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("✦ KINDLING SEES")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1)
                    .foregroundStyle(secondary)

                Spacer()

                Text("EARLY READ")
                    .font(.system(size: 7, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(secondary)
            }

            Text(previewTitle)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(ink)

            Text("There’s enough here to shape into an idea. I’ll ask a few questions next so we don’t analyze the wrong version of it.")
                .font(.system(size: 10))
                .foregroundStyle(secondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(raisedPaper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var previewTitle: String {
        if ideaText.lowercased().contains("meal") || ideaText.lowercased().contains("grocery") {
            return "Possible angle: family grocery savings"
        }

        if ideaText.count > 80 {
            return "You may be describing a real customer problem."
        }

        return "Good start. Let’s sharpen it."
    }

    private var recentInbox: some View {
        VStack(alignment: .leading, spacing: 10) {
            eyebrow("RECENTLY CAPTURED")

            VStack(spacing: 0) {
                InboxRow(
                    title: "AI scheduling for mobile trades",
                    detail: "Captured yesterday",
                    color: blue,
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                InboxRow(
                    title: "Better resale inventory photos",
                    detail: "Unsorted · 3 days ago",
                    color: orange,
                    ink: ink,
                    secondary: secondary
                )

                Divider().overlay(border)

                InboxRow(
                    title: "Local contractor quote tracker",
                    detail: "Unsorted · 5 days ago",
                    color: green,
                    ink: ink,
                    secondary: secondary
                )
            }
            .background(paper)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(border)
            )
        }
    }

    private var captureBottomBar: some View {
        VStack(spacing: 8) {
            Button {
                haptic(.medium)
                stage = .shape
            } label: {
                HStack {
                    Text("Help me shape this")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(
                    canShape
                    ? (isDarkMode ? ink : Color.white.opacity(0.90))
                    : secondary
                )
                .padding(.horizontal, 17)
                .padding(.vertical, 14)
                .background(
                    canShape
                    ? (isDarkMode ? raisedPaper : Color(red: 0.09, green: 0.09, blue: 0.08))
                    : raisedPaper
                )
                .clipShape(Capsule())
            }
            .buttonStyle(LogIdeaPressStyle())
            .disabled(!canShape)

            Button {
                haptic(.light)
            } label: {
                Text("Save to inbox without analyzing")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(secondary)
                    .padding(.vertical, 5)
            }
            .buttonStyle(LogIdeaPressStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 13)
        .background(background)
    }

    private var canShape: Bool {
        captureMode != .text ||
        ideaText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 12
    }

    private var shapeScreen: some View {
        VStack(spacing: 0) {
            shapeTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 9) {
                        eyebrow("SHAPE THE IDEA")

                        Text("Before we judge it,\nlet’s define it.")
                            .font(.system(size: 36, weight: .black))
                            .tracking(-1.8)
                            .lineSpacing(-5)
                            .foregroundStyle(ink)

                        Text("Kindling should analyze the business you actually mean — not make assumptions from one sentence.")
                            .font(.system(size: 12))
                            .foregroundStyle(secondary)
                            .lineSpacing(4)
                    }

                    originalIdeaCard

                    ShapeField(
                        number: "01",
                        title: "Who has this problem?",
                        placeholder: "Example: busy families with 2–4 children",
                        text: $customer,
                        accent: blue,
                        paper: paper,
                        ink: ink,
                        secondary: secondary,
                        border: border
                    )

                    ShapeField(
                        number: "02",
                        title: "What problem are you solving?",
                        placeholder: "Example: grocery overspending, food waste, and weekly planning stress",
                        text: $problem,
                        accent: coral,
                        paper: paper,
                        ink: ink,
                        secondary: secondary,
                        border: border
                    )

                    categorySection
                    businessModelSection
                    urgencySection
                    notesSection
                    shapeInsight
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 130)
            }

            shapeBottomBar
        }
    }

    private var shapeTopBar: some View {
        HStack {
            Button {
                haptic(.light)
                stage = .capture
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(paper)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(border))
            }
            .buttonStyle(LogIdeaPressStyle())

            Spacer()

            Text("KINDLING®")
                .font(.system(size: 16, weight: .black))
                .tracking(2)
                .foregroundStyle(ink)

            Spacer()

            Text("02")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(ink)
                .frame(width: 40, height: 40)
                .background(paper)
                .clipShape(Circle())
                .overlay(Circle().stroke(border))
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var originalIdeaCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ORIGINAL THOUGHT")
                .font(.system(size: 7, weight: .black))
                .tracking(0.8)

            Text(
                ideaText.isEmpty
                ? "Captured from \(captureMode.title.lowercased())."
                : ideaText
            )
            .font(.system(size: 11, weight: .medium))
            .lineSpacing(3)
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 9) {
            fieldLabel("03", "What kind of business is this?")

            FlowChoiceGrid(
                options: [
                    "Software / app",
                    "Local service",
                    "E-commerce",
                    "Marketplace",
                    "Physical product",
                    "Creator / media",
                    "Not sure yet"
                ],
                selection: $selectedCategory,
                accent: pink,
                paper: paper,
                ink: ink,
                border: border
            )
        }
    }

    private var businessModelSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            fieldLabel("04", "How might it make money?")

            TextField(
                "Subscription, service fee, product sale, marketplace take rate...",
                text: $businessModel,
                axis: .vertical
            )
            .font(.system(size: 12))
            .foregroundStyle(ink)
            .lineLimit(3...6)
            .padding(13)
            .background(paper)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(border)
            )

            Text("OPTIONAL · Kindling can help determine this later.")
                .font(.system(size: 7, weight: .black))
                .tracking(0.7)
                .foregroundStyle(secondary)
        }
    }

    private var urgencySection: some View {
        VStack(alignment: .leading, spacing: 9) {
            fieldLabel("05", "What are you trying to decide?")

            FlowChoiceGrid(
                options: [
                    "Just exploring",
                    "Should I validate it?",
                    "Should I build it?",
                    "Should I invest money?",
                    "Should I pivot an existing idea?"
                ],
                selection: $selectedUrgency,
                accent: green,
                paper: paper,
                ink: ink,
                border: border
            )
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            fieldLabel("06", "Anything Kindling should know?")

            TextEditor(text: $notes)
                .font(.system(size: 12))
                .foregroundStyle(ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 110)
                .padding(11)
                .background(paper)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(border)
                )
        }
    }

    private var shapeInsight: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("✦ KINDLING AI")
                .font(.system(size: 7, weight: .black))
                .tracking(0.9)
                .foregroundStyle(secondary)

            Text("We’ll analyze the uncertainty — not hide it.")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(ink)

            Text("Anything you leave blank can stay an explicit assumption in the report. Kindling should tell you what it knows, what it inferred, and what still needs validation.")
                .font(.system(size: 10))
                .foregroundStyle(secondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(raisedPaper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var shapeBottomBar: some View {
        VStack(spacing: 8) {
            Button {
                haptic(.success)
                stage = .ready
            } label: {
                HStack {
                    Text("Create idea")
                    Spacer()
                    Image(systemName: "sparkles")
                }
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(
                    isDarkMode
                    ? ink
                    : Color.white.opacity(0.90)
                )
                .padding(.horizontal, 17)
                .padding(.vertical, 14)
                .background(
                    isDarkMode
                    ? raisedPaper
                    : Color(red: 0.09, green: 0.09, blue: 0.08)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(LogIdeaPressStyle())

            Text("You can edit all of this later.")
                .font(.system(size: 8))
                .foregroundStyle(secondary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 13)
        .background(background)
    }

    private var readyScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(orange)
                    .frame(height: 220)
                    .rotationEffect(.degrees(-2))

                VStack(alignment: .leading, spacing: 8) {
                    Text("IDEA CAPTURED")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .black))

                    Text(readyTitle)
                        .font(.system(size: 30, weight: .black))
                        .tracking(-1.2)
                        .lineLimit(2)

                    Text(selectedCategory)
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundStyle(ink)
                .padding(22)
                .frame(maxWidth: .infinity, maxHeight: 220, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 9) {
                eyebrow("WHAT HAPPENS NEXT")

                Text("Now Kindling can decide what needs to be researched.")
                    .font(.system(size: 25, weight: .black))
                    .tracking(-1)
                    .foregroundStyle(ink)

                Text("The next step is the Idea Report: viability, entry difficulty, competitors, momentum, founder fit, niche opportunities, and the evidence behind the recommendation.")
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
                    .lineSpacing(4)
            }

            VStack(spacing: 8) {
                Button {
                    haptic(.medium)
                } label: {
                    HStack {
                        Text("Analyze this idea")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(
                        isDarkMode
                        ? ink
                        : Color.white.opacity(0.90)
                    )
                    .padding(.horizontal, 17)
                    .padding(.vertical, 14)
                    .background(
                        isDarkMode
                        ? raisedPaper
                        : Color(red: 0.09, green: 0.09, blue: 0.08)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(LogIdeaPressStyle())

                Button {
                    haptic(.light)
                    dismiss()
                } label: {
                    Text("Save to inbox and return home")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(LogIdeaPressStyle())
            }

            Spacer()
        }
        .padding(22)
    }

    private var readyTitle: String {
        if !problem.isEmpty {
            return problem
        }

        if !ideaText.isEmpty {
            return ideaText
        }

        return "New business idea"
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(paper)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(border))
            }
            .buttonStyle(LogIdeaPressStyle())

            Spacer()

            Text("KINDLING®")
                .font(.system(size: 16, weight: .black))
                .tracking(2)
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
            .buttonStyle(LogIdeaPressStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func eyebrow(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .black))
            .tracking(1.2)
            .foregroundStyle(secondary)
    }

    private func fieldLabel(_ number: String, _ title: String) -> some View {
        HStack(spacing: 9) {
            Text(number)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(ink)
                .frame(width: 28, height: 28)
                .background(raisedPaper)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            Text(title)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(ink)
        }
    }

    private func color(for mode: IdeaCaptureMode) -> Color {
        switch mode {
        case .text: return orange
        case .voice: return coral
        case .link: return blue
        case .photo: return pink
        }
    }

    private func selectCaptureMode(_ mode: IdeaCaptureMode) {
        haptic(.selection)

        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            captureMode = mode
        }

        if mode == .text {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                ideaFieldFocused = true
            }
        }
    }

    private enum HapticKind {
        case selection
        case light
        case medium
        case success
    }

    private func haptic(_ kind: HapticKind) {
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

enum LogIdeaStage {
    case capture
    case shape
    case ready
}

enum IdeaCaptureMode: String, CaseIterable, Identifiable {
    case text
    case voice
    case link
    case photo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Type"
        case .voice: return "Voice"
        case .link: return "Link"
        case .photo: return "Photo"
        }
    }

    var icon: String {
        switch self {
        case .text: return "text.cursor"
        case .voice: return "waveform"
        case .link: return "link"
        case .photo: return "camera"
        }
    }
}

struct ShapeField: View {
    let number: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let accent: Color
    let paper: Color
    let ink: Color
    let secondary: Color
    let border: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Text(number)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 28, height: 28)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                Text(title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(ink)
            }

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 12))
                .foregroundStyle(ink)
                .lineLimit(3...7)
                .padding(13)
                .background(paper)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(border)
                )
        }
    }
}

struct FlowChoiceGrid: View {
    let options: [String]
    @Binding var selection: String
    let accent: Color
    let paper: Color
    let ink: Color
    let border: Color

    private let columns = [
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(options, id: \.self) { option in
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    selection = option
                } label: {
                    HStack {
                        Text(option)
                            .font(.system(size: 9, weight: .black))
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if selection == option {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .black))
                        }
                    }
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .padding(.horizontal, 11)
                    .background(selection == option ? accent : paper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selection == option ? ink.opacity(0.65) : border)
                    )
                }
                .buttonStyle(LogIdeaPressStyle())
            }
        }
    }
}

struct InboxRow: View {
    let title: String
    let detail: String
    let color: Color
    let ink: Color
    let secondary: Color

    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: 35, height: 35)
                .overlay(
                    Image(systemName: "lightbulb")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(ink)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(ink)

                Text(detail)
                    .font(.system(size: 8))
                    .foregroundStyle(secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(secondary)
        }
        .padding(12)
    }
}

struct LogIdeaPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview {
    LogIdeaView()
}
