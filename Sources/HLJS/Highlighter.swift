import JavaScriptCore

public struct Highlighted {
    public let tokens: [HighlightToken]
    public let language: String
}

public struct HighlightToken {
    // https://highlightjs.readthedocs.io/en/latest/css-classes-reference.html
    public let kind: String?
    public let text: String
}

public enum HLJSInitError: Error {
    case contextMissing
    case libraryMissing
    case libraryUnloadable
    case libraryInvalid
}

public enum HighlightError: Error {
    case languageNotFound
    case resultNotFound
    case valueNotFound
    case valueInvalid
    case failed
}

public struct Highlighter {
    private let hljs: JSValue

    public init() throws(HLJSInitError) {
        guard let context = JSContext() else {
            throw .contextMissing
        }

        guard let hljsURL = Bundle.module.url(forResource: "hljs.min", withExtension: "js") else {
            throw .libraryMissing
        }

        guard let hljsCode = try? String(contentsOf: hljsURL) else {
            throw .libraryUnloadable
        }

        context.evaluateScript(hljsCode)

        guard let hljs = context.objectForKeyedSubscript("hljs") else {
            throw .libraryInvalid
        }

        self.hljs = hljs
    }

    public func highlight(_ code: String, language: String, ignoreIllegals: Bool = true)
        throws(HighlightError) -> Highlighted
    {
        guard let languageFound = hljs.invokeMethod("getLanguage", withArguments: [language]) else {
            throw .languageNotFound
        }

        if languageFound.isUndefined {
            throw .languageNotFound
        }

        let options: [String: Any] = [
            "language": language,
            "ignoreIllegals": ignoreIllegals,
        ]

        guard
            let result = hljs.invokeMethod(
                "highlight",
                withArguments: [code, options],
            )
        else {
            throw .resultNotFound
        }

        if result.objectForKeyedSubscript("value").isUndefined {
            throw .failed
        }

        guard
            let value = result.objectForKeyedSubscript("value").toString(),
            let language = result.objectForKeyedSubscript("language").toString()
        else {
            throw .valueNotFound
        }

        let tokens = try tokenize(value)

        return Highlighted(tokens: tokens, language: language)
    }
}

private func tokenize(_ output: String) throws(HighlightError) -> [HighlightToken] {
    let spanPattern = /<span class="(?<kind>[^"]+)">(?<text>[^<]+)<\/span>/

    var tokens = [HighlightToken]()

    var text = output[...]

    while !text.isEmpty {
        let nextSpan = text.firstIndex(of: "<") ?? text.endIndex

        let plain = text[..<nextSpan]

        if !plain.isEmpty {
            tokens.append(HighlightToken(kind: nil, text: String(plain)))
        }

        if nextSpan == text.endIndex {
            break
        }

        guard let match = text[nextSpan...].firstMatch(of: spanPattern) else {
            throw .valueInvalid
        }

        tokens.append(
            HighlightToken(
                kind: String(match.output.kind),
                text: String(match.output.text),
            )
        )

        text = text[match.range.upperBound...]
    }

    return tokens
}
