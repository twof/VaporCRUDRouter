import Vapor
import Fluent
import FluentKit

extension EventLoopFuture {
    func throwingFlatMap<NewValue>(file: StaticString = #file, line: UInt = #line, _ callback: @escaping ((Value) throws -> EventLoopFuture<NewValue>)) rethrows -> EventLoopFuture<NewValue> {
        return self.flatMap(file: file, line: line) { (value: Value) -> EventLoopFuture<NewValue> in
            do {
                return try callback(value)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
}

public protocol CrudSiblingsControllerProtocol {
    associatedtype ParentType: Model & Content where ParentType.IDValue: LosslessStringConvertible
    associatedtype ChildType: Model & Content where ChildType.IDValue: LosslessStringConvertible
    associatedtype ThroughType: Model

    var siblings: KeyPath<ParentType, SiblingsProperty<ParentType, ChildType, ThroughType>> { get }

    func index(_ req: Request) throws -> EventLoopFuture<ChildType>
    func indexAll(_ req: Request) throws -> EventLoopFuture<[ChildType]>
    func update(_ req: Request) throws -> EventLoopFuture<ChildType>
}

public extension CrudSiblingsControllerProtocol {
    func index(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId = try req.getId(modelType: ParentType.self)

        return try ParentType.find(parentId, on: req.db).unwrap(or: Abort(.notFound)).throwingFlatMap { parent -> EventLoopFuture<ChildType> in

            return try parent[keyPath: self.siblings]
                .query(on: req.db)
                .first()
                .unwrap(or: Abort(.notFound))
        }
    }

    func indexAll(_ req: Request) throws -> EventLoopFuture<[ChildType]> {
        let parentId = try req.getId(modelType: ParentType.self)

        return try ParentType.find(parentId, on: req.db).unwrap(or: Abort(.notFound)).throwingFlatMap { parent -> EventLoopFuture<[ChildType]> in
            let siblingsRelation = parent[keyPath: self.siblings]
            return try siblingsRelation
                .query(on: req.db)
                .all()
        }
    }

    func update(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId = try req.getId(modelType: ParentType.self)

        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<ChildType> in
                let siblings: SiblingsProperty<ParentType, ChildType, ThroughType> = parent[keyPath: self.siblings]
                let siblingsQuery = try siblings.query(on: req.db)
                return siblingsQuery
                    .first()
                    .unwrap(or: Abort(.notFound))
            }.throwingFlatMap { oldChild in
                let newChild = try req.content.decode(ChildType.self)
                let temp = newChild
                temp.id = oldChild.id
                return temp.update(on: req.db).transform(to: temp)
            }
    }
}

public extension CrudSiblingsControllerProtocol
//    where
//    ThroughType.Left == ParentType,
//    ThroughType.Right == ChildType
{
    func create(_ req: Request) throws -> EventLoopFuture<ChildType> {
        let parentId = try req.getId(modelType: ParentType.self)

        return try ParentType.find(parentId, on: req.db).unwrap(or: Abort(.notFound)).throwingFlatMap { parent -> EventLoopFuture<ChildType> in
            let child = try req.content.decode(ChildType.self)
            
            let relation = parent[keyPath: self.siblings]
            return relation.attach(child, on: req.db).transform(to: child)
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let parentId = try req.getId(modelType: ParentType.self)

        return try ParentType
            .find(parentId, on: req.db)
            .unwrap(or: Abort(.notFound))
            .throwingFlatMap { parent -> EventLoopFuture<HTTPStatus> in
                let siblingsRelation = parent[keyPath: self.siblings]
                return try siblingsRelation
                    .query(on: req.db)
                    .first()
                    .unwrap(or: Abort(.notFound))
                    .flatMap { siblingsRelation.detach($0, on: req.db).transform(to: $0) }
                    .delete(on: req.db)
                    .transform(to: HTTPStatus.ok)
        }
    }
}

//public extension CrudSiblingsControllerProtocol where ThroughType.Right == ParentType,
//ThroughType.Left == ChildType {
//    func create(_ req: Request) throws -> EventLoopFuture<ChildType> {
//        let parentId: ParentType.IDValue = try req.getId()
//
//        return try ParentType.find(parentId, on: req.db).unwrap(or: Abort(.notFound)).throwingFlatMap { parent -> EventLoopFuture<ChildType> in
//
//            return try req.content.decode(ChildType.self).flatMap { child in
//                return child.create(on: req.db)
//            }.flatMap { child in
//                let relation = parent[keyPath: self.siblings]
//                return relation.attach(child, on: req.db).transform(to: child)
//            }
//        }
//    }
//
//    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        let parentId: ParentType.IDValue = try req.getId()
//        let childId: ChildType.IDValue = try req.getId()
//
//        return try ParentType
//            .find(parentId, on: req.db)
//            .unwrap(or: Abort(.notFound))
//            .throwingFlatMap { parent -> EventLoopFuture<HTTPStatus> in
//                let siblingsRelation = parent[keyPath: self.siblings]
//                return try siblingsRelation
//                    .query(on: req.db)
//                    .filter(\ChildType.fluentID == childId)
//                    .first()
//                    .unwrap(or: Abort(.notFound))
//                    .delete(on: req.db)
//                    .transform(to: HTTPStatus.ok)
//        }
//    }
//}
