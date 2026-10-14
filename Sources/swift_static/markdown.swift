import HLJS
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
        e("h\(heading.level)", children: visitChildren(heading))
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> Node {
        e("p", children: visitChildren(paragraph))
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Node {
        e("blockquote", children: visitChildren(blockQuote))
    }

    func visitLineBreak(_ lineBreak: LineBreak) -> Node {
        e("br")
    }

    func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Node {
        e("hr")
    }

    func visitSoftBreak(_ softBreak: SoftBreak) -> Node {
        .text(" ")
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> Node {
        e("ul", children: visitChildren(unorderedList))
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> Node {
        var attrs = AttrMap()
        attrs[.generic("start")] = orderedList.startIndex.formatted()
        return e("ol", attrs: attrs, children: visitChildren(orderedList))
    }

    mutating func visitListItem(_ listItem: ListItem) -> Node {
        e("li") {
            if let cb = listItem.checkbox {
                makeCheckbox(cb)
            }
            visitChildren(listItem)
        }
    }

    private func makeCheckbox(_ checkbox: Checkbox) -> Node {
        var attrs: AttrMap = [
            .generic("type"): "checkbox",
            .generic("disabled"): "",
        ]
        if checkbox == .checked {
            attrs[.generic("checked")] = ""
        }
        return e("input", attrs: attrs)
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Node {
        var codeAttrs = AttrMap()
        codeAttrs[.class] = codeBlock.language.map { "language-" + $0 }

        return e("pre") {
            e("code", attrs: codeAttrs) {
                highlightedCode(codeBlock.code, language: codeBlock.language)
            }
        }
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> Node {
        e("code") { inlineCode.code }
    }

    mutating func visitLink(_ link: Link) -> Node {
        var attrs = AttrMap()
        attrs[.href] = link.destination
        return e("a", attrs: attrs, children: visitChildren(link))
    }

    func visitImage(_ image: Image) -> Node {
        var attrs = AttrMap()
        attrs[.src] = image.source
        attrs[.alt] = image.plainText
        attrs[.title] = image.title
        return e("img", attrs: attrs)
    }

    mutating func visitStrong(_ strong: Strong) -> Node {
        e("strong", children: visitChildren(strong))
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> Node {
        e("em", children: visitChildren(emphasis))
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> Node {
        e("del", children: visitChildren(strikethrough))
    }

    func visitText(_ text: Text) -> Node {
        .text(text.string)
    }

    func defaultVisit(_ markup: any Markdown.Markup) -> Node {
        fatalError("unhandled markdown markup: \(type(of: markup))")
    }

    private mutating func visitChildren(_ markup: any Markdown.Markup) -> [Node] {
        markup.children.compactMap { $0.accept(&self) }
    }
}

private func highlightedCode(_ code: String, language: String?) -> Node {
    guard let language = language else {
        return .text(code)
    }

    do {
        let highlighter = try Highlighter()
        let result = try highlighter.highlight(code, language: language)
        return renderTokens(result.tokens)
    } catch {
        print("[ERROR] highlight: \(error)")
        return .text(code)
    }
}

private func renderTokens(_ tokens: [HighlightToken]) -> Node {
    .fragment(
        // NOTE: assumes hljs has html-escaped the code
        tokens.map { token in
            if let kind = token.kind {
                return e("span", .class(kind)) { .raw(token.text) }
            } else {
                return .raw(token.text)
            }
        }
    )
}
