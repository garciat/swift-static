// ---

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

func formatHtml(_ node: Node) -> String {
    switch node {
    case .text(let it):
        return it.htmlEscaped

    case .fragment(let nodes):
        return nodes.map(formatHtml).joined()

    case .elem(let elem):
        if elem.isVoid {
            assert(elem.children.isEmpty, "void element should have no children")
            return formatOpen(elem)
        } else {
            return formatOpen(elem)
                + elem.children.map(formatHtml).joined()
                + formatClose(elem)
        }
    }
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
