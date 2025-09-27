import SwiftUI
import Supabase

@main
struct KuraniApp: App {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore: NotesStore
    @StateObject private var authManager: AuthManager
    @StateObject private var progressStore = ReadingProgressStore()
    @StateObject private var favoritesStore = FavoritesStore()
    #if DEBUG
    @State private var configurationError: Error?
    #endif

    init() {
        let configurationResult = SupabaseClientProvider.configurationResult()
        let client: SupabaseClient?
        #if DEBUG
        let debugConfigurationError: Error?
        #endif

        switch configurationResult {
        case .success(let provider):
            client = provider.client
            #if DEBUG
            debugConfigurationError = nil
            #endif
        case .failure(let error):
            client = nil
            #if DEBUG
            debugConfigurationError = error
            #endif
        }

        _notesStore = StateObject(wrappedValue: NotesStore(client: client))
        _authManager = StateObject(wrappedValue: AuthManager(client: client))
        #if DEBUG
        _configurationError = State(initialValue: debugConfigurationError)
        #endif

        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.kuraniTextPrimary)]
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.kuraniTextPrimary)]
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                translationStore: translationStore,
                notesStore: notesStore,
                progressStore: progressStore,
                favoritesStore: favoritesStore
            )
                .environmentObject(translationStore)
                .environmentObject(notesStore)
                .environmentObject(favoritesStore)
                .environmentObject(authManager)
                .environmentObject(progressStore)
                .preferredColorScheme(ColorScheme.light)
                .appStartTask()
                .task {
                    await translationStore.loadInitialData()
                    await notesStore.observeAuthChanges(authManager: authManager)
                }
                #if DEBUG
                .overlay(alignment: .top) {
                    if let message = configurationErrorMessage {
                        DebugConfigurationBanner(message: message)
                            .padding(.top, 16)
                    }
                }
                #endif
        }
    }
}

#if DEBUG
private struct DebugConfigurationBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.9), in: Capsule())
            .foregroundColor(.white)
            .shadow(radius: 4)
            .accessibilityIdentifier("SupabaseConfigurationBanner")
    }
}

private extension KuraniApp {
    var configurationErrorMessage: String? {
        guard let configurationError else { return nil }
        let description: String
        if let localizedError = configurationError as? LocalizedError,
           let localizedDescription = localizedError.errorDescription, !localizedDescription.isEmpty {
            description = localizedDescription
        } else {
            description = configurationError.localizedDescription
        }
        return "Supabase configuration error: \(description)"
    }
}
#endif
