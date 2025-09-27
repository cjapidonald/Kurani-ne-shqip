import Foundation

enum Secrets {
    enum SecretsError: LocalizedError {
        case missingValue(key: String)
        case invalidURL(key: String)

        var errorDescription: String? {
            switch self {
            case let .missingValue(key):
                return "Missing value for \(key) in Info.plist."
            case let .invalidURL(key):
                return "Value for \(key) is not a valid URL."
            }
        }
    }
}

struct SecretsLoader {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func supabaseConfiguration() throws -> (url: URL, anonKey: String) {
        let url = try supabaseURL()
        let anonKey = try supabaseAnonKey()
        return (url, anonKey)
    }

    func supabaseURL() throws -> URL {
        guard let rawValue = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            throw Secrets.SecretsError.missingValue(key: "SUPABASE_URL")
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw Secrets.SecretsError.missingValue(key: "SUPABASE_URL")
        }

        guard var components = URLComponents(string: value) else {
            throw Secrets.SecretsError.invalidURL(key: "SUPABASE_URL")
        }

        guard let scheme = components.scheme?.lowercased(), scheme == "https" else {
            throw Secrets.SecretsError.invalidURL(key: "SUPABASE_URL")
        }

        guard let host = components.host, !host.isEmpty else {
            throw Secrets.SecretsError.invalidURL(key: "SUPABASE_URL")
        }

        guard let url = components.url else {
            throw Secrets.SecretsError.invalidURL(key: "SUPABASE_URL")
        }

        return url
    }

    func supabaseAnonKey() throws -> String {
        guard let rawValue = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            throw Secrets.SecretsError.missingValue(key: "SUPABASE_ANON_KEY")
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            throw Secrets.SecretsError.missingValue(key: "SUPABASE_ANON_KEY")
        }

        return value
    }
}

extension Secrets {
    private static let loader = SecretsLoader()

    static func supabaseConfiguration() throws -> (url: URL, anonKey: String) {
        try loader.supabaseConfiguration()
    }

    static func supabaseURL() throws -> URL {
        try loader.supabaseURL()
    }

    static func supabaseAnonKey() throws -> String {
        try loader.supabaseAnonKey()
    }
}
