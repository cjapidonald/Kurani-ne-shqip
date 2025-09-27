import Foundation
import Supabase

enum SupabaseClientProvider {
    static let client: SupabaseClient = {
        let bundle = Bundle.main

        guard
            let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("Missing or invalid SUPABASE_URL in Info.plist")
        }

        guard let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !anonKey.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }

        return SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }()
}
