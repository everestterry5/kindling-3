import SwiftUI

struct WelcomeQuestionnaireView: View {
    let onFinish: () -> Void

    @State private var step = 0
    @State private var answers = OnboardingAnswers()
    @State private var selectedChallenges: Set<String> = []
    @State private var selectedGoals: Set<String> = []

    private let background = Color(red: 0.982, green: 0.965, blue: 0.925)
    private let paper = Color(red: 0.998, green: 0.992, blue: 0.975)
    private let ink = Color(red: 0.075, green: 0.075, blue: 0.065)
    private let secondary = Color(red: 0.25, green: 0.24, blue: 0.21)
    private let orange = Color(red: 1.00, green: 0.60, blue: 0.03)
    private let blue = Color(red: 0.43, green: 0.68, blue: 0.96)
    private let green = Color(red: 0.63, green: 0.84, blue: 0.36)
    private let pink = Color(red: 0.92, green: 0.65, blue: 0.75)
    private let coral = Color(red: 0.98, green: 0.42, blue: 0.32)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            if step < questions.count {
                questionScreen
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                completionScreen
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.90), value: step)
    }

    private var questionScreen: some View {
        let question = questions[step]

        return VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(question.eyebrow)
                            .font(.system(size: 8, weight: .black))
                            .tracking(1.4)
                            .foregroundStyle(secondary)

                        Text(question.title)
                            .font(.system(size: 34, weight: .black))
                            .tracking(-1.5)
                            .lineSpacing(-4)
                            .foregroundStyle(ink)

                        Text(question.subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(secondary)
                            .lineSpacing(4)
                    }

                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            answerButton(
                                question: question,
                                option: option,
                                index: index
                            )
                        }
                    }

                    if question.allowsMultiple {
                        Text("SELECT ALL THAT APPLY")
                            .font(.system(size: 7, weight: .black))
                            .tracking(1.1)
                            .foregroundStyle(secondary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 26)
                .padding(.bottom, 115)
            }

            bottomControls(question)
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    guard step > 0 else { return }
                    step -= 1
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(ink)
                        .frame(width: 38, height: 38)
                }
                .opacity(step == 0 ? 0 : 1)
                .disabled(step == 0)

                Spacer()

                Text("KINDLING")
                    .font(.system(size: 15, weight: .black))
                    .tracking(2.2)
                    .foregroundStyle(ink)

                Spacer()

                Text(String(format: "%02d", step + 1))
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(ink.opacity(0.20)))
            }

            GeometryReader { geometry in
                HStack(spacing: 5) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? ink : ink.opacity(0.12))
                    }
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func answerButton(
        question: OnboardingQuestion,
        option: String,
        index: Int
    ) -> some View {
        let selected = isSelected(question.id, option: option)
        let color = optionColor(index)

        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            select(question, option: option)
        } label: {
            HStack(spacing: 13) {
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(option)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(selected ? ink : ink.opacity(0.18))
            }
            .padding(12)
            .background(selected ? color.opacity(0.22) : paper)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(selected ? ink.opacity(0.70) : ink.opacity(0.10), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func bottomControls(_ question: OnboardingQuestion) -> some View {
        VStack(spacing: 8) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                advance()
            } label: {
                HStack {
                    Text(step == questions.count - 1 ? "FINISH SETUP" : "CONTINUE")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 10, weight: .black))
                .tracking(0.8)
                .foregroundStyle(background)
                .padding(.horizontal, 17)
                .frame(height: 52)
                .background(ink)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .disabled(!canContinue(question))
            .opacity(canContinue(question) ? 1 : 0.30)

            if question.optional {
                Button("SKIP") {
                    advance()
                }
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundStyle(secondary)
                .padding(.vertical, 5)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(background)
    }

    private var completionScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            Text("PROFILE READY")
                .font(.system(size: 8, weight: .black))
                .tracking(1.5)
                .foregroundStyle(secondary)

            Text("Kindling knows\nwhat matters to you.")
                .font(.system(size: 38, weight: .black))
                .tracking(-1.8)
                .lineSpacing(-5)
                .foregroundStyle(ink)

            Text("This profile will shape founder fit, recommendations, validation guidance, and how Kindling ranks your ideas.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(secondary)
                .lineSpacing(4)

            VStack(spacing: 8) {
                summaryRow("STAGE", answers.stage, color: orange)
                summaryRow("EXPERIENCE", answers.experience, color: blue)
                summaryRow("DECISION STYLE", answers.decisionStyle, color: pink)
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onFinish()
            } label: {
                HStack {
                    Text("ENTER KINDLING")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 10, weight: .black))
                .tracking(0.8)
                .foregroundStyle(background)
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(ink)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
    }

    private func summaryRow(
        _ label: String,
        _ value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(color)
                .frame(width: 10, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 7, weight: .black))
                    .tracking(1)
                    .foregroundStyle(secondary)

                Text(value.isEmpty ? "Not specified" : value)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(ink)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 58)
        .background(paper)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(ink.opacity(0.10))
        )
    }

    private func select(_ question: OnboardingQuestion, option: String) {
        switch question.id {
        case "stage": answers.stage = option
        case "challenge":
            toggle(option, in: &selectedChallenges)
            answers.challenges = Array(selectedChallenges)
        case "businessType": answers.businessType = option
        case "team": answers.teamSize = option
        case "experience": answers.experience = option
        case "goals":
            toggle(option, in: &selectedGoals)
            answers.goals = Array(selectedGoals)
        case "time": answers.timeAvailable = option
        case "budget": answers.budgetComfort = option
        case "decision": answers.decisionStyle = option
        case "discovery": answers.discoverySource = option
        default: break
        }
    }

    private func isSelected(_ questionID: String, option: String) -> Bool {
        switch questionID {
        case "stage": return answers.stage == option
        case "challenge": return selectedChallenges.contains(option)
        case "businessType": return answers.businessType == option
        case "team": return answers.teamSize == option
        case "experience": return answers.experience == option
        case "goals": return selectedGoals.contains(option)
        case "time": return answers.timeAvailable == option
        case "budget": return answers.budgetComfort == option
        case "decision": return answers.decisionStyle == option
        case "discovery": return answers.discoverySource == option
        default: return false
        }
    }

    private func canContinue(_ question: OnboardingQuestion) -> Bool {
        if question.optional { return true }

        switch question.id {
        case "stage": return !answers.stage.isEmpty
        case "challenge": return !selectedChallenges.isEmpty
        case "businessType": return !answers.businessType.isEmpty
        case "team": return !answers.teamSize.isEmpty
        case "experience": return !answers.experience.isEmpty
        case "goals": return !selectedGoals.isEmpty
        case "time": return !answers.timeAvailable.isEmpty
        case "budget": return !answers.budgetComfort.isEmpty
        case "decision": return !answers.decisionStyle.isEmpty
        default: return true
        }
    }

    private func advance() {
        if step < questions.count - 1 {
            step += 1
        } else {
            step = questions.count
        }
    }

    private func toggle(_ option: String, in set: inout Set<String>) {
        if set.contains(option) {
            set.remove(option)
        } else {
            set.insert(option)
        }
    }

    private func optionColor(_ index: Int) -> Color {
        [coral, blue, orange, pink, green][index % 5]
    }

    private var questions: [OnboardingQuestion] {
        [
            OnboardingQuestion(
                id: "stage",
                eyebrow: "01 · WHERE YOU ARE",
                title: "Where are you in your entrepreneurial journey?",
                subtitle: "This helps Kindling decide how much weight to give validation, execution, and growth.",
                options: [
                    "I’m exploring ideas",
                    "I have an idea I want to validate",
                    "I’m building something now",
                    "I already run a business",
                    "I’m looking for my next opportunity"
                ]
            ),
            OnboardingQuestion(
                id: "challenge",
                eyebrow: "02 · CURRENT CHALLENGE",
                title: "What do you need the most help with right now?",
                subtitle: "Pick everything that feels relevant.",
                options: [
                    "Finding a strong business idea",
                    "Knowing if an idea is actually viable",
                    "Finding a niche",
                    "Understanding competitors",
                    "Building a business plan",
                    "Getting customers",
                    "Deciding what to work on next"
                ],
                allowsMultiple: true
            ),
            OnboardingQuestion(
                id: "businessType",
                eyebrow: "03 · BUSINESS TYPE",
                title: "What kind of business are you most interested in building?",
                subtitle: "Kindling can adjust opportunity analysis around different business models.",
                options: [
                    "Software / app",
                    "Local service",
                    "E-commerce",
                    "Marketplace",
                    "Creator / media business",
                    "Physical product",
                    "I’m open to anything"
                ]
            ),
            OnboardingQuestion(
                id: "team",
                eyebrow: "04 · TEAM",
                title: "How are you building?",
                subtitle: "Your available team changes what opportunities are practical.",
                options: [
                    "Just me",
                    "Me + a cofounder",
                    "Small team",
                    "Existing company / team",
                    "Not sure yet"
                ]
            ),
            OnboardingQuestion(
                id: "experience",
                eyebrow: "05 · EXPERIENCE",
                title: "How experienced are you with starting businesses?",
                subtitle: "Kindling can explain more when you need it and move faster when you don’t.",
                options: [
                    "This is my first time",
                    "I’ve tried a few ideas",
                    "I’ve launched a business before",
                    "I run businesses regularly"
                ]
            ),
            OnboardingQuestion(
                id: "goals",
                eyebrow: "06 · WHAT YOU WANT",
                title: "What would make Kindling valuable to you?",
                subtitle: "Choose the outcomes you care about most.",
                options: [
                    "Avoid wasting money on bad ideas",
                    "Find opportunities before others",
                    "Build something profitable",
                    "Replace or supplement my income",
                    "Build a scalable company",
                    "Organize all my business ideas",
                    "Move from thinking to actually launching"
                ],
                allowsMultiple: true
            ),
            OnboardingQuestion(
                id: "time",
                eyebrow: "07 · TIME",
                title: "How much time can you realistically give a new business?",
                subtitle: "Founder Fit will use this when judging how practical an idea is for you.",
                options: [
                    "Less than 5 hours / week",
                    "5–10 hours / week",
                    "10–20 hours / week",
                    "20–40 hours / week",
                    "Full time"
                ]
            ),
            OnboardingQuestion(
                id: "budget",
                eyebrow: "08 · BUDGET",
                title: "What level of startup investment feels realistic?",
                subtitle: "This is only used to personalize recommendations. You can change it later.",
                options: [
                    "Under $1,000",
                    "$1,000–$5,000",
                    "$5,000–$15,000",
                    "$15,000–$50,000",
                    "$50,000+",
                    "I’m not sure yet"
                ]
            ),
            OnboardingQuestion(
                id: "decision",
                eyebrow: "09 · DECISION STYLE",
                title: "How do you usually decide whether an idea is worth pursuing?",
                subtitle: "Kindling can adapt how it presents recommendations to you.",
                options: [
                    "Show me the numbers",
                    "Show me the customer problem",
                    "Show me the upside and downside",
                    "Give me a clear recommendation",
                    "Let me explore everything myself"
                ]
            ),
            OnboardingQuestion(
                id: "discovery",
                eyebrow: "10 · ONE LAST THING",
                title: "How did you find Kindling?",
                subtitle: "Optional — this helps us understand how people discover the app.",
                options: [
                    "Friend or colleague",
                    "Social media",
                    "Search",
                    "App Store",
                    "Creator / podcast / newsletter",
                    "Other"
                ],
                optional: true
            )
        ]
    }
}

struct OnboardingQuestion: Identifiable {
    let id: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let options: [String]
    var allowsMultiple: Bool = false
    var optional: Bool = false
}

struct OnboardingAnswers {
    var stage = ""
    var challenges: [String] = []
    var businessType = ""
    var teamSize = ""
    var experience = ""
    var goals: [String] = []
    var timeAvailable = ""
    var budgetComfort = ""
    var decisionStyle = ""
    var discoverySource = ""
}

#Preview {
    WelcomeQuestionnaireView(onFinish: {})
}
