import Vapor
import Fluent

public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content>: CrudParentControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]
    let activeMethods: Set<ParentRouterMethod>

    init(
        relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        basePath: [PathComponentsRepresentable],
        path: [PathComponentsRepresentable],
        activeMethods: Set<ParentRouterMethod>
    ) {
        let adjustedPath = path.adjustedPath(for: ParentType.self)

        self.relation = relation
        self.basePath = basePath
        self.path = adjustedPath
        self.activeMethods = activeMethods
    }
}

extension CrudParentController: RouteCollection {
    public func boot(router: Router) throws {
        let parentPath = self.basePath.appending(self.path)

        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: parentPath
            )
        }
    }
}
