import Vapor
import Fluent

public protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible
    
    var db: Database { get }

    var relation: KeyPath<ChildType, Parent<ParentType>> { get }

    func index(_ req: Request) throws -> EventLoopFuture<ParentType>
    func update(_ req: Request) throws -> EventLoopFuture<ParentType>
}

public extension CrudParentControllerProtocol {
    func index(_ req: Request) throws -> EventLoopFuture<ParentType> {
        let childId: ChildType.IDValue = try req.getId()

        return ChildType.find(childId, on: db).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: self.db)
        }
    }

    func update(_ req: Request) throws -> EventLoopFuture<ParentType> {
        let childId: ChildType.IDValue = try req.getId()

        return ChildType
            .find(childId, on: db)
            .unwrap(or: Abort(.notFound))
            .flatMap { child in
                return child[keyPath: self.relation].get(on: self.db)
        }
    }
}
