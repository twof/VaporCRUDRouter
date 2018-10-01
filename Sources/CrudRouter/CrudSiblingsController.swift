import Vapor
import Fluent

public protocol CrudSiblingsControllerProtocol {
    associatedtype ParentType: Content where ParentType.ID: Parameter
    associatedtype ChildType: Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database
    associatedtype ThroughType: ModifiablePivot where
        ThroughType.Database: JoinSupporting,
        ChildType.Database == ThroughType.Database,
        ThroughType.Left == ParentType,
        ThroughType.Right == ChildType

    var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>> { get }

    init(siblingRelation: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>, basePath: [PathComponentsRepresentable], path: [PathComponentsRepresentable])

    func index(_ req: Request) throws -> Future<ChildType>
    func indexAll(_ req: Request) throws -> Future<[ChildType]>
    func create(_ req: Request) throws -> Future<ChildType>
    func update(_ req: Request) throws -> Future<ChildType>
    func delete(_ req: Request) throws -> Future<HTTPStatus>
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

    func create(_ req: Request) throws -> Future<ChildType> {
        let parentId: ParentType.ID = try getId(from: req)

        return ParentType.find(parentId, on: req).unwrap(or: Abort(.notFound)).flatMap { parent -> Future<ChildType> in

            return try req.content.decode(ChildType.self).flatMap { child in
                let relation = parent[keyPath: self.siblings]
                return relation.attach(child, on: req).transform(to: child)
            }
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

public struct CrudSiblingsController<ChildT: Content, ParentT: Content, ThroughT: ModifiablePivot>: CrudSiblingsControllerProtocol where
        ChildT.ID: Parameter,
        ParentT.ID: Parameter,
        ChildT.Database == ParentT.Database,
        ThroughT.Database: JoinSupporting,
        ThroughT.Database == ChildT.Database,
        ThroughT.Left == ParentT,
        ThroughT.Right == ChildT {

    public typealias ThroughType = ThroughT
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]

    public init(
        siblingRelation: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>,
        basePath: [PathComponentsRepresentable],
        path: [PathComponentsRepresentable]
    ) {
        self.siblings = siblingRelation
        self.basePath = basePath
        self.path = path
    }
}

extension CrudSiblingsController: RouteCollection {}

public extension CrudSiblingsController {
    public func boot(router: Router) throws {
        let parentString
            = self.path.count == 0
                ? [String(describing: ParentType.self).snakeCased()! as PathComponentsRepresentable]
                : self.path

        let parentPath = self.basePath.appending(parentString)
        let parentIdPath = self.basePath.appending(parentString).appending(ParentType.ID.parameter)

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.post(parentPath, use: self.create)
        router.put(parentIdPath, use: self.update)
        router.delete(parentIdPath, use: self.delete)
    }
}
