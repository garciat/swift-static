import Foundation
import Markdown

// ---

struct PostMeta: Codable {
    let title: String
    let date: Date
}

extension Article<PostMeta> {
    static var dirName: String {
        "posts"
    }

    var slug: String {
        path.fileName.encodedURIComponent
    }

    var absolutePath: String {
        "/\(Self.dirName)/\(slug)/"
    }
}

let posts =
    try loadArticles(PostMeta.self, from: URL(filePath: "example/posts"))
    .sorted { $0.meta.date > $1.meta.date }

let site: Site = .root(
    index: .html(IndexPage(posts)),
    .dir(
        Article<PostMeta>.dirName,
        posts.map { post in
            .dir(post.slug, index: .html(PostPage(post)))
        }
    ),
)

try await site.main()

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
                a(href: H.url(post.absolutePath)) {
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
