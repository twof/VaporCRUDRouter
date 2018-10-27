import Vapor
import Fluent

public protocol CrudParentControllerProtocol: Crudable {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database

    var relation: KeyPath<ChildType, Parent<ChildType, ParentType>> { get }

    func index(_ req: Request) throws -> Future<ParentType>
    func update(_ req: Request) throws -> Future<ParentType>
}

public extension CrudParentControllerProtocol {
    func index(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try req.getId()

        return ChildType.find(childId, on: req).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try req.getId()

        return ChildType
            .find(childId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { child in
                return child[keyPath: self.relation].get(on: req)
        }
    }
}
