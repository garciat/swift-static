import Yams

struct FrontmatterResult<T> {
    let frontmatter: T
    let body: String

    func mapYaml<U: Codable>(to: U.Type) throws -> FrontmatterResult<U> where T == String {
        let decoder = YAMLDecoder()
        let parsed = try decoder.decode(to, from: frontmatter)
        return FrontmatterResult<U>(frontmatter: parsed, body: body)
    }
}

func parseFrontmatter(_ raw: String) -> FrontmatterResult<String>? {
    let pattern =
        #/(?ms)\A---[ \t]*\R(?<frontmatter>.*?)(?:\R)?^---[ \t]*(?:\R|\z)(?<body>.*)\z/#

    return raw.firstMatch(of: pattern)
        .map {
            FrontmatterResult(
                frontmatter: String($0.output.frontmatter),
                body: String($0.output.body),
            )
        }
}
