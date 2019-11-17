import Vapor
import FluentKit
import Fluent
import NIOExtras

public protocol CrudChildrenControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible

    var children: KeyPath<ParentType, Children<ParentType, ChildType>> { get }

    func index(_ req: Request) throws -> EventLoopFuture<ChildType>
    func indexAll(_ req: Request) throws -> EventLoopFuture<[ChildType]>
    func create(_ req: Request) throws -> EventLoopFuture<ChildType>
    func update(_ req: Request) throws -> EventLoopFuture<ChildType>
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus>
}

public extension CrudChildrenControllerProtocol {
    func index(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId: ParentType.IDValue = try req.getId()
        let childId: ChildType.IDValue = try req.getId()
        
        let thing = ParentType
            .query(on: req.db)
            .join(ChildType.self, on: children == \ParentType.$id)
        
        return
        
//            .find(parentId, on: db)
//            .unwrap(or: Abort(.notFound))
//            .flatMap { parent -> EventLoopFuture<ChildType> in
//                return try! parent[keyPath: self.children]
//                    .query(on: self.db)
//                    .filter(\ChildType.id == childId)
//                    .first()
//                    .unwrap(or: Abort(.notFound))
//        }
    }

    func indexAll(_ req: Request) throws -> EventLoopFuture<[ChildType]> {
        let parentId: ParentType.IDValue = try req.getId()
        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<[ChildType]> in
                return try parent[keyPath: self.children]
                    .query(on: req.db)
                    .all()
            }
    }

    func create(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId: ParentType.IDValue = try req.getId()

        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<ChildType> in
                let child = try req.content.decode(ChildType.self)
                return try parent[keyPath: self.children].query(on: req.db)
        }
    }

    func update(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId: ParentType.IDValue = try req.getId()
        let childId: ChildType.IDValue = try req.getId()

        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<ChildType> in
                return try parent[keyPath: self.children]
                    .query(on: req.db)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
            }.throwingFlatMap { oldChild in
                return try req.content.decode(ChildType.self).flatMap { newChild in
                    var temp = newChild
                    temp.fluentID = oldChild.fluentID
                    return temp.update(on: req.db)
                }
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let parentId: ParentType.IDValue = try req.getId()
        let childId: ChildType.IDValue = try req.getId()

        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<HTTPStatus> in
                return try parent[keyPath: self.children]
                    .query(on: req.db)
                    .filter(\ChildType.fluentID == childId)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .delete(on: req.db)
                    .transform(to: HTTPStatus.ok)
        }
    }
}
