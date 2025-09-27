import SwiftUI
import Network

struct AppStartTaskModifier: ViewModifier {
    @EnvironmentObject private var authManager: AuthManager

    private let quranServiceFactory: () -> QuranServicing
    @State private var hasRunInitialChecks = false
    @State private var hasCompletedPostSignInChecks = false
    @State private var isPresentingSignIn = false
    @State private var diagnosticsMessage: LocalizedStringKey?
    @State private var isDiagnosticsToastVisible = false
    @State private var diagnosticsDismissTask: Task<Void, Never>?

    init(quranServiceFactory: @escaping () -> QuranServicing = { QuranService() }) {
        self.quranServiceFactory = quranServiceFactory
    }

    func body(content: Content) -> some View {
        content
            .task {
                guard !hasRunInitialChecks else { return }
                hasRunInitialChecks = true
                await runInitialChecks()
                if authManager.userId != nil && !hasCompletedPostSignInChecks {
                    hasCompletedPostSignInChecks = true
                    await runPostSignInChecks()
                }
            }
            .onReceive(authManager.$userId) { userId in
                guard userId != nil else { return }
                guard !hasCompletedPostSignInChecks else { return }
                hasCompletedPostSignInChecks = true
                Task { await runPostSignInChecks() }
            }
            .overlay(alignment: .bottom) {
                if authManager.userId == nil {
                    Button {
                        isPresentingSignIn = true
                    } label: {
                        Text("Temporary Sign In")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.kuraniAccentBrand)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 6)
                    }
                    .padding()
                    .accessibilityLabel("Temporary sign-in with email")
                }
            }
            .sheet(isPresented: $isPresentingSignIn) {
                SignInPromptView()
                    .environmentObject(authManager)
            }
            .overlay(alignment: .top) {
                if isDiagnosticsToastVisible, let diagnosticsMessage {
                    ToastView(message: diagnosticsMessage)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
    }

    private func runInitialChecks() async {
        await checkNetwork()
        await loadWords()
        await rebuildAyah()
    }

    private func runPostSignInChecks() async {
        let service = quranServiceFactory()
        var encounteredError = false

        do {
            _ = try await service.getMyNotesForSurah(surah: 1)
        } catch {
            encounteredError = true
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey("Unable to verify note access."))
            }
        }

        do {
            _ = try await service.isFavorite(surah: 1, ayah: 1)
        } catch {
            encounteredError = true
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey("Unable to verify favourite access."))
            }
        }

        if !encounteredError {
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey("Post sign-in checks completed."))
            }
        }
    }

    private func checkNetwork() async {
        var configurationValid = false
        do {
            _ = try Secrets.supabaseURL()
            configurationValid = true
        } catch {
            configurationValid = false
        }

        let status = await currentNetworkStatus()
        let message: LocalizedStringKey

        if !configurationValid {
            message = LocalizedStringKey("Supabase configuration could not be loaded.")
        } else {
            switch status {
            case .satisfied:
                message = LocalizedStringKey("Startup connectivity checks passed.")
            case .unsatisfied:
                message = LocalizedStringKey("Network check failed: connection unavailable.")
            case .requiresConnection:
                message = LocalizedStringKey("Network check requires additional connection.")
            @unknown default:
                message = LocalizedStringKey("Network check returned an unknown status.")
            }
        }

        await MainActor.run {
            showDiagnosticsToast(message)
        }
    }

    private func loadWords() async {
        let service = quranServiceFactory()
        do {
            _ = try await service.loadTranslationWords(surah: 1, ayah: nil)
        } catch {
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey("Failed to load translation words."))
            }
        }
    }

    private func rebuildAyah() async {
        let service = quranServiceFactory()
        do {
            _ = try await service.rebuildAlbanianAyah(surah: 1, ayah: 1)
        } catch {
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey("Failed to rebuild sample ayah."))
            }
        }
    }

    private func currentNetworkStatus() async -> NWPath.Status {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "AppStartTaskNetworkMonitor")
            var hasResumed = false

            monitor.pathUpdateHandler = { path in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: path.status)
                monitor.cancel()
            }

            monitor.start(queue: queue)
        }
    }
}

private extension AppStartTaskModifier {
    @MainActor
    private func showDiagnosticsToast(_ message: LocalizedStringKey) {
        diagnosticsDismissTask?.cancel()
        diagnosticsMessage = message
        withAnimation {
            isDiagnosticsToastVisible = true
        }

        diagnosticsDismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation {
                    isDiagnosticsToastVisible = false
                }
                diagnosticsMessage = nil
            }
        }
    }
}

extension View {
    func appStartTask(quranServiceFactory: @escaping () -> QuranServicing = { QuranService() }) -> some View {
        modifier(AppStartTaskModifier(quranServiceFactory: quranServiceFactory))
    }
}
