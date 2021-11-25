import Vapor
import Fluent

public struct CrudChildrenController<
    OriginType: Model & Content,
    ChildType: Model & Content
>: CrudChildrenControllerProtocol, Crudable where
    ChildType.IDValue: LosslessStringConvertible,
    OriginType.IDValue: LosslessStringConvertible
{
    public typealias TargetType = ChildType

    public var router: RoutesBuilder

    public var children: KeyPath<OriginType, ChildrenProperty<OriginType, ChildType>>
    public let path: [PathComponent]
    let activeMethods: Set<ChildrenRouterMethod>

    init(
        childrenRelation: KeyPath<OriginType, ChildrenProperty<OriginType, ChildType>>,
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
        let originPath = self.path
        let originIdPath = self.path.appending(.parameter("\(ChildType.schema)ID"))

        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: originPath,
                idPath: originIdPath
            )
        }
    }
}
