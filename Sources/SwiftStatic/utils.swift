import Foundation

extension CharacterSet {
    static let urlPathComponentAllowed: CharacterSet = {
        CharacterSet(charactersIn: "A"..."Z")
            | CharacterSet(charactersIn: "a"..."z")
            | CharacterSet(charactersIn: "0"..."9")
            | CharacterSet(charactersIn: "-._~")
    }()

    static func | (lhs: CharacterSet, rhs: CharacterSet) -> CharacterSet {
        return lhs.union(rhs)
    }
}

extension String {
    public var encodedURIComponent: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathComponentAllowed)!
    }
}

extension String {
    var htmlEscaped: String {
        var result = String()
        result.reserveCapacity(utf8.count)

        for scalar in unicodeScalars {
            switch scalar {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            case "'": result += "&#39;"
            default: result.unicodeScalars.append(scalar)
            }
        }

        return result
    }

    var htmlAttributeEscaped: String {
        var result = String()
        result.reserveCapacity(utf8.count)

        for scalar in unicodeScalars {
            switch scalar {
            case "&": result += "&amp;"
            case "\"": result += "&quot;"
            case "<": result += "&lt;"
            default: result.unicodeScalars.append(scalar)
            }
        }

        return result
    }
}

extension URL {
    public var fileName: String {
        deletingPathExtension().lastPathComponent
    }

    var pathExtensionMimeType: String {
        switch pathExtension {
        case "html": "text/html"
        case "css": "text/css"
        case "js": "text/javascript"
        case "json": "application/json"
        case "png": "image/png"
        case "jpg", "jpeg": "image/jpeg"
        default: "application/octet-stream"
        }
    }
}
