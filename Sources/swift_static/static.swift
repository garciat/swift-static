import FlyingFox
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

    func serve(port: UInt16 = 3000) async throws {
        let server = HTTPServer(port: port)

        for (path, res) in flatten(URL(string: "/")!) {
            let data =
                switch res {
                case .data(let data):
                    data
                case .html(let root):
                    formatPage(root).data(using: .utf8)!
                case .string(let s):
                    s.data(using: .utf8)!
                }

            let mimeType =
                path.fileExtension?.fileExtensionMimeType
                ?? .defaultHttpMimeType

            var paths = [path.absoluteString]

            if path.lastPathComponent == "index.html" {
                paths.append(path.deletingLastPathComponent().absoluteString)
            }

            for path in paths {
                await server.appendRoute(path, for: ["GET"]) { request in
                    HTTPResponse(
                        statusCode: .ok,
                        headers: [.contentType: mimeType],
                        body: data,
                    )
                }
            }
        }

        print("Starting server on :\(port)")

        try await server.run()
    }

    func render(to basePath: URL) throws {
        for (path, res) in flatten(basePath) {
            try FileManager.default.createDirectory(
                at: path.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )

            switch res {
            case .data(let data):
                try data.write(to: path)
            case .html(let root):
                try formatPage(root).write(to: path, atomically: true, encoding: .utf8)
            case .string(let s):
                try s.write(to: path, atomically: true, encoding: .utf8)
            }

            print("[render]", "wrote \(path.relativePath)")
        }

        print("[render]", "done")
    }

    func flatten(_ basePath: URL) -> [(URL, Response)] {
        switch self {
        case .root(let index, let children):
            (index.map { [(basePath.appendingPathComponent("index.html"), $0)] } ?? [])
                + children.flatMap { $0.flatten(basePath) }
        }
    }
}

enum Tree {
    case file(String, Response)
    case dir(String, index: Response? = nil, [Tree])

    static func dir(_ name: String, index: Response? = nil, _ items: Tree...) -> Tree {
        .dir(name, index: index, items)
    }

    func flatten(_ basePath: URL) -> [(URL, Response)] {
        switch self {
        case .file(let name, let body):
            return [(basePath.appendingPathComponent(name), body)]
        case .dir(let name, let index, let children):
            let next = basePath.appendingPathComponent(name, isDirectory: true)

            return (index.map { [(next.appendingPathComponent("index.html"), $0)] } ?? [])
                + children.flatMap { $0.flatten(next) }
        }
    }
}

extension URL {
    var fileExtension: String.SubSequence? {
        let last = lastPathComponent
        return last.lastIndex(of: ".").map { last.suffix(from: $0) }
    }
}

extension StringProtocol {
    var fileExtensionMimeType: String {
        switch self {
        case ".html": "text/html"
        default: .defaultHttpMimeType
        }
    }

    static var defaultHttpMimeType: String {
        "application/octet-stream"
    }
}
