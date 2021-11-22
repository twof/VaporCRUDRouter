import Vapor
import FluentKit
import Fluent
import NIOExtras

public protocol CrudChildrenControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible

    var children: KeyPath<ParentType, ChildrenProperty<ParentType, ChildType>> { get }

    func index(_ req: Request) async throws -> ChildType
    func indexAll(_ req: Request) async throws -> [ChildType]
    func create(_ req: Request) async throws -> ChildType
    func update(_ req: Request) async throws -> ChildType
    func delete(_ req: Request) async throws -> HTTPStatus
}

public extension CrudChildrenControllerProtocol {
    func index(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.children].query(on: req.db).filter(\._$id == childId).first()
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

        return try await parent[keyPath: self.children].query(on: req.db).all()
    }

    func create(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        let child = try req.content.decode(ChildType.self)
        try await parent[keyPath: self.children].create(child, on: req.db)

        return child
    }

    func update(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            try await parent[keyPath: self.children].query(on: req.db).filter(\._$id == childId).first() != nil
        else {
            throw Abort(.notFound)
        }

        let newChild = try req.content.decode(ChildType.self)
        let temp = newChild
        temp._$id.exists = true
        temp.id = childId
        try await temp.update(on: req.db)
        return temp
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.children].query(on: req.db).filter(\._$id == childId).first()
        else {
            throw Abort(.notFound)
        }

        try await child.delete(on: req.db)
        return HTTPStatus.ok
    }
}
