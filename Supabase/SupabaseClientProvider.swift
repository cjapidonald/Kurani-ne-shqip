import Foundation
import Supabase

enum SupabaseConfigError: LocalizedError {
    case missingValue(key: String)
    case invalidURL(key: String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "Missing configuration value for \(key)."
        case .invalidURL(let key):
            return "Invalid URL in configuration for \(key)."
        }
    }
}

final class SupabaseClientProvider {
    private static let lock = NSLock()
    private static var cachedResult: Result<SupabaseClientProvider, Error>?

    static func client(bundle: Bundle = .main) throws -> SupabaseClient {
        try resolveShared(bundle: bundle).get().client
    }

    static func clientIfAvailable(bundle: Bundle = .main) -> SupabaseClient? {
        try? client(bundle: bundle)
    }

    static var redirectURL: URL? {
        guard case .success(let provider) = resolveShared(bundle: .main) else {
            return nil
        }
        return provider.redirectURL
    }

    static func configurationResult(bundle: Bundle = .main) -> Result<SupabaseClientProvider, Error> {
        resolveShared(bundle: bundle)
    }

    private static func resolveShared(bundle: Bundle) -> Result<SupabaseClientProvider, Error> {
        lock.lock()
        defer { lock.unlock() }

        if let cachedResult {
            return cachedResult
        }

        let result = Result { try SupabaseClientProvider(bundle: bundle) }
        cachedResult = result
        return result
    }

    struct Configuration {
        let url: URL
        let anonKey: String
    }

    let client: SupabaseClient
    let redirectURL: URL?

    init(bundle: Bundle = .main, configuration: Configuration? = nil) throws {
        let configuration = try configuration ?? SupabaseClientProvider.loadConfiguration(from: bundle)
        redirectURL = SupabaseClientProvider.makeRedirectURL(from: bundle)

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

    private static func loadConfiguration(from bundle: Bundle) throws -> Configuration {
        let urlString = try requireValue(forKey: "SUPABASE_URL", in: bundle)
        let anonKey = try requireValue(forKey: "SUPABASE_ANON_KEY", in: bundle)

        guard let url = URL(string: urlString) else {
            throw SupabaseConfigError.invalidURL(key: "SUPABASE_URL")
        }

        return Configuration(url: url, anonKey: anonKey)
    }

    private static func requireValue(forKey key: String, in bundle: Bundle) throws -> String {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            throw SupabaseConfigError.missingValue(key: key)
        }
        return value
    }

    private static func makeRedirectURL(from bundle: Bundle) -> URL? {
        guard let value = bundle.object(forInfoDictionaryKey: "SUPABASE_REDIRECT_URL") as? String else {
            return nil
        }
        return URL(string: value)
    }
}

