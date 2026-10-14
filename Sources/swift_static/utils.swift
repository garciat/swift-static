import Foundation

extension CharacterSet {
    static var urlPathSegmentAllowed: CharacterSet {
        CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()"
        )
    }
}

extension String {
    var encodedURIComponent: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathSegmentAllowed)!
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
    var fileName: String {
        let last = lastPathComponent
        return last.lastIndex(of: ".")
            .map { String(last.prefix(upTo: $0)) }
            ?? last
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
