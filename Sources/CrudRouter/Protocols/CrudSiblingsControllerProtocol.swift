import Vapor
import Fluent

public protocol CrudSiblingsControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database
    associatedtype ThroughType: ModifiablePivot where
        ThroughType.Database: JoinSupporting,
        ChildType.Database == ThroughType.Database
    
    var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>> { get }
    
    func index(_ req: Request) throws -> Future<ChildType>
    func indexAll(_ req: Request) throws -> Future<[ChildType]>
    func update(_ req: Request) throws -> Future<ChildType>
}

public extension CrudSiblingsControllerProtocol {
    func index(_ req: Request) throws -> Future<ChildType> {
        let parentId: ParentType.ID = try getId(from: req)
        let childId: ChildType.ID = try getId(from: req)
        
        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in
            
            return try parent[keyPath: self.siblings]
                .query(on: req)
                .filter(\ChildType.fluentID == childId)
                .first()
                .unwrap(or: Abort(.notFound))
        }
    }
    
    func indexAll(_ req: Request) throws -> Future<[ChildType]> {
        let parentId: ParentType.ID = try getId(from: req)
        
        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<[ChildType]> in
            let siblingsRelation = parent[keyPath: self.siblings]
            return try siblingsRelation
                .query(on: req)
                .all()
        }
    }
    
    func update(_ req: Request) throws -> Future<ChildType> {
        let parentId: ParentType.ID = try getId(from: req)
        let childId: ChildType.ID = try getId(from: req)
        
        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> Future<ChildType> in
                return try parent[keyPath: self.siblings]
                    .query(on: req)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
            }.flatMap { oldChild in
                return try req.content.decode(ChildType.self).flatMap { newChild in
                    var temp = newChild
                    temp.fluentID = oldChild.fluentID
                    return temp.update(on: req)
                }
        }
    }
}

public extension CrudSiblingsControllerProtocol where ThroughType.Left == ParentType,
ThroughType.Right == ChildType {
    func create(_ req: Request) throws -> Future<ChildType> {
        let parentId: ParentType.ID = try getId(from: req)
        
        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in
            
            return try req.content.decode(ChildType.self).flatMap { child in
                let relation = parent[keyPath: self.siblings]
                return relation.attach(child, on: req).transform(to: child)
            }
        }
    }
    
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let parentId: ParentType.ID = try getId(from: req)
        let childId: ChildType.ID = try getId(from: req)
        
        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> Future<HTTPStatus> in
                let siblingsRelation = parent[keyPath: self.siblings]
                return try siblingsRelation
                    .query(on: req)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .flatMap { siblingsRelation.detach($0, on: req).transform(to: $0) }
                    .delete(on: req)
                    .transform(to: HTTPStatus.ok)
        }
    }
}

public extension CrudSiblingsControllerProtocol where ThroughType.Right == ParentType,
ThroughType.Left == ChildType {
    func create(_ req: Request) throws -> Future<ChildType> {
        let parentId: ParentType.ID = try getId(from: req)
        
        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in
            
            return try req.content.decode(ChildType.self).flatMap { child in
                return child.create(on: req)
                }.flatMap { child in
                    let relation = parent[keyPath: self.siblings]
                    return relation.attach(child, on: req).transform(to: child)
            }
        }
    }
    
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let parentId: ParentType.ID = try getId(from: req)
        let childId: ChildType.ID = try getId(from: req)
        
        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> Future<HTTPStatus> in
                let siblingsRelation = parent[keyPath: self.siblings]
                return try siblingsRelation
                    .query(on: req)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .delete(on: req)
                    .transform(to: HTTPStatus.ok)
        }
    }
}

fileprivate extension CrudSiblingsControllerProtocol {
    func getId<T: ID & Parameter>(from req: Request) throws -> T {
        guard let id = try req.parameters.next(T.self) as? T else { fatalError() }
        
        return id
    }
}

