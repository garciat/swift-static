@resultBuilder
public struct HtmlBuilder {
    public static func buildExpression(_ expression: String) -> Node {
        .text(expression)
    }

    public static func buildExpression(_ expression: Node) -> Node {
        expression
    }

    public static func buildExpression(_ expression: [Node]) -> Node {
        .fragment(flattening: expression)
    }

    public static func buildBlock(_ components: Node...) -> Node {
        .fragment(flattening: components)
    }

    public static func buildArray(_ components: [Node]) -> Node {
        .fragment(flattening: components)
    }

    public static func buildOptional(_ component: Node?) -> Node {
        component ?? .fragment([])
    }
}

extension Node {
    public static func fragment(@HtmlBuilder content: () -> Node) -> Node {
        .fragment(flattening: [content()])
    }

    static func fragment(flattening nodes: [Node]) -> Node {
        .fragment(nodes.flatMap { $0.flattened() })
    }

    func flattened() -> [Node] {
        switch self {
        case .fragment(let inner):
            inner
        default:
            [self]
        }
    }
}
