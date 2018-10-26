import Vapor
import Fluent

public protocol CrudChildrenControllerProtocol {
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

public struct CrudChildrenController<ChildT: Model & Content, ParentT: Model & Content>: CrudChildrenControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var children: KeyPath<ParentT, Children<ParentT, ChildT>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]
    let activeMethods: Set<ChildrenRouterMethod>

    init(
        childrenRelation: KeyPath<ParentT,
        Children<ParentT, ChildT>>,
        basePath: [PathComponentsRepresentable],
        path: [PathComponentsRepresentable],
        activeMethods: Set<ChildrenRouterMethod>
    ) {
        let adjustedPath = path.adjustedPath(for: ChildType.self)

        self.children = childrenRelation
        self.basePath = basePath
        self.path = adjustedPath
        self.activeMethods = activeMethods
    }
}

extension CrudChildrenController: RouteCollection {
    public func boot(router: Router) throws {
        let parentPath = self.basePath.appending(self.path)
        let parentIdPath = self.basePath.appending(self.path).appending(ParentType.ID.parameter)

        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: parentPath,
                idPath: parentIdPath
            )
        }
    }
}
