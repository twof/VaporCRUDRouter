import Vapor
import Fluent
import FluentKit

extension EventLoopFuture {
    func throwingFlatMap<NewValue>(file: StaticString = #file, line: UInt = #line, _ callback: @escaping ((Value) throws -> EventLoopFuture<NewValue>)) rethrows -> EventLoopFuture<NewValue> {
        return self.flatMap(file: file, line: line) { (value: Value) -> EventLoopFuture<NewValue> in
            do {
                return try callback(value)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
}

// TODO: Do these proocols actually need to be public?
public protocol CrudSiblingsControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible
    associatedtype ThroughType: Model

    var siblings: KeyPath<ParentType, SiblingsProperty<ParentType, ChildType, ThroughType>> { get }

    func index(_ req: Request) async throws -> ChildType
    func indexAll(_ req: Request) async throws -> [ChildType]
    func update(_ req: Request) async throws -> ChildType
}

public extension CrudSiblingsControllerProtocol {
    func index(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        // TODO: childId isn't being used. This probably isn't correct.
        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.siblings].query(on: req.db).first()
        else {
            throw Abort(.notFound)
        }

        return child
    }

    func indexAll(_ req: Request) async throws -> [ChildType] {
        let parentId = try req.getId(modelType: ParentType.self)

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        return try await parent[keyPath: self.siblings].query(on: req.db).all()
    }

    func update(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        // TODO: Make sure this actually updates the siblings. Parent is never used.
        guard
            let parent = try await ParentType.find(parentId, on: req.db)
        else {
            throw Abort(.notFound)
        }

        let newChild = try req.content.decode(ChildType.self)
        let temp = newChild
        temp.id = childId

        try await temp.update(on: req.db)
        return temp
    }
}

public extension CrudSiblingsControllerProtocol {
    func create(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        let newChild = try req.content.decode(ChildType.self)
        try await parent[keyPath: self.siblings].attach(newChild, on: req.db)
        return newChild
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        let parentId = try req.getId(modelType: ParentType.self)

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        let siblingsRelation = parent[keyPath: self.siblings]

        guard let child = try await siblingsRelation.query(on: req.db).first() else {
            throw Abort(.notFound)
        }

        try await siblingsRelation.detach(child, on: req.db)
        try await child.delete(on: req.db)
        return HTTPStatus.ok
    }
}
