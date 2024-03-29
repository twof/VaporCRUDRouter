import Vapor
import Fluent

public struct CrudSiblingsController<
    OriginType: Model & Content,
    SiblingType: Model & Content,
    ThroughType: Model
>: CrudSiblingsControllerProtocol, Crudable where
    SiblingType.IDValue: LosslessStringConvertible,
    OriginType.IDValue: LosslessStringConvertible
{
    public typealias TargetType = SiblingType
    
    public let siblings: KeyPath<OriginType, SiblingsProperty<OriginType, SiblingType, ThroughType>>
    public let path: [PathComponent]
    public let router: RoutesBuilder

    let activeMethods: Set<SiblingRouterMethod>

    init(
        siblingRelation: KeyPath<OriginType, SiblingsProperty<OriginType, SiblingType, ThroughType>>,
        path: [PathComponent],
        router: RoutesBuilder,
        activeMethods: Set<SiblingRouterMethod>
    ) {
        self.siblings = siblingRelation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudSiblingsController: RouteCollection {}

public extension CrudSiblingsController {
    func boot(routes router: RoutesBuilder) throws {
        let childPath = self.path
        let childIdPath = self.path.appending(.parameter("\(SiblingType.schema)ID"))

        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: childPath,
                idPath: childIdPath
            )
        }
    }
}
