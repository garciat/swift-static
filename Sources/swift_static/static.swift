import Foundation

enum Response {
    case data(Data)
    case html(Node)
    case string(String)
}

enum TreeRoot {
    case root(index: Response? = nil, [Tree])

    static func root(index: Response? = nil, _ items: Tree...) -> TreeRoot {
        .root(index: index, items)
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
        }
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
