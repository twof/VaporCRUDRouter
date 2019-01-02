import Vapor
import Fluent

public protocol CrudParentControllerProtocol: ControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database

    var relation: KeyPath<ChildType, Parent<ChildType, ParentType>> { get }

    func index(_ req: Request) throws -> Future<ReturnModelType>
    func update(_ req: Request) throws -> Future<ReturnModelType>
}

public extension CrudParentControllerProtocol where ModelType == ReturnModelType, ModelType == ParentType {
    func index(_ req: Request) throws -> Future<ReturnModelType> {
        let childId: ChildType.ID = try req.getId()

        return ChildType.find(childId, on: req).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<ReturnModelType> {
        let childId: ChildType.ID = try req.getId()

        return ChildType
            .find(childId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { child in
                return child[keyPath: self.relation].get(on: req)
        }
    }
}

public extension CrudParentControllerProtocol where ModelType: Publicable, ReturnModelType == ModelType.PublicModel, ModelType == ParentType {
    func index(_ req: Request) throws -> Future<ReturnModelType> {
        let childId: ChildType.ID = try req.getId()
        
        return ChildType.find(childId, on: req).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: req).flatMap { try $0.public(on: req) }
        }
    }
    
    func update(_ req: Request) throws -> Future<ReturnModelType> {
        let childId: ChildType.ID = try req.getId()
        
        return ChildType
            .find(childId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { child in
                return child[keyPath: self.relation].get(on: req).flatMap { try $0.public(on: req) }
        }
    }
}
