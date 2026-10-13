import Foundation
import Markdown

// ---

struct PostMeta: Codable {
    let title: String
}

let postRaw =
    """
    ---
    title: Welcome
    ---
    # Title

    [Hello World](https://garciat.com)

    ## What

    **Yes!!**
    """

let post = try parseFrontmatter(postRaw)?.mapYaml(to: PostMeta.self)

let site: TreeRoot = .root(
    index: .html(IndexPage()),
    .dir(
        "posts",
        index: .html {
            PostPage(title: post!.frontmatter.title) {
                markdown(post!.body)
            }
        }
    ),
)

try site.render(to: URL(fileURLWithPath: "_site", isDirectory: true))

try await site.serve()

// ---

func PostPage(title: String, @HtmlBuilder content: () -> Node) -> Node {
    BaseLayout(title: title) {
        content()
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

func BaseLayout(title theTitle: String, @HtmlBuilder content: () -> Node) -> Node {
    html(.lang("en")) {
        head {
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width,initial-scale=1.0")

            title(theTitle)
        }
        body {
            content()
        }
    }
}
