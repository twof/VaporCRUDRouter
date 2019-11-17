import Vapor
import Fluent

public protocol CrudSiblingsControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible
    associatedtype ThroughType: Model
    
    var db: Database { get }

    var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>> { get }

    func index(_ req: Request) throws -> EventLoopFuture<ChildType>
    func indexAll(_ req: Request) throws -> EventLoopFuture<[ChildType]>
    func update(_ req: Request) throws -> EventLoopFuture<ChildType>
}

public extension CrudSiblingsControllerProtocol {
    func index(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId: ParentType.IDValue = try req.getId()
        let childId: ChildType.IDValue = try req.getId()

        return ParentType.find(parentId, on: db).unwrap(or: Abort(.notFound)).flatMap { parent -> EventLoopFuture<ChildType> in

            return try parent[keyPath: self.siblings]
                .query(on: self.db)
                .filter(\ChildType.fluentID == childId)
                .first()
                .unwrap(or: Abort(.notFound))
        }
    }

    func indexAll(_ req: Request) throws -> EventLoopFuture<[ChildType]> {
        let parentId: ParentType.IDValue = try req.getId()

        return ParentType.find(parentId, on: db).unwrap(or: Abort(.notFound)).flatMap { parent -> EventLoopFuture<[ChildType]> in
            let siblingsRelation = parent[keyPath: self.siblings]
            return try siblingsRelation
                .query(on: self.db)
                .all()
        }
    }

    func update(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId: ParentType.IDValue = try req.getId()
        let childId: ChildType.IDValue = try req.getId()

        return ParentType
            .find(parentId, on: db)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> EventLoopFuture<ChildType> in
                return try parent[keyPath: self.siblings]
                    .query(on: self.db)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
            }.flatMap { oldChild in
                return try req.content.decode(ChildType.self).flatMap { newChild in
                    var temp = newChild
                    temp.fluentID = oldChild.fluentID
                    return temp.update(on: self.db)
                }
        }
    }
}

public extension CrudSiblingsControllerProtocol where ThroughType.Left == ParentType,
ThroughType.Right == ChildType {
    func create(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId: ParentType.IDValue = try req.getId()

        return ParentType.find(parentId, on: db).unwrap(or: Abort(.notFound)).flatMap { parent -> EventLoopFuture<ChildType> in

            return try req.content.decode(ChildType.self).flatMap { child in
                let relation = parent[keyPath: self.siblings]
                return relation.attach(child, on: self.db).transform(to: child)
            }
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let parentId: ParentType.IDValue = try req.getId()
        let childId: ChildType.IDValue = try req.getId()

        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> EventLoopFuture<HTTPStatus> in
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
    func create(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId: ParentType.IDValue = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> EventLoopFuture<ChildType> in

            return try req.content.decode(ChildType.self).flatMap { child in
                return child.create(on: req)
                }.flatMap { child in
                    let relation = parent[keyPath: self.siblings]
                    return relation.attach(child, on: req).transform(to: child)
            }
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let parentId: ParentType.IDValue = try req.getId()
        let childId: ChildType.IDValue = try req.getId()

        return ParentType
            .find(parentId, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { parent -> EventLoopFuture<HTTPStatus> in
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
