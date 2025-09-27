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
        guard
            let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("Missing or invalid SUPABASE_URL in Info.plist")
        }

        guard let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !anonKey.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }

        let options: SupabaseClientOptions
        if let redirectURL {
            options = SupabaseClientOptions(auth: .init(redirectToURL: redirectURL))
        } else {
            options = SupabaseClientOptions()
        }

        return SupabaseClient(supabaseURL: url, supabaseKey: anonKey, options: options)
    }()
}
