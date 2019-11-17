import Vapor
import Fluent

public struct CrudChildrenController<ChildT: Model & Content, ParentT: Model & Content>: CrudChildrenControllerProtocol, Crudable where ChildT.IDValue: LosslessStringConvertible, ParentT.IDValue: LosslessStringConvertible {
    public var db: Database
    public var router: RoutesBuilder
    
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var children: KeyPath<ParentT, Children<ParentT, ChildT>>
    public let path: [PathComponentsRepresentable]
    let activeMethods: Set<ChildrenRouterMethod>

    init(
        childrenRelation: KeyPath<ParentT, Children<ParentT, ChildT>>,
        path: [PathComponentsRepresentable],
        router: RoutesBuilder,
        activeMethods: Set<ChildrenRouterMethod>
    ) {
        self.children = childrenRelation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudChildrenController: RouteCollection {
    public func boot(routes router: RoutesBuilder) throws {
        let parentPath = self.path
        let parentIdPath = self.path.appending(ParentType.IDValue.parameter)

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
