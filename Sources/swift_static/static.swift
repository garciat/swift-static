import Foundation

enum Response {
    case data(Data)
    case html(Node)
    case string(String)

    static func html(@HtmlBuilder content: () -> Node) -> Response {
        .html(content())
    }
}

enum TreeRoot {
    case root(index: Response? = nil, [Tree])

    static func root(index: Response? = nil, _ items: Tree...) -> TreeRoot {
        .root(index: index, items)
    }
}

enum Tree {
    case file(String, Response)
    case dir(String, index: Response? = nil, [Tree])

    static func dir(_ name: String, index: Response? = nil, _ items: Tree...) -> Tree {
        .dir(name, index: index, items)
    }
}

// helpers
struct H {
    static let baseURL: URL = {
        let config =
            ProcessInfo.processInfo.environment["BASE_URL"]
            .map { $0.hasSuffix("/") ? $0 : $0 + "/" }

        guard let base = config.flatMap({ URL(string: $0) }) else {
            return URL(string: "https://localhost:3000/")!
        }

        return base
    }()

    static func url(_ path: String, absolute: Bool = false) -> String {
        assert(path.starts(with: "/"))

        let relative = path == "/" ? "." : String(path.dropFirst())

        let url = URL(string: relative, relativeTo: Self.baseURL)!

        return absolute ? url.absoluteString : url.path(percentEncoded: true)
    }
}
