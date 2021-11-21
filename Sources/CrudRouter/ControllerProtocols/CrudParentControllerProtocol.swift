import Vapor
import Fluent

public protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible

    var relation: KeyPath<ChildType, ParentProperty<ChildType, ParentType>> { get }

    func index(_ req: Request) async throws -> ParentType
    func update(_ req: Request) async throws -> ParentType
}

public extension CrudParentControllerProtocol {
    func index(_ req: Request) async throws -> ParentType {
        let childId = try req.getId(modelType: ChildType.self)

        guard let child = try await ChildType.find(childId, on: req.db) else {
            throw Abort(.notFound)
        }

        return try await child[keyPath: self.relation].get(on: req.db)
    }

    func update(_ req: Request) async throws -> ParentType {
//        let childId = try req.getId(modelType: ChildType.self)
        let parentId = try req.getId(modelType: ParentType.self)
        let newParent = try req.content.decode(ParentType.self)
        // TODO: make sure this actually updates the parent

        let temp = newParent
        temp.id = parentId
        try await temp.update(on: req.db)
        return temp
    }
}
