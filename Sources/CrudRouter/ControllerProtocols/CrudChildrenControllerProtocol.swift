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
        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.children].query(on: req.db).first()
        else {
            throw Abort(.notFound)
        }

        return child
    }

    func indexAll(_ req: Request) async throws -> [ChildType] {
        let parentId = try req.getId(modelType: ParentType.self)
        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<[ChildType]> in
                return try parent[keyPath: self.children]
                    .query(on: req.db)
                    .all()
            }
    }

    func create(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)

        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<ChildType> in
                let child = try req.content.decode(ChildType.self)
                return child.save(on: req.db).transform(to: child)
        }
    }

    func update(_ req: Request) async throws -> ChildType {
        let parentId = try req.getId(modelType: ParentType.self)

        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<ChildType> in
                return try parent[keyPath: self.children]
                    .query(on: req.db)
                    .first()
                    .unwrap(or: Abort(.notFound))
            }.throwingFlatMap { oldChild in
                let newChild = try req.content.decode(ChildType.self)
                let temp = newChild
                temp.id = oldChild.id
                return temp.update(on: req.db).transform(to: temp)
        }
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        let parentId = try req.getId(modelType: ParentType.self)
        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.children].query(on: req.db).first()
        else {
            throw Abort(.notFound)
        }

        try await child.delete(on: req.db)
        return HTTPStatus.ok
    }
}
