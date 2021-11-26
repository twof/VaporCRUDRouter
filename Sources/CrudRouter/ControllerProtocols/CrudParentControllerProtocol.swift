import Vapor
import FluentKit

protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible

    var relation: KeyPath<ChildType, ParentProperty<ChildType, ParentType>> { get }

    func index(_ req: Request) async throws -> ParentType
    func update(_ req: Request) async throws -> ParentType
}

extension CrudParentControllerProtocol {
    func index(_ req: Request) async throws -> ParentType {
        let childId = try req.getId(modelType: ChildType.self)

        guard let child = try await ChildType.find(childId, on: req.db) else {
            throw Abort(.notFound)
        }

        return try await child[keyPath: self.relation].get(on: req.db)
    }

    func update(_ req: Request) async throws -> ParentType {
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
        return temp
    }
}
