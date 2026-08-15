import SwiftUI
import UIKit

struct PitchDeckPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSlideID: UUID?

    let idea: BusinessIdea?
    let executiveSummary: String
    let targetCustomer: String
    let positioning: String
    let revenueModel: String
    let goToMarket: String
    let operations: String
    let financialPlan: String
    let risks: String
    let milestones: String
    let planProgress: Int

    private let background = Color(red: 0.972, green: 0.955, blue: 0.925)
    private let paper = Color(red: 0.998, green: 0.992, blue: 0.975)
    private let ink = Color(red: 0.09, green: 0.09, blue: 0.08)
    private let secondary = Color(red: 0.24, green: 0.23, blue: 0.21)

    private let orange = Color(red: 0.96, green: 0.62, blue: 0.04)
    private let blue = Color(red: 0.34, green: 0.56, blue: 0.88)
    private let green = Color(red: 0.20, green: 0.66, blue: 0.36)
    private let pink = Color(red: 0.91, green: 0.54, blue: 0.68)
    private let coral = Color(red: 0.98, green: 0.38, blue: 0.33)

    private var ideaTitle: String {
        idea?.title ?? "AI Meal Planning"
    }

    private var slides: [PitchDeckSlide] {
        [
            PitchDeckSlide(
                number: "01",
                eyebrow: "OPENING",
                title: ideaTitle,
                body: cleanFirstSentence(executiveSummary),
                footer: "Never let a good idea go cold.",
                color: orange
            ),
            PitchDeckSlide(
                number: "02",
                eyebrow: "PROBLEM",
                title: "The pain is specific.",
                body: "The customer has a recurring problem worth solving: \(cleanFirstSentence(targetCustomer))",
                footer: "Start narrow. Prove the pain.",
                color: coral
            ),
            PitchDeckSlide(
                number: "03",
                eyebrow: "CUSTOMER",
                title: "Who it is for.",
                body: cleanBullets(targetCustomer),
                footer: "Early adopters before everyone else.",
                color: blue
            ),
            PitchDeckSlide(
                number: "04",
                eyebrow: "SOLUTION",
                title: "The offer.",
                body: cleanFirstSentence(positioning),
                footer: "One promise. One measurable outcome.",
                color: pink
            ),
            PitchDeckSlide(
                number: "05",
                eyebrow: "WHY NOW",
                title: "The opening.",
                body: "Kindling sees a sharper opportunity when the plan connects customer pain, timing, and a focused wedge.",
                footer: "Use the market window before it closes.",
                color: green
            ),
            PitchDeckSlide(
                number: "06",
                eyebrow: "BUSINESS MODEL",
                title: "How it makes money.",
                body: cleanBullets(revenueModel),
                footer: "Revenue should match felt value.",
                color: orange
            ),
            PitchDeckSlide(
                number: "07",
                eyebrow: "GO TO MARKET",
                title: "How the first customers find it.",
                body: cleanBullets(goToMarket),
                footer: "Validation before paid scale.",
                color: blue
            ),
            PitchDeckSlide(
                number: "08",
                eyebrow: "EXECUTION",
                title: "How it gets built.",
                body: cleanBullets(operations),
                footer: "Keep the first version painfully focused.",
                color: pink
            ),
            PitchDeckSlide(
                number: "09",
                eyebrow: "FINANCIALS + RISKS",
                title: "The assumptions to prove.",
                body: "\(cleanFirstSentence(financialPlan))\n\nBiggest risk: \(cleanFirstSentence(risks))",
                footer: "A deck is strongest when it is honest.",
                color: coral
            ),
            PitchDeckSlide(
                number: "10",
                eyebrow: "THE ASK",
                title: "What happens next.",
                body: cleanBullets(milestones),
                footer: "Ask for the resource that unlocks the next proof point.",
                color: green
            )
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        deckCarousel
                        slideList
                        exportPanel
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .background(background.ignoresSafeArea())
        }
        .onAppear {
            selectedSlideID = slides.first?.id
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(paper)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.08))
                    )
            }

            Spacer()

            Text("PITCH DECK")
                .font(.system(size: 8, weight: .black))
                .tracking(1.6)
                .foregroundStyle(secondary)

            Spacer()

            Text("\(planProgress)%")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(ink)
                .frame(width: 40, height: 40)
                .background(paper)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.08))
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GENERATED FROM BUSINESS PLAN")
                .font(.system(size: 8, weight: .black))
                .tracking(1.4)
                .foregroundStyle(secondary)

            Text("Investor story,\nslide by slide.")
                .font(.system(size: 39, weight: .black))
                .tracking(-2)
                .lineSpacing(-5)
                .foregroundStyle(ink)

            Text("This is a prototype deck preview. Later, this can export to PDF, Keynote, or PowerPoint once the backend is wired.")
                .font(.system(size: 11))
                .foregroundStyle(secondary)
                .lineSpacing(4)
        }
    }

    private var deckCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(slides) { slide in
                    PitchSlideCard(slide: slide)
                        .frame(width: 310, height: 420)
                        .id(slide.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedSlideID)
        .sensoryFeedback(.selection, trigger: selectedSlideID)
    }

    private var slideList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DECK OUTLINE")
                .font(.system(size: 8, weight: .black))
                .tracking(1.4)
                .foregroundStyle(secondary)

            ForEach(slides) { slide in
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.snappy(duration: 0.25, extraBounce: 0.02)) {
                        selectedSlideID = slide.id
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(slide.number)
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 34, height: 34)
                            .background(slide.color)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(slide.eyebrow)
                                .font(.system(size: 7, weight: .black))
                                .tracking(0.9)
                                .foregroundStyle(secondary)

                            Text(slide.title)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(ink)
                        }

                        Spacer()

                        Image(systemName: selectedSlideID == slide.id ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(selectedSlideID == slide.id ? ink : Color.black.opacity(0.18))
                    }
                    .padding(12)
                    .background(paper)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.07))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var exportPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("EXPORT")
                .font(.system(size: 8, weight: .black))
                .tracking(1.4)

            Text("Deck export comes next.")
                .font(.system(size: 22, weight: .black))
                .tracking(-0.7)

            Text("The preview is ready. The production version should let users export a PDF, send it to collaborators, or regenerate the deck for investor, partner, or personal-use formats.")
                .font(.system(size: 10))
                .lineSpacing(4)

            HStack(spacing: 8) {
                Button {} label: {
                    Text("PDF SOON")
                        .font(.system(size: 8, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(ink)
                        .clipShape(Capsule())
                }
                .disabled(true)

                Button {} label: {
                    Text("REGENERATE SOON")
                        .font(.system(size: 8, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(paper)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.08))
                        )
                }
                .disabled(true)
            }
        }
        .foregroundStyle(ink)
        .padding(17)
        .background(orange)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func cleanFirstSentence(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "•", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let periodIndex = cleaned.firstIndex(of: ".") {
            return String(cleaned[...periodIndex])
        }

        return cleaned.isEmpty ? "Add more detail to this section to improve the generated slide." : cleaned
    }

    private func cleanBullets(_ text: String) -> String {
        let lines = text
            .split(separator: "\n")
            .map { line in
                line
                    .replacingOccurrences(of: "•", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .prefix(4)

        if lines.isEmpty {
            return "Add more detail to this section to improve the generated slide."
        }

        return lines.map { "• \($0)" }.joined(separator: "\n")
    }
}

struct PitchDeckSlide: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let eyebrow: String
    let title: String
    let body: String
    let footer: String
    let color: Color
}

