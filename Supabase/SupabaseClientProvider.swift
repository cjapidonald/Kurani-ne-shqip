import Foundation
import Supabase

enum SupabaseClientProvider {
    private static let bundle = Bundle.main

    static let redirectURL: URL? = {
        guard let value = bundle.object(forInfoDictionaryKey: "SUPABASE_REDIRECT_URL") as? String else {
            return nil
        }
        return URL(string: value)
    }()

    static let client: SupabaseClient = {
        let configuration: (url: URL, anonKey: String)
        do {
            configuration = try Secrets.supabaseConfiguration()
        } catch {
            fatalError(error.localizedDescription)
        }

        let options: SupabaseClientOptions
        if let redirectURL {
            options = SupabaseClientOptions(auth: .init(redirectToURL: redirectURL))
        } else {
            options = SupabaseClientOptions()
        }

        return SupabaseClient(supabaseURL: configuration.url, supabaseKey: configuration.anonKey, options: options)
    }()
}
