import Vapor
import Fluent

public struct CrudSiblingsController<ChildT: Model & Content, ParentT: Model & Content, ThroughT: ModifiablePivot>
    where
    ChildT.ID: Parameter,
    ParentT.ID: Parameter,
    ChildT.Database == ParentT.Database,
    ThroughT.Database: JoinSupporting,
    ThroughT.Database == ChildT.Database {

    public typealias ThroughType = ThroughT
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<ModifiableSiblingRouterMethod>

    init(
        siblingRelation: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ModifiableSiblingRouterMethod>
    ) {
        self.siblings = siblingRelation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudSiblingsController: CrudSiblingsControllerProtocol {
    public typealias ModelType = ChildT
    public typealias ReturnModelType = ChildT
}

extension CrudSiblingsController: Crudable { }

extension CrudSiblingsController: RouteCollection { }

public extension CrudSiblingsController where ThroughType.Right == ParentType,
ThroughType.Left == ChildType {
    public func boot(router: Router) throws {
        let parentPath = self.path
        let parentIdPath = self.path.appending(ParentType.ID.parameter)

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
        let parentPath = self.path
        let parentIdPath = self.path.appending(ParentType.ID.parameter)

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
        let parentPath = self.path
        let parentIdPath = self.path.appending(ParentType.ID.parameter)

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.put(parentIdPath, use: self.update)
    }
}
