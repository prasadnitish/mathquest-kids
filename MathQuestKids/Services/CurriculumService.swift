import Foundation

enum CurriculumService {
    static func loadDefaultCatalog(bundle: Bundle = .main) throws -> CurriculumCatalog {
        guard let url = bundle.url(forResource: "lesson-plans-k5", withExtension: "json") else {
            throw NSError(
                domain: "CurriculumService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "lesson-plans-k5.json not found"]
            )
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let catalog = try decoder.decode(CurriculumCatalog.self, from: data)
        try catalog.validate()
        return catalog
    }
}
