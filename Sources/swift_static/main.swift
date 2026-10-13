import Foundation
import Markdown

// ---

struct PostMeta: Codable {
    let title: String
}

let posts = try loadArticles(PostMeta.self, from: URL(filePath: "example/posts"))

let site: TreeRoot = .root(
    index: .html(IndexPage(posts)),
    .dir(
        "posts",
        posts.map { post in
            .dir(
                post.path.fileName,
                index: .html {
                    PostPage(title: post.meta.title) {
                        markdown(post.body)
                    }
                },
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

func PostPage(title: String, @HtmlBuilder content: () -> Node) -> Node {
    BaseLayout(title: title) {
        content()
    }
}

func IndexPage(_ posts: [Article<PostMeta>]) -> Node {
    BaseLayout(title: "Gabriel Garcia") {
        h1("Gabriel Garcia")

        e("ul") {
            for post in posts {
                e("li") {
                    a(href: "/posts/\(post.path.fileName)/") {
                        post.meta.title
                    }
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
