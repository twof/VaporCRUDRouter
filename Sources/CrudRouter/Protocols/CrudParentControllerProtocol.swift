import Vapor
import Fluent

public protocol CrudParentControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database
    
    var relation: KeyPath<ChildType, Parent<ChildType, ParentType>> { get }
    
    func index(_ req: Request) throws -> Future<ParentType>
    func update(_ req: Request) throws -> Future<ParentType>
}

public extension CrudParentControllerProtocol {
    
    func index(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try getId(from: req)
        
        return ChildType.find(childId, on: req).unwrap(or: Abort(.notFound)).flatMap { child in
            child[keyPath: self.relation].get(on: req)
        }
    }
    
    func update(_ req: Request) throws -> Future<ParentType> {
        let childId: ChildType.ID = try getId(from: req)
        
        return ChildType
            .find(childId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { child in
                return child[keyPath: self.relation].get(on: req)
        }
    }
}

fileprivate extension CrudParentControllerProtocol {
    func getId<T: ID & Parameter>(from req: Request) throws -> T {
        guard let id = try req.parameters.next(T.self) as? T else { fatalError() }
        
        return id
    }
}

