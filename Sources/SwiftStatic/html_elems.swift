// Parent Element
func e(_ name: String, attrs: AttrMap = .empty, children: [Node]) -> Node {
    .elem(Elem(name: name, attrs: attrs, children: children))
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
func e(_ name: String, attrs: AttrMap = .empty) -> Node {
    .void(VElem(name: name, attrs: attrs))
}

public func html(_ attrs: Attr..., @HtmlBuilder content: () -> Node) -> Node {
    e("html", attrs: AttrMap(of: attrs), content)
}

public func head(@HtmlBuilder content: () -> Node) -> Node {
    e("head", content)
}

public func title(_ text: String) -> Node {
    e("title") { text }
}

public func meta(charset: String) -> Node {
    e("meta", attrs: [.generic("charset"): charset])
}

public func meta(name: String, content: String) -> Node {
    return e("meta", attrs: [.name: name, .content: content])
}

public func link(stylesheetURL: String) -> Node {
    return e("link", attrs: [.rel: "stylesheet", .href: stylesheetURL])
}

public func body(@HtmlBuilder content: () -> Node) -> Node {
    e("body", content)
}

public func div(_ attrs: Attr..., @HtmlBuilder content: () -> Node) -> Node {
    e("div", attrs: AttrMap(of: attrs), content)
}

public func h1(_ text: String) -> Node {
    e("h1") { text }
}

public func p(_ text: String) -> Node {
    e("p") { text }
}

public func ul<S: Sequence>(_ items: S, @HtmlBuilder content: (S.Element) -> Node) -> Node {
    e("ul") {
        for item in items {
            content(item)
        }
    }
}

public func li(@HtmlBuilder content: () -> Node) -> Node {
    e("li", content)
}

public func a(href: String, @HtmlBuilder content: () -> Node) -> Node {
    e("a", attrs: [.href: href], content)
}
