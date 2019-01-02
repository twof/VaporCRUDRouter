import Vapor
import Fluent


public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content>: CrudParentControllerProtocol, Crudable where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<ParentRouterMethod>

    init(
        relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ParentRouterMethod>
    ) {
        self.relation = relation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudParentController: RouteCollection {
    public func boot(router: Router) throws {
        let parentPath = self.path

        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: parentPath
            )
        }
    }
}
