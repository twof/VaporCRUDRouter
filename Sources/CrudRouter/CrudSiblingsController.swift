import Vapor
import Fluent

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
//    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]
    let activeMethods: Set<ModifiableSiblingRouterMethod>

    init(
        siblingRelation: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>,
//        basePath: [PathComponentsRepresentable],
        path: [PathComponentsRepresentable],
        activeMethods: Set<ModifiableSiblingRouterMethod>
    ) {
        self.siblings = siblingRelation
//        self.basePath = basePath
        self.path = path
        self.activeMethods = activeMethods
    }
}

extension CrudSiblingsController: RouteCollection {}

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
