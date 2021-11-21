import Vapor
import Fluent

public struct CrudChildrenController<ChildT: Model & Content, ParentT: Model & Content>: CrudChildrenControllerProtocol, Crudable where ChildT.IDValue: LosslessStringConvertible, ParentT.IDValue: LosslessStringConvertible {
//    public var db: Database
    public var router: RoutesBuilder
    
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var children: KeyPath<ParentT, ChildrenProperty<ParentT, ChildT>>
    public let path: [PathComponent]
    let activeMethods: Set<ChildrenRouterMethod>

    init(
        childrenRelation: KeyPath<ParentT, ChildrenProperty<ParentT, ChildT>>,
        path: [PathComponent],
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
    public func boot(routes routesBuilder: RoutesBuilder) throws {
        let parentPath = self.path
        let parentIdPath = self.path.appending(.parameter("\(ParentType.schema)ID"))

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
