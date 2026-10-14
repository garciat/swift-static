func formatPage(_ root: Node) -> String {
    return "<!DOCTYPE html>\n" + formatHtml(root)
}

func formatHtml(_ node: Node) -> String {
    switch node {
    case .text(let value):
        return value.htmlEscaped

    case .raw(let value):
        return value

    case .fragment(let nodes):
        return nodes.map(formatHtml).joined()

    case .elem(let elem):
        return formatOpen(elem)
            + elem.children.map(formatHtml).joined()
            + formatClose(elem)

    case .void(let elem):
        return formatOpen(elem)
    }
}

func formatOpen(_ elem: Elem) -> String {
    if elem.attrs.isEmpty {
        "<\(elem.name)>"
    } else {
        "<\(elem.name) \(elem.attrs.format())>"
    }
}

func formatOpen(_ elem: VElem) -> String {
    if elem.attrs.isEmpty {
        "<\(elem.name)>"
    } else {
        "<\(elem.name) \(elem.attrs.format())>"
    }
}

func formatClose(_ elem: Elem) -> String {
    "</\(elem.name)>"
}

extension AttrMap {
    func format() -> String {
        sorted(by: { $0.key < $1.key })
            .map { "\($0.key.value)=\"\($0.value.htmlAttributeEscaped)\"" }
            .joined(separator: " ")
    }
}

extension AttrTag {
    var value: String {
        switch self {
        case .generic(let val):
            val
        default:
            String(describing: self)
        }
    }
}
