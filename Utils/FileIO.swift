import Foundation
import SwiftUI

enum FileIOError: Error, LocalizedError {
    case fileNotFound
    case decodingFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return NSLocalizedString("toast.error", comment: "File not found")
        case .decodingFailed: return NSLocalizedString("toast.error", comment: "Decoding failed")
        case .encodingFailed: return NSLocalizedString("toast.error", comment: "Encoding failed")
        }
    }
}

struct FileIO {
    static func loadBundleJSON<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw FileIOError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func decodeJSON<T: Decodable>(data: Data, as type: T.Type) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw FileIOError.decodingFailed
        }
    }
}
