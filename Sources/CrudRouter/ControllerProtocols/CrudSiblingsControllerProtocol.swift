import Vapor
import FluentKit

protocol CrudSiblingsControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible
    associatedtype ThroughType: Model

    var siblings: KeyPath<ParentType, SiblingsProperty<ParentType, ChildType, ThroughType>> { get }

    func index(_ req: Request) async throws -> Response
    func indexAll(_ req: Request) async throws -> Response
    func create(_ req: Request) async throws -> Response
    func update(_ req: Request) async throws -> Response
    func delete(_ req: Request) async throws -> Response
}

extension CrudSiblingsControllerProtocol {
    func index(_ req: Request) async throws -> Response {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            let child = try await parent[keyPath: self.siblings].query(on: req.db).filter(\._$id == childId).first()
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

        let siblings = try await parent[keyPath: self.siblings].query(on: req.db).all()
        return try await siblings.encodeResponse(status: .ok, for: req)
    }

    func create(_ req: Request) async throws -> Response {
        let parentId = try req.getId(modelType: ParentType.self)

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        let newChild = try req.content.decode(ChildType.self)
        try await parent[keyPath: self.siblings].attach(newChild, on: req.db)
        return try await newChild.encodeResponse(status: .created, for: req)
    }

    func update(_ req: Request) async throws -> Response {
        let parentId = try req.getId(modelType: ParentType.self)
        let childId = try req.getId(modelType: ChildType.self)

        guard
            let parent = try await ParentType.find(parentId, on: req.db),
            try await parent[keyPath: self.siblings].query(on: req.db).filter(\._$id == childId).first() != nil
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

        guard let parent = try await ParentType.find(parentId, on: req.db) else {
            throw Abort(.notFound)
        }

        let siblingsRelation = parent[keyPath: self.siblings]

        guard let child = try await siblingsRelation.query(on: req.db).first() else {
            throw Abort(.notFound)
        }

        try await siblingsRelation.detach(child, on: req.db)
        try await child.delete(on: req.db)
        return try await HTTPStatus.noContent.encodeResponse(for: req)
    }
}
