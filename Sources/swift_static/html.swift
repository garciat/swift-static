// ---

enum ZeroOneMany<T> {
    case zero
    case one(T)
    case many([T])
}

func zom<T>(_ arr: [T]) -> ZeroOneMany<T> {
    switch arr.count {
    case 0:
        .zero
    case 1:
        .one(arr[0])
    default:
        .many(arr)
    }
}

// ---

struct Elem {
    let name: String
    let attrs: [AttrTag: String]
    let children: [Node]

    // https://developer.mozilla.org/en-US/docs/Glossary/Void_element
    let isVoid: Bool
}

enum Node {
    case elem(Elem)
    case text(String)
}

// relative ordering for attributes
enum AttrTag: Comparable, Hashable {
    case name
    case content
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

    func write(_ attrs: inout [AttrTag: String]) {
        switch self {
        case .id(let val): attrs[.generic("id")] = val
        case .lang(let val): attrs[.generic("lang")] = val
        }
    }
}

func dictAttrs(_ attrs: [Attr]) -> [AttrTag: String] {
    var d: [AttrTag: String] = [:]
    for attr in attrs {
        attr.write(&d)
    }
    return d
}

// TODO: escape value
func formatAttrs(_ attrs: [AttrTag: String]) -> String {
    attrs
        .sorted(by: { $0.key < $1.key })
        .map { "\($0.key.value)=\"\($0.value)\"" }.joined(separator: " ")
}

func formatOpen(_ elem: Elem) -> String {
    if elem.attrs.isEmpty {
        "<\(elem.name)>"
    } else {
        "<\(elem.name) \(formatAttrs(elem.attrs))>"
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

// TODO: escape text
func formatTextOnly(_ elem: Elem, _ text: String) -> String {
    "\(formatOpen(elem))\(text)\(formatClose(elem))"
}

func containsText(_ nodes: [Node]) -> Bool {
    for node in nodes {
        if case .text = node {
            return true
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
            [it]
        }
    }

    return go(node).joined(separator: "\n")
}

func formatPage(_ root: Node) -> String {
    return "<!DOCTYPE html>\n" + formatHtml(root)
}

@resultBuilder
struct HtmlBuilder {
    static func buildExpression(_ expression: String) -> [Node] {
        [.text(expression)]
    }

    static func buildExpression(_ expression: Node) -> [Node] {
        [expression]
    }

    static func buildExpression(_ expression: [Node]) -> [Node] {
        expression
    }

    static func buildBlock(_ components: [Node]...) -> [Node] {
        components.flatMap { $0 }
    }

    static func buildArray(_ components: [[Node]]) -> [Node] {
        components.flatMap { $0 }
    }
}

// Parent Element
func e(_ name: String, attrs: [AttrTag: String] = [:], @HtmlBuilder _ content: () -> [Node]) -> Node
{
    .elem(Elem(name: name, attrs: attrs, children: content(), isVoid: false))
}

// Parent Element
func e(_ name: String, _ attrs: Attr..., @HtmlBuilder content: () -> [Node]) -> Node {
    e(name, attrs: dictAttrs(attrs), content)
}

// Textual Element
func e(_ name: String, _ text: String, attrs: [AttrTag: String] = [:]) -> Node {
    .elem(Elem(name: name, attrs: attrs, children: [.text(text)], isVoid: false))
}

// Textual Element
func e(_ name: String, _ text: String, _ attrs: Attr...) -> Node {
    e(name, text, attrs: dictAttrs(attrs))
}

// Void Element
func e(_ name: String, attrs: [AttrTag: String]) -> Node {
    .elem(Elem(name: name, attrs: attrs, children: [], isVoid: true))
}

func html(_ attrs: Attr..., @HtmlBuilder content: () -> [Node]) -> Node {
    e("html", attrs: dictAttrs(attrs), content)
}

func head(@HtmlBuilder content: () -> [Node]) -> Node {
    e("head", content)
}

func body(@HtmlBuilder content: () -> [Node]) -> Node {
    e("body", content)
}

func div(_ attrs: Attr..., @HtmlBuilder content: () -> [Node]) -> Node {
    e("div", attrs: dictAttrs(attrs), content)
}

func title(_ text: String) -> Node {
    e("title", text)
}

func h1(_ text: String) -> Node {
    e("h1", text)
}

func p(_ text: String) -> Node {
    e("p", text)
}

func p(_ parts: Node...) -> Node {
    e("p", attrs: [:]) { parts }
}

func a(_ text: String, href: String) -> Node {
    e("a", text, attrs: [.generic("href"): href])
}

enum ViewportWidth {
    case value(Int)
    case deviceWidth

    var str: String {
        switch self {
        case .value(let val):
            "\(val)"
        case .deviceWidth:
            "device-width"
        }
    }
}

enum MetaViewportItem {
    case width(ViewportWidth)
    case initialScale(Double)

    var str: String {
        switch self {
        case .width(let val):
            "width=\(val.str)"
        case .initialScale(let val):
            "initial-scale=\(val)"
        }
    }
}

enum MetaNameContent {
    case description(String)
    case viewport([MetaViewportItem])

    var value: (String, String) {
        switch self {
        case .description(let val):
            ("description", val)
        case .viewport(let items):
            ("viewport", items.map { $0.str }.joined(separator: ","))
        }
    }

    public static func viewport(_ items: MetaViewportItem...) -> MetaNameContent {
        .viewport(items)
    }
}

func meta(charset: String) -> Node {
    e("meta", attrs: [.generic("charset"): charset])
}

func meta(_ value: MetaNameContent) -> Node {
    let (name, content) = value.value
    return e("meta", attrs: [.name: name, .content: content])
}
