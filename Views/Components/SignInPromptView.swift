import SwiftUI
import AuthenticationServices

struct SignInPromptView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isSendingEmail = false
    @State private var showEmailAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                BrandHeader(titleKey: "notes.signInPrompt", subtitle: "notes.noAccess")
                    .padding(.horizontal, 12)
                    .padding(.top)

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        authManager.prepareAppleRequest(request)
                    } onCompletion: { result in
                        Task { await authManager.handleAppleCompletion(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.25), radius: 18, y: 12)

                    Divider()
                        .background(Color.kuraniAccentLight.opacity(0.4))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("signin.email"))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.kuraniTextSecondary)
                        TextField(LocalizedStringKey("signin.email.placeholder"), text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(14)
                            .background(Color.kuraniPrimarySurface.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundColor(.kuraniTextPrimary)
                        Button {
                            Task { await sendMagicLink() }
                        } label: {
                            Text(LocalizedStringKey("signin.email"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GradientButtonStyle())
                        .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingEmail)
                    }
                }
                .appleCard(cornerRadius: 26)
                .padding(.horizontal, 8)

                Spacer()
            }
            .padding()
            .background(KuraniTheme.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("action.cancel")) { dismiss() }
                        .tint(.kuraniAccentLight)
                }
            }
            .onReceive(authManager.$userId) { userId in
                if userId != nil {
                    dismiss()
                }
            }
            .alert(LocalizedStringKey("signin.email"), isPresented: $showEmailAlert) {
                Button(LocalizedStringKey("action.ok"), role: .cancel) {}
            } message: {
                Text(LocalizedStringKey("signin.email.sent"))
            }
            .onChange(of: authManager.emailMagicLinkSent) { oldValue, newValue in
                if newValue && !oldValue {
                    showEmailAlert = true
                }
            }
        }
        .background(KuraniTheme.backgroundGradient.ignoresSafeArea())
    }

    @MainActor
    private func sendMagicLink() async {
        guard !email.isEmpty else { return }
        isSendingEmail = true
        await authManager.sendMagicLink(to: email)
        isSendingEmail = false
    }
}

