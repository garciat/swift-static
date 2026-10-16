import Foundation
import JXKit

public struct Highlighted {
    public let tokens: [HighlightToken]
    public let language: String
}

public enum HighlightToken {
    case text(String)
    case tag(String, [Self])
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

public enum TokenizationError: Error {
    case excessiveDepth
    case unexpectedClosingTag
    case invalidOpeningTag
    case missingClosingTag
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

        let tokens = try Tokenizer.tokenize(value.string)

        return Highlighted(tokens: tokens, language: language)
    }
}

private struct Tokenizer {
    static func tokenize(_ source: String) throws(TokenizationError) -> [HighlightToken] {
        var input = source[...]
        return try enter(&input, level: 0)
    }

    private static func enter(_ input: inout String.SubSequence, level: Int)
        throws(TokenizationError)
        -> [HighlightToken]
    {
        if level > 10 {
            throw .excessiveDepth
        }

        var tokens = [HighlightToken]()

        while true {
            if let leading = input.pop(whileNot: "<") {
                tokens.append(.text(String(leading)))
            }

            if input.isEmpty {
                break
            }

            assert(input.first == "<")

            if input.starts(with: "</") {
                if level > 0 {
                    break
                } else {
                    throw .unexpectedClosingTag
                }
            }

            guard let match = input.pop(prefix: /<span class="(?<labels>[^"]+)">/) else {
                throw .invalidOpeningTag
            }

            let contents = try enter(&input, level: level + 1)

            tokens.append(.tag(String(match.output.labels), contents))

            guard input.pop(prefix: "</span>") else {
                throw .missingClosingTag
            }
        }

        return tokens
    }
}

extension String.SubSequence {
    fileprivate mutating func pop(whileNot delimiter: Character) -> Self? {
        let end = firstIndex(of: delimiter) ?? endIndex
        let out = self[..<end]
        self = self[end...]
        return out.isEmpty ? nil : out
    }

    fileprivate mutating func pop(prefix: Self) -> Bool {
        guard starts(with: prefix) else {
            return false
        }
        self = dropFirst(prefix.count)
        return true
    }

    fileprivate mutating func pop<R>(prefix regex: R) -> Regex<R.RegexOutput>.Match?
    where R: RegexComponent {
        guard let match = prefixMatch(of: regex) else {
            return nil
        }
        self = self[match.range.upperBound...]
        return match
    }
}
