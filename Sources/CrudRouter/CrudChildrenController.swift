import Vapor
import Fluent


public struct CrudChildrenController<ChildT: Model & Content, ParentT: Model & Content>: CrudChildrenControllerProtocol, Crudable where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var children: KeyPath<ParentT, Children<ParentT, ChildT>>
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<ChildrenRouterMethod>

    init(
        childrenRelation: KeyPath<ParentT, Children<ParentT, ChildT>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ChildrenRouterMethod>
    ) {
        self.children = childrenRelation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudChildrenController: RouteCollection {
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
