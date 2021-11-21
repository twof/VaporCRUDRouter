import Vapor
import Fluent

public protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible

    var relation: KeyPath<ChildType, ParentProperty<ChildType, ParentType>> { get }

    func index(_ req: Request) throws -> EventLoopFuture<ParentType>
    func update(_ req: Request) throws -> EventLoopFuture<ParentType>
}

public extension CrudParentControllerProtocol {
    func index(_ req: Request) throws -> EventLoopFuture<ParentType> {
        let childId = try req.getId(modelType: ChildType.self)

        return ChildType.find(childId, on: req.db).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: req.db)
        }
    }

    func update(_ req: Request) throws -> EventLoopFuture<ParentType> {
        let childId = try req.getId(modelType: ChildType.self)

        return ChildType
            .find(childId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { child in
                return child[keyPath: self.relation].get(on: req.db)
        }
    }
}
