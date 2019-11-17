import Vapor

public extension Array {
    public func appending(_ element: Element) -> Array<Element> {
        var temp = self
        temp.append(element)
        return temp
    }
}

extension Array where Element == PathComponent {
    func adjustedPath<T>(for type: T.Type) -> [PathComponent] {
        return self.count == 0
            ? [String(describing: T.self).snakeCased()! as PathComponent]
            : self
    }
}
