import Foundation
import Supabase

protocol TranslationService {
    func fetchSurahMetadata() async throws -> [Surah]
    func fetchAyahsBySurah() async throws -> [Int: [Ayah]]
    func fetchArabicTextBySurah() async throws -> [Int: [Int: String]]
}

final class SupabaseTranslationService: TranslationService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.client) {
        self.client = client
    }

    func fetchSurahMetadata() async throws -> [Surah] {
        // TODO: Replace with Supabase-backed implementation.
        return []
    }

    func fetchAyahsBySurah() async throws -> [Int: [Ayah]] {
        // TODO: Replace with Supabase-backed implementation.
        return [:]
    }

    func fetchArabicTextBySurah() async throws -> [Int: [Int: String]] {
        // TODO: Replace with Supabase-backed implementation.
        return [:]
    }
}
