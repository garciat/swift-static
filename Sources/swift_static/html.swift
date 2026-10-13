// ---

enum ZeroOneMany<S: Sequence> {
    case zero
    case one(S.Element)
    case many(S)
}

func zom<T>(_ arr: [T]) -> ZeroOneMany<[T]> {
    switch arr.count {
    case 0:
        .zero
    case 1:
        .one(arr[0])
    default:
        .many(arr)
    }
}

extension String {
    var htmlEscaped: String {
        var result = String()
        result.reserveCapacity(utf8.count)

        for scalar in unicodeScalars {
            switch scalar {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            case "'": result += "&#39;"
            default: result.unicodeScalars.append(scalar)
            }
        }

        return result
    }

    var htmlAttributeEscaped: String {
        var result = String()
        result.reserveCapacity(utf8.count)

        for scalar in unicodeScalars {
            switch scalar {
            case "&": result += "&amp;"
            case "\"": result += "&quot;"
            case "<": result += "&lt;"
            default: result.unicodeScalars.append(scalar)
            }
        }

        return result
    }
}

// ---

struct Elem {
    let name: String
    let attrs: AttrMap
    let children: [Node]

    // https://developer.mozilla.org/en-US/docs/Glossary/Void_element
    let isVoid: Bool
}

enum Node {
    case elem(Elem)
    case text(String)
    case fragment([Node])

    func flattened() -> [Node] {
        switch self {
        case .fragment(let inner):
            inner
        default:
            [self]
        }
    }

    static func fragment(flattening nodes: [Node]) -> Node {
        .fragment(nodes.flatMap { $0.flattened() })
    }
}

// relative ordering for attributes
enum AttrTag: Comparable, Hashable {
    case id
    case name
    case content
    case href
    case generic(String)

    var value: String {
        switch self {
        case .generic(let val):
            val
        default:
            String(describing: self)
        }
    }
}

enum Attr {
    case id(String)
    case lang(String)

    var components: (name: AttrTag, value: String) {
        switch self {
        case .id(let val): (.id, val)
        case .lang(let val): (.generic("lang"), val)
        }
    }
}

typealias AttrMap = [AttrTag: String]

extension AttrMap {
    init(of attrs: [Attr]) {
        self = .empty
        for attr in attrs {
            let c = attr.components
            self[c.name] = c.value
        }
    }

    func format() -> String {
        self.sorted(by: { $0.key < $1.key })
            .map { "\($0.key.value)=\"\($0.value.htmlAttributeEscaped)\"" }
            .joined(separator: " ")
    }

    static var empty: AttrMap {
        [:]
    }
}

func formatOpen(_ elem: Elem) -> String {
    if elem.attrs.isEmpty {
        "<\(elem.name)>"
    } else {
        "<\(elem.name) \(elem.attrs.format())>"
    }
}

func formatClose(_ elem: Elem) -> String {
    "</\(elem.name)>"
}

func formatEmpty(_ elem: Elem) -> String {
    if elem.isVoid {
        formatOpen(elem)
    } else {
        "\(formatOpen(elem))\(formatClose(elem))"
    }
}

func formatTextOnly(_ elem: Elem, _ text: String) -> String {
    "\(formatOpen(elem))\(text.htmlEscaped)\(formatClose(elem))"
}

func containsText(_ nodes: [Node]) -> Bool {
    for node in nodes {
        switch node {
        case .text:
            return true
        case .fragment(let inner):
            return containsText(inner)
        default:
            continue
        }
    }
    return false
}

func formatHtml(_ node: Node) -> String {
    func go(_ node: Node) -> [String] {
        switch node {
        case .elem(let elem):
            switch zom(elem.children) {
            case .zero:
                [formatEmpty(elem)]
            case .one(.text(let text)):
                [formatTextOnly(elem, text)]
            default:
                if containsText(elem.children) {
                    [
                        formatOpen(elem),
                        "  " + elem.children.flatMap { go($0) }.joined(),
                        formatClose(elem),
                    ]
                } else {
                    [formatOpen(elem)]
                        + elem.children.flatMap { go($0) }.map { "  " + $0 }
                        + [formatClose(elem)]
                }
            }
        case .text(let it):
            [it.htmlEscaped]
        case .fragment(let nodes):
            nodes.flatMap { go($0) }
        }
    }

    return go(node).joined(separator: "\n")
}

func formatPage(_ root: Node) -> String {
    return "<!DOCTYPE html>\n" + formatHtml(root)
}

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
}

// Parent Element
func e(_ name: String, attrs: AttrMap = .empty, children: [Node]) -> Node {
    .elem(Elem(name: name, attrs: attrs, children: children, isVoid: false))
}

// Parent Element
func e(_ name: String, attrs: AttrMap = .empty, @HtmlBuilder _ content: () -> Node) -> Node {
    e(name, attrs: attrs, children: content().flattened())
}

// Parent Element
func e(_ name: String, _ attrs: Attr..., @HtmlBuilder content: () -> Node) -> Node {
    e(name, attrs: AttrMap(of: attrs), content)
}

// Parent Element
func e(_ name: String, @HtmlBuilder content: () -> Node) -> Node {
    e(name, attrs: .empty, content)
}

// Void Element
func e(_ name: String, attrs: AttrMap) -> Node {
    .elem(Elem(name: name, attrs: attrs, children: [], isVoid: true))
}

func html(_ attrs: Attr..., @HtmlBuilder content: () -> Node) -> Node {
    e("html", attrs: AttrMap(of: attrs), content)
}

func head(@HtmlBuilder content: () -> Node) -> Node {
    e("head", content)
}

func title(_ text: String) -> Node {
    e("title") { text }
}

func meta(charset: String) -> Node {
    e("meta", attrs: [.generic("charset"): charset])
}

func meta(name: String, content: String) -> Node {
    return e("meta", attrs: [.name: name, .content: content])
}

func body(@HtmlBuilder content: () -> Node) -> Node {
    e("body", content)
}

func div(_ attrs: Attr..., @HtmlBuilder content: () -> Node) -> Node {
    e("div", attrs: AttrMap(of: attrs), content)
}

func h1(_ text: String) -> Node {
    e("h1") { text }
}

func p(_ text: String) -> Node {
    e("p") { text }
}

func a(href: String, @HtmlBuilder content: () -> Node) -> Node {
    e("a", attrs: [.href: href], content)
}
