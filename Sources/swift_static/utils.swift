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