struct PitchSlideCard: View {
    let slide: PitchDeckSlide

    private let ink = Color(red: 0.09, green: 0.09, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(slide.eyebrow)
                        .font(.system(size: 8, weight: .black))
                        .tracking(1.3)

                    Text("SLIDE \(slide.number)")
                        .font(.system(size: 7, weight: .black))
                        .tracking(1)
                        .opacity(0.62)
                }

                Spacer()

                Text(slide.number)
                    .font(.system(size: 38, weight: .black))
                    .tracking(-1.2)
            }

            Rectangle()
                .fill(ink.opacity(0.24))
                .frame(height: 1)
                .padding(.vertical, 18)

            Text(slide.title)
                .font(.system(size: 33, weight: .black))
                .tracking(-1.4)
                .lineSpacing(-4)
                .minimumScaleFactor(0.82)

            Text(slide.body)
                .font(.system(size: 13, weight: .medium))
                .lineSpacing(5)
                .padding(.top, 18)

            Spacer()

            HStack {
                Text(slide.footer.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.8)
                    .lineLimit(2)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .black))
            }
        }
        .foregroundStyle(ink)
        .padding(22)
        .background(slide.color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    PitchDeckPreviewView(
        idea: nil,
        executiveSummary: "AI Meal Planning helps families reduce grocery waste and spending.",
        targetCustomer: "Primary customer: busy families.\n• Shops weekly\n• Wants savings",
        positioning: "Plan meals around what you already have.",
        revenueModel: "Monthly subscription.\n$9.99–$14.99 / month",
        goToMarket: "Start with budget-conscious communities.",
        operations: "MVP team: founder, contractor, backend support.",
        financialPlan: "Estimated MVP cost: $8,000–$20,000.",
        risks: "Highest risk: willingness to pay.",
        milestones: "30 days: 15 interviews.\n60 days: prototype.\n90 days: MVP decision.",
        planProgress: 72
    )
}
