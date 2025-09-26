import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var authManager: AuthManager

    @State private var showingImporter = false
    @State private var showingSignInSheet = false
    @State private var toastVisible = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("settings.account"))) {
                    if let user = authManager.user {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.email ?? "")
                                .foregroundColor(.textPrimary)
                            Text(user.id.uuidString)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Text(LocalizedStringKey("notes.signinRequired"))
                            .foregroundColor(.textSecondary)
                    }

                    if authManager.userId == nil {
                        Button(LocalizedStringKey("settings.signin")) {
                            showingSignInSheet = true
                        }
                    } else {
                        Button(LocalizedStringKey("settings.signout")) {
                            Task { await viewModel.signOut() }
                        }
                        .foregroundColor(.red)
                    }
                }
                .listRowBackground(Color.primarySurface)

                Section(header: Text(LocalizedStringKey("settings.translation"))) {
                    HStack {
                        Text(viewModel.isUsingSampleTranslation ? LocalizedStringKey("settings.translation.sample") : LocalizedStringKey("settings.translation.loaded"))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        if viewModel.isImporting {
                            ProgressView()
                        }
                    }

                    Button(LocalizedStringKey("settings.import")) {
                        showingImporter = true
                    }
                }
                .listRowBackground(Color.primarySurface)

                Section(header: Text(LocalizedStringKey("settings.about"))) {
                    Text(LocalizedStringKey("settings.about.disclaimer"))
                        .foregroundColor(.textSecondary)
                    HStack {
                        Text(LocalizedStringKey("settings.version"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.textSecondary)
                    }
                }
                .listRowBackground(Color.primarySurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .tint(Color.accentBrand)
            .navigationTitle(LocalizedStringKey("settings.title"))
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    Task { await importTranslation(url: url) }
                case .failure:
                    viewModel.toast = LocalizedStringKey("settings.import.invalid")
                }
            }
            .sheet(isPresented: $showingSignInSheet) {
                SignInPromptView()
                    .environmentObject(authManager)
            }
            .overlay(alignment: .bottom) {
                if toastVisible, let message = viewModel.toast {
                    ToastView(message: message)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: viewModel.toast) { _, newValue in
                guard newValue != nil else { return }
                withAnimation { toastVisible = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { toastVisible = false }
                    viewModel.toast = nil
                }
            }
        }
    }

    private func importTranslation(url: URL) async {
        await viewModel.importTranslation(from: url)
    }
}
