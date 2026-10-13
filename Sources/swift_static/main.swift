import Foundation

// ---

let site: TreeRoot = .root(
    index: .html(IndexPage()),
    .dir(
        "posts",
        index: .string("hi")
    ),
)

try site.render(to: URL(fileURLWithPath: "_site", isDirectory: true))

try await site.serve()

// ---

func IndexPage() -> Node {
    BaseLayout(title: "Gabriel Garcia") {
        h1("Gabriel Garcia")
        for i in 0..<10 {
            p("\(i)")
        }
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
