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
        guard let value = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !value.isEmpty else {
            throw Secrets.SecretsError.missingValue(key: "SUPABASE_URL")
        }

        guard let url = URL(string: value) else {
            throw Secrets.SecretsError.invalidURL(key: "SUPABASE_URL")
        }

        return url
    }

    func supabaseAnonKey() throws -> String {
        guard let value = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !value.isEmpty else {
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
