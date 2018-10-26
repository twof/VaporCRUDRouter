import Vapor
import Fluent

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
