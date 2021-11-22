import Vapor
import Fluent

public struct CrudParentController<
    OriginType: Model & Content,
    ParentType: Model & Content
>: CrudParentControllerProtocol, Crudable where
    OriginType.IDValue: LosslessStringConvertible,
    ParentType.IDValue: LosslessStringConvertible
{
    public let relation: KeyPath<OriginType, ParentProperty<OriginType, ParentType>>
    public let path: [PathComponent]
    public let router: RoutesBuilder
    let activeMethods: Set<ParentRouterMethod>

    init(
        relation: KeyPath<OriginType, ParentProperty<OriginType, ParentType>>,
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
