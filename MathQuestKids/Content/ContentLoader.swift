import Foundation

enum ContentLoader {
    static func loadDefaultPack(bundle: Bundle = .main) throws -> ContentPack {
        guard let url = bundle.url(forResource: "content-pack-v1", withExtension: "json") else {
            throw NSError(domain: "ContentLoader", code: 404, userInfo: [NSLocalizedDescriptionKey: "content-pack-v1.json not found"])
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let pack = try decoder.decode(ContentPack.self, from: data)
        try pack.validate()
        return pack
    }
}
