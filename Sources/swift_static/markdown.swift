import Markdown

func markdown(_ raw: String) -> Node {
    var visitor = DocumentToNodes()
    let doc = Document(parsing: raw)
    return doc.accept(&visitor)
}

private struct DocumentToNodes: MarkupVisitor {
    typealias Result = Node

    mutating func visitDocument(_ document: Document) -> Node {
        .fragment(visitChildren(document))
    }

    mutating func visitHeading(_ heading: Heading) -> Node {
        e("h\(heading.level)") { heading.plainText }
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> Node {
        e("p", children: visitChildren(paragraph))
    }

    mutating func visitLink(_ link: Link) -> Node {
        var attrs = AttrMap()
        if let dest = link.destination {
            attrs[.href] = dest
        }
        return e("a", attrs: attrs, children: visitChildren(link))
    }

    mutating func visitStrong(_ strong: Strong) -> Node {
        e("strong", children: visitChildren(strong))
    }

    mutating func visitText(_ text: Text) -> Node {
        .text(text.string)
    }

    func defaultVisit(_ markup: any Markdown.Markup) -> Node {
        fatalError("unhandled markdown markup: \(type(of: markup))")
    }

    private mutating func visitChildren(_ markup: any Markdown.Markup) -> [Node] {
        markup.children.compactMap { $0.accept(&self) }
    }
}
