let page = html(.lang("en")) {
    head {
        meta(charset: "utf-8")
        meta(.viewport(.width(.deviceWidth), .initialScale(1)))

        title("Gabriel Garcia")
    }
    body {
        h1("Gabriel Garcia")
        for i in 0..<10 {
            p("\(i)")
        }
    }
}

print(formatPage(page))
