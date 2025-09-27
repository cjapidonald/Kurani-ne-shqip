import SwiftUI
import Network

struct AppStartTaskModifier: ViewModifier {
    @EnvironmentObject private var authManager: AuthManager

    private let quranServiceFactory: () -> QuranServicing
    @State private var hasRunInitialChecks = false
    @State private var hasCompletedPostSignInChecks = false
    @State private var isPresentingSignIn = false

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
    }

    private func runInitialChecks() async {
        await checkNetwork()
        await loadWords()
        await rebuildAyah()
    }

    private func runPostSignInChecks() async {
        let service = quranServiceFactory()

        do {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            try await service.upsertMyNote(
                surah: 1,
                ayah: 1,
                albanianText: "AppStartTask",
                note: "Temporary note created at \(timestamp)"
            )
            print("[AppStartTask] upsertMyNote succeeded for surah 1 ayah 1")
        } catch {
            print("[AppStartTask] upsertMyNote failed: \(error.localizedDescription)")
        }

        do {
            let wasFavorite = try await service.isFavorite(surah: 1, ayah: 1)
            try await service.toggleFavorite(surah: 1, ayah: 1)
            let isFavoriteNow = try await service.isFavorite(surah: 1, ayah: 1)
            print("[AppStartTask] toggleFavorite changed from \(wasFavorite) to \(isFavoriteNow) for surah 1 ayah 1")
        } catch {
            print("[AppStartTask] toggleFavorite failed: \(error.localizedDescription)")
        }
    }

    private func checkNetwork() async {
        let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        if let supabaseURL {
            print("[AppStartTask] Supabase URL: \(supabaseURL)")
        } else {
            print("[AppStartTask] Supabase URL missing from Info.plist")
        }

        let status = await currentNetworkStatus()
        let description: String
        switch status {
        case .satisfied:
            description = "satisfied"
        case .unsatisfied:
            description = "unsatisfied"
        case .requiresConnection:
            description = "requiresConnection"
        @unknown default:
            description = "unknown"
        }
        print("[AppStartTask] Network status: \(description)")
    }

    private func loadWords() async {
        let service = quranServiceFactory()
        do {
            let words = try await service.loadTranslationWords(surah: 1, ayah: nil)
            let firstWords = words.prefix(5).map(\.albanianWord)
            print("[AppStartTask] First 5 words for surah 1: \(firstWords.joined(separator: ", "))")
        } catch {
            print("[AppStartTask] Failed to load translation words: \(error.localizedDescription)")
        }
    }

    private func rebuildAyah() async {
        let service = quranServiceFactory()
        do {
            let rebuilt = try await service.rebuildAlbanianAyah(surah: 1, ayah: 1)
            print("[AppStartTask] rebuildAlbanianAyah result: \(rebuilt)")
        } catch {
            print("[AppStartTask] rebuildAlbanianAyah failed: \(error.localizedDescription)")
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

extension View {
    func appStartTask(quranServiceFactory: @escaping () -> QuranServicing = { QuranService() }) -> some View {
        modifier(AppStartTaskModifier(quranServiceFactory: quranServiceFactory))
    }
}
