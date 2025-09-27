import Foundation
import Supabase

final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    static var client: SupabaseClient { shared.client }
    static var redirectURL: URL? { shared.redirectURL }

    let client: SupabaseClient
    let redirectURL: URL?

    init(bundle: Bundle = .main, secretsLoader: SecretsLoader? = nil) {
        let loader = secretsLoader ?? SecretsLoader(bundle: bundle)
        redirectURL = SupabaseClientProvider.makeRedirectURL(from: bundle)

        let configuration: (url: URL, anonKey: String)
        do {
            configuration = try loader.supabaseConfiguration()
        } catch {
            fatalError(error.localizedDescription)
        }

        let options: SupabaseClientOptions
        if let redirectURL {
            options = SupabaseClientOptions(auth: .init(redirectToURL: redirectURL))
        } else {
            options = SupabaseClientOptions()
        }

        client = SupabaseClient(supabaseURL: configuration.url, supabaseKey: configuration.anonKey, options: options)

        #if DEBUG
        let hostDescription = configuration.url.host ?? configuration.url.absoluteString
        print("[SupabaseClientProvider] Supabase ✅ (\(hostDescription))")
        #endif
    }

    private static func makeRedirectURL(from bundle: Bundle) -> URL? {
        guard let value = bundle.object(forInfoDictionaryKey: "SUPABASE_REDIRECT_URL") as? String else {
            return nil
        }
        return URL(string: value)
    }
}
