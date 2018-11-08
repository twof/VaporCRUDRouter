import Vapor

public protocol Returnable {
    associatedtype Return: Content = Self
}

public extension Returnable where Self: Publicable & Content {
    typealias Return = Self.PublicModel
}
