import SwiftUI

struct KindlingWelcomeView: View {
    let onGetStarted: () -> Void
    let onLogin: () -> Void

    @State private var showLogin = false

    private let background = Color(red: 0.982, green: 0.965, blue: 0.925)
    private let ink = Color(red: 0.075, green: 0.075, blue: 0.065)
    private let secondary = Color(red: 0.25, green: 0.24, blue: 0.21)
    private let orange = Color(red: 1.00, green: 0.60, blue: 0.03)

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("KINDLING")
                        .font(.system(size: 16, weight: .black))
                        .tracking(2.5)
                        .foregroundStyle(ink)

                    Spacer()

                    Text("IDEA ARCHIVE")
                        .font(.system(size: 7, weight: .black))
                        .tracking(1.1)
                        .foregroundStyle(secondary)
                        .padding(.horizontal, 9)
                        .frame(height: 24)
                        .overlay(
                            Capsule()
                                .stroke(ink.opacity(0.18))
                        )
                }

                Spacer()

                VStack(spacing: 28) {
                    Image("KindlingTagline")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 330)
                        .accessibilityLabel("Never let a good idea go cold")

                    KindlingSparkMark()
                        .frame(width: 112, height: 112)

                    Text("A place to capture ideas, pressure-test them, and keep the right ones moving.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 310)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onGetStarted()
                    } label: {
                        HStack {
                            Text("GET STARTED")
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
                    .buttonStyle(EntryPressStyle())

                    Button {
                        showLogin = true
                    } label: {
                        Text("LOG IN")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.1)
                            .foregroundStyle(ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(EntryPressStyle())
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showLogin) {
            KindlingLoginSheet {
                showLogin = false
                onLogin()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct KindlingSparkMark: View {
    private let ink = Color(red: 0.075, green: 0.075, blue: 0.065)
    private let orange = Color(red: 1.00, green: 0.60, blue: 0.03)

    var body: some View {
        ZStack {
            Circle()
                .fill(orange)

            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(ink)

                Rectangle()
                    .fill(ink)
                    .frame(width: 42, height: 5)
                    .rotationEffect(.degrees(7))

                Rectangle()
                    .fill(ink)
                    .frame(width: 42, height: 5)
                    .rotationEffect(.degrees(-7))
            }
        }
        .rotationEffect(.degrees(-2))
    }
}

private struct KindlingLoginSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""

    let onLogin: () -> Void

    private let background = Color(red: 0.982, green: 0.965, blue: 0.925)
    private let paper = Color(red: 0.998, green: 0.992, blue: 0.975)
    private let ink = Color(red: 0.075, green: 0.075, blue: 0.065)
    private let secondary = Color(red: 0.25, green: 0.24, blue: 0.21)
    private let orange = Color(red: 1.00, green: 0.60, blue: 0.03)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("RETURNING FOUNDER")
                    .font(.system(size: 8, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(secondary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(ink)
                        .frame(width: 34, height: 34)
                }
            }

            Text("Welcome back.")
                .font(.system(size: 34, weight: .black))
                .tracking(-1.4)
                .foregroundStyle(ink)

            VStack(spacing: 10) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(ink.opacity(0.16))
                    )

                SecureField("Password", text: $password)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(ink.opacity(0.16))
                    )
            }
            .font(.system(size: 12, weight: .semibold))

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onLogin()
            } label: {
                HStack {
                    Text("LOG IN")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 10, weight: .black))
                .tracking(0.8)
                .foregroundStyle(background)
                .padding(.horizontal, 17)
                .frame(height: 50)
                .background(ink)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(EntryPressStyle())

            Text("Prototype login for now — real account authentication comes with the backend.")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(secondary)
                .lineSpacing(3)
        }
        .padding(22)
        .background(background.ignoresSafeArea())
    }
}

private struct EntryPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.978 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    KindlingWelcomeView(onGetStarted: {}, onLogin: {})
}
