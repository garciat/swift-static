@resultBuilder
struct HtmlBuilder {
    static func buildExpression(_ expression: String) -> Node {
        .text(expression)
    }

    static func buildExpression(_ expression: Node) -> Node {
        expression
    }

    static func buildExpression(_ expression: [Node]) -> Node {
        .fragment(flattening: expression)
    }

    static func buildBlock(_ components: Node...) -> Node {
        .fragment(flattening: components)
    }

    static func buildArray(_ components: [Node]) -> Node {
        .fragment(flattening: components)
    }

    static func buildOptional(_ component: Node?) -> Node {
        component ?? .fragment([])
    }
}

extension Node {
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
