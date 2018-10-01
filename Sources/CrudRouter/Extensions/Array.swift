public extension Array {
    public func appending(_ element: Element) -> Array<Element> {
        var temp = self
        temp.append(element)
        return temp
    }
}
