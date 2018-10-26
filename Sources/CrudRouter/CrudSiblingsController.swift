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
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in

            return try parent[keyPath: self.siblings]
                .query(on: req)
                .filter(\ChildType.fluentID == childId)
                .first()
                .unwrap(or: Abort(.notFound))
        }
    }

    func indexAll(_ req: Request) throws -> Future<[ChildType]> {
        let parentId: ParentType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<[ChildType]> in
            let siblingsRelation = parent[keyPath: self.siblings]
            return try siblingsRelation
                .query(on: req)
                .all()
        }
    }

    func update(_ req: Request) throws -> Future<ChildType> {
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()

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
        let parentId: ParentType.ID = try req.getId()

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in

            return try req.content.decode(ChildType.self).flatMap { child in
                let relation = parent[keyPath: self.siblings]
                return relation.attach(child, on: req).transform(to: child)
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
        let parentId: ParentType.ID = try req.getId()

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
        let parentId: ParentType.ID = try req.getId()
        let childId: ChildType.ID = try req.getId()

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

public struct CrudSiblingsController<ChildT: Model & Content, ParentT: Model & Content, ThroughT: ModifiablePivot>: CrudSiblingsControllerProtocol where
    ChildT.ID: Parameter,
    ParentT.ID: Parameter,
    ChildT.Database == ParentT.Database,
    ThroughT.Database: JoinSupporting,
    ThroughT.Database == ChildT.Database {

    public typealias ThroughType = ThroughT
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]
    let activeMethods: Set<ModifiableSiblingRouterMethod>

    init(
        siblingRelation: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>,
        basePath: [PathComponentsRepresentable],
        path: [PathComponentsRepresentable],
        activeMethods: Set<ModifiableSiblingRouterMethod>
    ) {
        let path = path.adjustedPath(for: ChildType.self)

        self.siblings = siblingRelation
        self.basePath = basePath
        self.path = path
        self.activeMethods = activeMethods
    }
}

extension CrudSiblingsController: RouteCollection {}

public extension CrudSiblingsController where ThroughType.Right == ParentType,
ThroughType.Left == ChildType {
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

public extension CrudSiblingsController where ThroughType.Left == ParentType,
ThroughType.Right == ChildType {
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

public extension CrudSiblingsController {
    public func boot(router: Router) throws {
        let parentPath = self.basePath.appending(self.path)
        let parentIdPath = self.basePath.appending(self.path).appending(ParentType.ID.parameter)

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.put(parentIdPath, use: self.update)
    }
}
