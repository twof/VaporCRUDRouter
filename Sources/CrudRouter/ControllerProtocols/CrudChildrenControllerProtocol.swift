import Vapor
import FluentKit

protocol CrudChildrenControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible

    var children: KeyPath<ParentType, ChildrenProperty<ParentType, ChildType>> { get }

    func index(_ req: Request) async throws -> Response
    func indexAll(_ req: Request) async throws -> Response
    func create(_ req: Request) async throws -> Response
    func update(_ req: Request) async throws -> Response
    func delete(_ req: Request) async throws -> Response
}

extension CrudChildrenControllerProtocol {
    func index(_ req: Request) async throws -> Response {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.children].query(on: req.db).filter(\._$id == childId).first()
        else {
            throw Abort(.notFound)
        }

        return try await child.encodeResponse(status: .ok, for: req)
    }

    func indexAll(_ req: Request) async throws -> Response {
        let parentId = try req.getId(modelType: ParentType.self)

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        let children = try await parent[keyPath: self.children].query(on: req.db).all()
        return try await children.encodeResponse(status: .ok, for: req)
    }

    func create(_ req: Request) async throws -> Response {
        let parentId = try req.getId(modelType: ParentType.self)

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        let child = try req.content.decode(ChildType.self)
        try await parent[keyPath: self.children].create(child, on: req.db)

        return try await child.encodeResponse(status: .created, for: req)
    }

    func update(_ req: Request) async throws -> Response {
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
        return try await temp.encodeResponse(status: .ok, for: req)
    }

    func delete(_ req: Request) async throws -> Response {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.children].query(on: req.db).filter(\._$id == childId).first()
        else {
            throw Abort(.notFound)
        }

        try await child.delete(on: req.db)
        return try await HTTPStatus.noContent.encodeResponse(for: req)
    }
}
