import Foundation

enum Response {
    case data(Data)
    case html(Node)
    case string(String)
}

indirect enum Tree: Sendable {
    case file(String, Response)
    case dir(String, Tree)

    case node(index: Response? = nil, [Tree])

    static func node(index: Response? = nil, _ items: Tree...) -> Tree {
        .node(index: index, items)
    }

    static func node(_ name: String, index: Response? = nil, _ items: Tree...) -> Tree {
        .dir(name, .node(index: index, items))
    }
}

func BaseLayout(title theTitle: String, @HtmlBuilder content: () -> [Node]) -> Node {
    html(.lang("en")) {
        head {
            meta(charset: "utf-8")
            meta(.viewport(.width(.deviceWidth), .initialScale(1)))

            title(theTitle)
        }
        body {
            content()
        }
    }
}

func IndexPage() -> Node {
    BaseLayout(title: "Gabriel Garcia") {
        h1("Gabriel Garcia")
        for i in 0..<10 {
            p("\(i)")
        }
    }
}

let site: Tree = .node(
    index: .html(IndexPage()),
    .node(
        "posts",
        index: .string("hi")
    ),
)
