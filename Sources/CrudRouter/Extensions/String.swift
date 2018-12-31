import Foundation

public extension String {
    
    /// Returns a snake cased version of self if possible
    ///
    /// - Returns: A snake cased version of self
    public func snakeCased() -> String? {
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
}
