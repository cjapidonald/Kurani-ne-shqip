import SwiftUI
import Network
import Foundation

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
        await verifyLocalAlbanianDataset()
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
            #if DEBUG
            let summary = try await translationWordDiagnosticsSummary(service: service)
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey(stringLiteral: summary))
            }
            #else
            _ = try await translationWordDiagnosticsSummary(service: service)
            #endif
        } catch {
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey("Failed to load translation words."))
            }
        }
    }

    private func translationWordDiagnosticsSummary(service: QuranServicing) async throws -> String {
        let surah1Words = try await service.loadTranslationWords(surah: 1, ayah: nil)
        let surah1WordCounts = Dictionary(grouping: surah1Words, by: \.ayah).mapValues(\.count)
        let surah1ExpectedAyahs = Array(1...7)
        let surah1MissingAyahs = surah1ExpectedAyahs.filter { surah1WordCounts[$0] == nil }
        let surah1TotalWords = surah1Words.count

        var surah2WordCounts: [Int: Int] = [:]
        for ayah in 1...5 {
            let words = try await service.loadTranslationWords(surah: 2, ayah: ayah)
            if !words.isEmpty {
                surah2WordCounts[ayah] = words.count
            }
        }
        let surah2TotalWords = surah2WordCounts.values.reduce(0, +)
        let surah2ExpectedAyahs = Array(1...5)
        let surah2MissingAyahs = surah2ExpectedAyahs.filter { surah2WordCounts[$0] == nil }

        let missingAyahs = surah1MissingAyahs.map { "1:\($0)" } + surah2MissingAyahs.map { "2:\($0)" }
        let surah1Summary = "S1 ayahs: \(surah1WordCounts.count)/\(surah1ExpectedAyahs.count) (\(surah1TotalWords) words)"
        let surah2Summary = "S2 1-5 ayahs: \(surah2WordCounts.count)/\(surah2ExpectedAyahs.count) (\(surah2TotalWords) words)"

        var message = "Translation words loaded. \(surah1Summary); \(surah2Summary)"
        if !missingAyahs.isEmpty {
            message += " | Missing: \(missingAyahs.joined(separator: ", "))"
        }

        // Manual verification SQL:
        // SELECT surah, ayah, COUNT(*) AS word_count
        // FROM translation
        // WHERE surah = 1 OR (surah = 2 AND ayah BETWEEN 1 AND 5)
        // GROUP BY surah, ayah
        // ORDER BY surah, ayah;

        return message
    }

    private func verifyLocalAlbanianDataset() async {
        do {
            let loader = AlbanianQuranLoader()
            let dataset = try loader.load()
            let hasIntroAyah = dataset.ayahsBySurah[1]?.contains(where: { $0.number == 1 && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? false
            if !hasIntroAyah {
                await MainActor.run {
                    showDiagnosticsToast(LocalizedStringKey("Embedded Albanian text appears to be missing."))
                }
            }
        } catch {
            await MainActor.run {
                showDiagnosticsToast(LocalizedStringKey("Failed to load embedded Albanian text."))
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
