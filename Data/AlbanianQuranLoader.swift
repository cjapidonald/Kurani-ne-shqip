import Foundation

struct AlbanianQuranDataset: Decodable {
    struct SurahData: Decodable {
        struct AyahData: Decodable {
            let number: Int
            let text: String
        }

        let number: Int
        let name: String
        let ayahCount: Int
        let ayahs: [AyahData]

        enum CodingKeys: String, CodingKey {
            case number
            case name
            case ayahCount
            case ayahs
        }
    }

    let surahs: [SurahData]
}

protocol AlbanianQuranLoading {
    func load() throws -> (surahs: [Surah], ayahsBySurah: [Int: [Ayah]])
}

struct AlbanianQuranLoader: AlbanianQuranLoading {
    private let resourceName: String
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(resourceName: String = "AlbanianQuran", bundle: Bundle = .main, decoder: JSONDecoder = JSONDecoder()) {
        self.resourceName = resourceName
        self.bundle = bundle
        self.decoder = decoder
    }

    func load() throws -> (surahs: [Surah], ayahsBySurah: [Int: [Ayah]]) {
        guard let url = locateResourceURL() else {
            throw LoaderError.resourceNotFound(resourceName)
        }

        let data = try Data(contentsOf: url)
        let dataset = try decoder.decode(AlbanianQuranDataset.self, from: data)
        let surahs = dataset.surahs.map { Surah(number: $0.number, name: $0.name, ayahCount: $0.ayahCount) }
        var ayahsBySurah: [Int: [Ayah]] = [:]
        for surah in dataset.surahs {
            ayahsBySurah[surah.number] = surah.ayahs.map { Ayah(number: $0.number, text: $0.text) }
        }
        return (surahs, ayahsBySurah)
    }

    private func locateResourceURL() -> URL? {
        if let url = bundle.url(forResource: resourceName, withExtension: "json") {
            return url
        }

        // When running in previews or unit tests, `.main` may not contain the resource.
        // Fallback to the module bundle by identifying the bundle that contains this loader type.
        let mirrorBundle = Bundle(for: BundleToken.self)
        return mirrorBundle.url(forResource: resourceName, withExtension: "json")
    }

    enum LoaderError: LocalizedError {
        case resourceNotFound(String)

        var errorDescription: String? {
            switch self {
            case .resourceNotFound(let name):
                return "Resource \(name).json was not found in the app bundle."
            }
        }
    }
}

private final class BundleToken {}
