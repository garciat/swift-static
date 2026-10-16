import Foundation

public enum Response {
    case data(Data)
    case html(Node)
    case string(String)

    static func html(@HtmlBuilder content: () -> Node) -> Response {
        .html(content())
    }
}

public struct TreeNode {
    let index: Response?
    let children: [TreeItem]
}

public enum TreeItem {
    case file(String, Response)
    case dir(String, TreeNode)
}

public typealias Site = TreeNode

extension Site {
    public static func root(index: Response? = nil, _ items: TreeItem...) -> Site {
        TreeNode(index: index, children: items)
    }
}

extension TreeItem {
    public static func dir(_ name: String, index: Response? = nil, _ items: [TreeItem]) -> TreeItem
    {
        .dir(name, TreeNode(index: index, children: items))
    }

    public static func dir(_ name: String, index: Response? = nil, _ items: TreeItem...) -> TreeItem
    {
        .dir(name, index: index, items)
    }
}

// helpers
public struct H {
    public static let baseURL: URL = {
        let config =
            ProcessInfo.processInfo.environment["BASE_URL"]
            .map { $0.hasSuffix("/") ? $0 : $0 + "/" }

        guard let base = config.flatMap({ URL(string: $0) }) else {
            return URL(string: "https://localhost:3000/")!
        }

        return base
    }()

    public static func url(_ path: String, absolute: Bool = false) -> String {
        assert(path.starts(with: "/"))

        let relative = path == "/" ? "." : String(path.dropFirst())

        let url = URL(string: relative, relativeTo: Self.baseURL)!

        return absolute ? url.absoluteString : url.path(percentEncoded: true)
    }
}
