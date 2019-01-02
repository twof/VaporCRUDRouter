import Vapor
import Fluent

public protocol CrudChildrenControllerProtocol: ControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database

    var children: KeyPath<ParentType, Children<ParentType, ChildType>> { get }

    func index(_ req: Request) throws -> Future<ReturnModelType>
    func indexAll(_ req: Request) throws -> Future<[ReturnModelType]>
    func create(_ req: Request) throws -> Future<ReturnModelType>
    func update(_ req: Request) throws -> Future<ReturnModelType>
    func delete(_ req: Request) throws -> Future<HTTPStatus>
}

public extension CrudChildrenControllerProtocol where ModelType == ReturnModelType, ModelType == ChildType {
    func index(_ req: Request) throws -> Future<ReturnModelType> {
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in

            return try parent[keyPath: self.children]
                .query(on: req)
                .filter(\ChildType.fluentID == childId)
                .first()
                .unwrap(or: Abort(.notFound))
        }
    }

    func indexAll(_ req: Request) throws -> Future<[ReturnModelType]> {
        let parentId: ParentType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<[ChildType]> in

            return try parent[keyPath: self.children]
                .query(on: req)
                .all()
        }
    }

    func create(_ req: Request) throws -> Future<ReturnModelType> {
        let parentId: ParentType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in

            return try req.content.decode(ChildType.self).flatMap { child in
                return try parent[keyPath: self.children].query(on: req).save(child)
            }
        }
    }

    func update(_ req: Request) throws -> Future<ReturnModelType> {
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()

        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> Future<ChildType> in
                return try parent[keyPath: self.children]
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

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()

        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> Future<HTTPStatus> in
                return try parent[keyPath: self.children]
                    .query(on: req)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .delete(on: req)
                    .transform(to: HTTPStatus.ok)
        }
    }
}


public extension CrudChildrenControllerProtocol where ModelType: Publicable, ReturnModelType == ModelType.PublicModel, ModelType == ChildType {
    func index(_ req: Request) throws -> Future<ReturnModelType> {
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()
        
        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ReturnModelType> in
            
            return try parent[keyPath: self.children]
                .query(on: req)
                .filter(\ChildType.fluentID == childId)
                .first()
                .unwrap(or: Abort(.notFound))
                .flatMap { try $0.public(on: req) }
        }
    }
    
    func indexAll(_ req: Request) throws -> Future<[ReturnModelType]> {
        let parentId: ParentType.ID = try req.getId()
        
        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<[ReturnModelType]> in
            
            return try parent[keyPath: self.children]
                .query(on: req)
                .all()
                .flatMap { children in
                    try children.map { try $0.public(on: req) }.flatten(on: req)
                }
        }
    }
    
    func create(_ req: Request) throws -> Future<ReturnModelType> {
        let parentId: ParentType.ID = try req.getId()
        
        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ReturnModelType> in
            
            return try req.content.decode(ChildType.self).flatMap { child in
                return try parent[keyPath: self.children]
                    .query(on: req)
                    .save(child)
                    .flatMap { try $0.public(on: req) }
            }
        }
    }
    
    func update(_ req: Request) throws -> Future<ReturnModelType> {
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()
        
        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> Future<ChildType> in
                return try parent[keyPath: self.children]
                    .query(on: req)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
            }.flatMap { oldChild -> Future<ReturnModelType> in
                return try req.content.decode(ChildType.self).flatMap { newChild in
                    var temp = newChild
                    temp.fluentID = oldChild.fluentID
                    return temp.update(on: req).flatMap { try $0.public(on: req) }
                }
            }
    }
    
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()
        
        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> Future<HTTPStatus> in
                return try parent[keyPath: self.children]
                    .query(on: req)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .delete(on: req)
                    .transform(to: HTTPStatus.ok)
        }
    }
}
