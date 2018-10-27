import Vapor

public extension Array {
    public func appending(_ element: Element) -> Array<Element> {
        var temp = self
        temp.append(element)
        return temp
    }

    public func appending(_ elements: Array<Element>) -> Array<Element> {
        var temp = self
        temp.append(contentsOf: elements)
        return temp
    }
}

extension Array where Element == PathComponentsRepresentable {
    func adjustedPath<T>(for type: T.Type) -> [PathComponentsRepresentable] {
        return self.count == 0
            ? [String(describing: T.self).snakeCased()! as PathComponentsRepresentable]
            : self
    }
}
