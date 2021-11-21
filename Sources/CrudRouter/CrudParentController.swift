import Vapor
import Fluent

public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content>: CrudParentControllerProtocol, Crudable where ChildT.IDValue: LosslessStringConvertible, ParentT.IDValue: LosslessStringConvertible {
//    public var db: Database
    
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public let relation: KeyPath<ChildType, ParentProperty<ChildType, ParentType>>
    public let path: [PathComponent]
    public let router: RoutesBuilder
    let activeMethods: Set<ParentRouterMethod>

    init(
        relation: KeyPath<ChildType, ParentProperty<ChildType, ParentType>>,
        path: [PathComponent],
        router: RoutesBuilder,
        activeMethods: Set<ParentRouterMethod>
    ) {
        self.relation = relation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudParentController: RouteCollection {
    public func boot(routes router: RoutesBuilder) throws {
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
