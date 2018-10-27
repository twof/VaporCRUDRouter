import Vapor
import Fluent

public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content>: CrudParentControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    let path: [PathComponentsRepresentable]
    let activeMethods: Set<ParentRouterMethod>

    init(
        relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        path: [PathComponentsRepresentable],
        activeMethods: Set<ParentRouterMethod>
    ) {
        self.relation = relation
        self.path = path
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
