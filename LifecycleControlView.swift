import SwiftUI
import UIKit

struct LifecycleControlView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: KindlingStore
    @AppStorage("kindlingDarkMode") private var isDarkMode = false

    let ideaID: UUID

    private var idea: BusinessIdea? {
        store.idea(withID: ideaID)
    }

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
        : Color.black.opacity(0.08)
    }

    private let orange = Color(red: 0.96, green: 0.62, blue: 0.04)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let idea {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("IDEA LIFECYCLE")
                                .font(.system(size: 8, weight: .black))
                                .tracking(1.4)
                                .foregroundStyle(secondary)

                            Text(idea.title)
                                .font(.system(size: 28, weight: .black))
                                .tracking(-0.8)
                                .foregroundStyle(ink)

                            Text(
                                idea.decision == .pause
                                ? "Paused · \(idea.lifecycle.rawValue)"
                                : idea.lifecycle.rawValue
                            )
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(ink)
                        }

                        lifecycleTrack(current: idea.lifecycle)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("WHAT THIS STAGE MEANS")
                                .font(.system(size: 8, weight: .black))
                                .tracking(1.3)
                                .foregroundStyle(secondary)

                            Text(idea.lifecycle.shortGuidance)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ink)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(paper)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(border)
                        )

                        VStack(spacing: 9) {
                            ForEach(IdeaLifecycle.allCases, id: \.self) { stage in
                                stageRow(
                                    stage: stage,
                                    current: idea.lifecycle
                                )
                            }
                        }

                        HStack(spacing: 10) {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                store.retreatLifecycle(id: ideaID)
                            } label: {
                                Label("Back a stage", systemImage: "arrow.left")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(paper)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(border)
                                    )
                            }
                            .disabled(idea.lifecycle.previous == nil)

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                store.advanceLifecycle(id: ideaID)
                            } label: {
                                Label("Next stage", systemImage: "arrow.right")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                            .disabled(idea.lifecycle.next == nil)
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                            if idea.decision == .pause {
                                store.resumeIdea(id: ideaID)
                            } else {
                                store.pauseIdea(id: ideaID)
                            }
                        } label: {
                            HStack {
                                Image(systemName: idea.decision == .pause ? "play.fill" : "pause.fill")

                                Text(
                                    idea.decision == .pause
                                    ? "RESUME IDEA"
                                    : "PAUSE IDEA"
                                )

                                Spacer()

                                Text(
                                    idea.decision == .pause
                                    ? "Return to active portfolio"
                                    : "Keep it without prioritizing it"
                                )
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(secondary)
                            }
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(ink)
                            .padding(.horizontal, 15)
                            .frame(height: 52)
                            .background(paper)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(border)
                            )
                        }
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
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(ink)
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private func lifecycleTrack(
        current: IdeaLifecycle
    ) -> some View {
        let stages = IdeaLifecycle.allCases
        let currentIndex = stages.firstIndex(of: current) ?? 0

        return HStack(spacing: 5) {
            ForEach(Array(stages.enumerated()), id: \.element) { index, stage in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(index <= currentIndex ? orange : border)
                        .frame(height: 5)

                    Text(stage.rawValue.prefix(3).uppercased())
                        .font(.system(size: 6, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(
                            index == currentIndex
                            ? ink
                            : secondary
                        )
                }
            }
        }
    }

    private func stageRow(
        stage: IdeaLifecycle,
        current: IdeaLifecycle
    ) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            store.updateLifecycle(
                id: ideaID,
                lifecycle: stage
            )
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(stage == current ? orange : paper)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(
                            systemName:
                                stage == current
                                ? "checkmark"
                                : "circle"
                        )
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(ink)
                    )
                    .overlay(
                        Circle()
                            .stroke(border)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.rawValue)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(ink)

                    Text(stage.shortGuidance)
                        .font(.system(size: 9))
                        .foregroundStyle(secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(13)
            .background(paper)
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(
                        stage == current
                        ? orange.opacity(0.8)
                        : border
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
