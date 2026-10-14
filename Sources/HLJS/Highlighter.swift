import Foundation
import JXKit

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
    case libraryError(any Error)
    case libraryInvalid
}

public enum HighlightError: Error {
    case languageNotFound
    case valueInvalid
    case failed
}

public struct Highlighter {
    private let hljs: JXValue

    public init() throws(HLJSInitError) {
        let context = JXContext()

        guard let hljsURL = Bundle.module.url(forResource: "hljs.min", withExtension: "js") else {
            throw .libraryMissing
        }

        guard let hljsCode = try? String(contentsOf: hljsURL) else {
            throw .libraryUnloadable
        }

        do {
            try context.eval(hljsCode)
        } catch {
            throw .libraryError(error)
        }

        do {
            self.hljs = try context.global["hljs"]
        } catch {
            throw .libraryInvalid
        }
    }

    public func highlight(_ code: String, language: String, ignoreIllegals: Bool = true)
        throws -> Highlighted
    {
        let languageFound = try hljs.invokeMethod("getLanguage", withArguments: [language])

        if languageFound.isUndefined {
            throw HighlightError.languageNotFound
        }

        let options: [String: Any] = [
            "language": language,
            "ignoreIllegals": ignoreIllegals,
        ]

        let result = try hljs.invokeMethod(
            "highlight",
            withArguments: [code, options],
        )

        let value = try result["value"]

        if value.isUndefined {
            throw HighlightError.failed
        }

        let language = try result["language"].string

        let tokens = try tokenize(value.string)

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
