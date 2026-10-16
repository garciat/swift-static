import FlyingFox
import Foundation

extension Site {
    public func main() async throws {
        switch CommandLine.arguments.dropFirst().first {
        case "serve":
            try await serve()
        default:
            try render(to: URL(fileURLWithPath: "_site", isDirectory: true))
        }
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

            let mimeType = path.pathExtensionMimeType

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

    func flatten(_ base: URL) -> [(URL, Response)] {
        switch self {
        case .root(let index, let children):
            flattenDir(
                onto: base,
                index: index,
                children: children,
            )
        }
    }
}

extension Tree {
    func flatten(_ base: URL) -> [(URL, Response)] {
        switch self {
        case .file(let name, let body):
            [(base.appendingPathComponent(name), body)]
        case .dir(let name, let index, let children):
            flattenDir(
                onto: base.appendingPathComponent(name, isDirectory: true),
                index: index,
                children: children,
            )
        }
    }
}

func flattenDir(onto path: URL, index: Response?, children: [Tree]) -> [(URL, Response)] {
    (index.map { [(path.appendingPathComponent("index.html"), $0)] } ?? [])
        + children.flatMap { $0.flatten(path) }
}
