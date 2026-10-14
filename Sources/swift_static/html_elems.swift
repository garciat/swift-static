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

func ul<S: Sequence>(_ items: S, @HtmlBuilder content: (S.Element) -> Node) -> Node {
    e("ul") {
        for item in items {
            content(item)
        }
    }
}

func li(@HtmlBuilder content: () -> Node) -> Node {
    e("li", content)
}

func a(href: String, @HtmlBuilder content: () -> Node) -> Node {
    e("a", attrs: [.href: href], content)
}
