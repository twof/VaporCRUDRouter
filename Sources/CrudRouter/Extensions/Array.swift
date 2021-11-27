import Vapor

extension Array {
    func appending(_ element: Element) -> Array<Element> {
        var temp = self
        temp.append(element)
        return temp
    }
}

extension Array where Element == PathComponent {
    func adjustedPath<T>(for type: T.Type) -> [PathComponent] {
        return self.count == 0
            ? [.constant(String(describing: T.self).snakeCased())]
            : self
    }
}
