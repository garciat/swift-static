import Foundation
import Yams

struct Article<T> {
    let path: URL
    let meta: T
    let body: String
}

func loadArticles<T: Codable>(_ type: T.Type, from dirPath: URL) throws -> [Article<T>] {
    assert(dirPath.isFileURL)

    let children = try FileManager.default.contentsOfDirectory(
        at: dirPath,
        includingPropertiesForKeys: nil,
    )

    let decoder = YAMLDecoder()

    return
        try children
        .filter { $0.pathExtension == "md" }
        .map {
            let (frontmatter, body) = try parseFrontmatter(String(contentsOf: $0, encoding: .utf8))
            let meta = try decoder.decode(type, from: frontmatter)
            return Article(path: $0, meta: meta, body: body)
        }
}
func parseFrontmatter(_ raw: String) -> (frontmatter: String, body: String) {
    let pattern =
        #/(?ms)\A---[ \t]*\R(?<frontmatter>.*?)(?:\R)?^---[ \t]*(?:\R|\z)(?<body>.*)\z/#

    guard let match = raw.firstMatch(of: pattern) else {
        return (frontmatter: "", body: raw)
    }

    return (
        frontmatter: String(match.output.frontmatter),
        body: String(match.output.body),
    )
}
