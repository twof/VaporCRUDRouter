import Vapor
import Fluent

public protocol CrudChildrenControllerProtocol: Crudable {
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database

    var children: KeyPath<ParentType, Children<ParentType, ChildType>> { get }

    func index(_ req: Request) throws -> Future<ChildType>
    func indexAll(_ req: Request) throws -> Future<[ChildType]>
    func create(_ req: Request) throws -> Future<ChildType>
    func update(_ req: Request) throws -> Future<ChildType>
    func delete(_ req: Request) throws -> Future<HTTPStatus>
}

public extension CrudChildrenControllerProtocol {
    func index(_ req: Request) throws -> Future<ChildType> {
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

    func indexAll(_ req: Request) throws -> Future<[ChildType]> {
        let parentId: ParentType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<[ChildType]> in

            return try parent[keyPath: self.children]
                .query(on: req)
                .all()
        }
    }

    func create(_ req: Request) throws -> Future<ChildType> {
        let parentId: ParentType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in

            return try req.content.decode(ChildType.self).flatMap { child in
                return try parent[keyPath: self.children].query(on: req).save(child)
            }
        }
    }

    func update(_ req: Request) throws -> Future<ChildType> {
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
