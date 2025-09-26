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
                    .padding(.top)

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        authManager.prepareAppleRequest(request)
                    } onCompletion: { result in
                        Task { await authManager.handleAppleCompletion(result) }
                    }
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Divider()
                        .background(Color.accentLight.opacity(0.4))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("signin.email"))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.textSecondary)
                        TextField(LocalizedStringKey("signin.email.placeholder"), text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(12)
                            .background(Color.primarySurface.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundColor(.textPrimary)
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
                .padding()
                .background(Color.primarySurface.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Spacer()
            }
            .padding()
            .background(Color.darkBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("action.cancel")) { dismiss() }
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
            .onChange(of: authManager.emailMagicLinkSent) { newValue in
                if newValue {
                    showEmailAlert = true
                }
            }
        }
    }

    @MainActor
    private func sendMagicLink() async {
        guard !email.isEmpty else { return }
        isSendingEmail = true
        await authManager.sendMagicLink(to: email)
        isSendingEmail = false
    }
}

