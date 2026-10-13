import Foundation
import Markdown

// ---

struct PostMeta: Codable {
    let title: String
    let date: Date
}

let posts =
    try loadArticles(PostMeta.self, from: URL(filePath: "example/posts"))
    .sorted { $0.meta.date > $1.meta.date }

let site: TreeRoot = .root(
    index: .html(IndexPage(posts)),
    .dir(
        "posts",
        posts.map { post in
            .dir(
                post.path.fileName,
                index: .html(PostPage(post)),
            )
        }
    ),
)

switch CommandLine.arguments.dropFirst().first {
case "serve":
    try await site.serve()
default:
    try site.render(to: URL(fileURLWithPath: "_site", isDirectory: true))
}

// ---

func PostPage(_ post: Article<PostMeta>) -> Node {
    BaseLayout(title: post.meta.title) {
        h1(post.meta.title)
        p("Posted on \(post.meta.date.formatted(date: .long, time: .omitted))")
        markdown(post.body)
    }
}

func IndexPage(_ posts: [Article<PostMeta>]) -> Node {
    BaseLayout(title: "Gabriel Garcia") {
        h1("Gabriel Garcia")

        ul(posts) { post in
            li {
                a(href: "/posts/\(post.path.fileName)/") {
                    post.meta.title
                }
            }
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
