struct Elem {
    let name: String
    let attrs: AttrMap
    let children: [Node]
}

// https://developer.mozilla.org/en-US/docs/Glossary/Void_element
struct VElem {
    let name: String
    let attrs: AttrMap
}

enum Node {
    case elem(Elem)
    case void(VElem)

    case raw(String)
    case text(String)

    case fragment([Node])
}

// relative ordering for attributes
enum AttrTag: Comparable, Hashable {
    case id
    case name
    case content
    case href
    case src
    case alt
    case title
    case `class`
    case generic(String)
}

enum Attr {
    case id(String)
    case lang(String)
}

typealias AttrMap = [AttrTag: String]

extension AttrMap {
    init(of attrs: [Attr]) {
        self = .empty
        for attr in attrs {
            let (name, value) = attr.components
            self[name] = value
        }
    }

    static var empty: AttrMap {
        [:]
    }
}

extension Attr {
    var components: (name: AttrTag, value: String) {
        switch self {
        case .id(let val): (.id, val)
        case .lang(let val): (.generic("lang"), val)
        }
    }
}
