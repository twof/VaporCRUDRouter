import Vapor
import FluentKit

protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible

    var relation: KeyPath<ChildType, ParentProperty<ChildType, ParentType>> { get }

    func index(_ req: Request) async throws -> Response
    func update(_ req: Request) async throws -> Response
}

extension CrudParentControllerProtocol {
    func index(_ req: Request) async throws -> Response {
        let childId = try req.getId(modelType: ChildType.self)

        guard let child = try await ChildType.find(childId, on: req.db) else {
            throw Abort(.notFound)
        }

        let body = try await child[keyPath: self.relation].get(on: req.db)
        return try await body.encodeResponse(status: .ok, for: req)
    }

    func update(_ req: Request) async throws -> Response {
        let childId = try req.getId(modelType: ChildType.self)
        let newParent = try req.content.decode(ParentType.self)

        guard let child = try await ChildType.find(childId, on: req.db) else {
            throw Abort(.notFound)
        }

        let oldParent = try await child[keyPath: self.relation].get(on: req.db)

        let temp = newParent
        temp.id = oldParent.id
        temp._$id.exists = true
        try await temp.update(on: req.db)
        return try await temp.encodeResponse(status: .ok, for: req)
    }
}
