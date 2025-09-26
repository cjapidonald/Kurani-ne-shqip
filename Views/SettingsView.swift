import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var showingImporter = false
    @State private var toastVisible = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("settings.account"))) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStringKey("settings.account.offline"))
                            .foregroundColor(.kuraniTextSecondary)
                    }
                    .appleCard()
                    .padding(.horizontal, 12)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section(header: Text(LocalizedStringKey("settings.translation"))) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(viewModel.isUsingSampleTranslation ? LocalizedStringKey("settings.translation.sample") : LocalizedStringKey("settings.translation.loaded"))
                                .foregroundColor(.kuraniTextSecondary)
                            Spacer()
                            if viewModel.isImporting {
                                ProgressView()
                                    .tint(.kuraniAccentLight)
                            }
                        }

                        Button(LocalizedStringKey("settings.import")) {
                            showingImporter = true
                        }
                        .buttonStyle(GradientButtonStyle())
                    }
                    .appleCard()
                    .padding(.horizontal, 12)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section(header: Text(LocalizedStringKey("settings.about"))) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey("settings.about.disclaimer"))
                            .foregroundColor(.kuraniTextSecondary)
                        HStack {
                            Text(LocalizedStringKey("settings.version"))
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(.kuraniTextSecondary)
                        }
                    }
                    .appleCard()
                    .padding(.horizontal, 12)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .listRowSeparator(.hidden)
            .background(KuraniTheme.backgroundGradient.ignoresSafeArea())
            .tint(Color.kuraniAccentLight)
            .navigationTitle(LocalizedStringKey("settings.title"))
            .toolbarBackground(Color.kuraniDarkBackground.opacity(0.4), for: .navigationBar)
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    Task { await importTranslation(url: url) }
                case .failure:
                    viewModel.toast = LocalizedStringKey("settings.import.invalid")
                }
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
        .background(KuraniTheme.backgroundGradient.ignoresSafeArea())
    }

    private func importTranslation(url: URL) async {
        await viewModel.importTranslation(from: url)
    }
}
