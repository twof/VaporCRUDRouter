import Vapor
import Fluent

public struct CrudSiblingsController<
    ChildType: Model & Content,
    ParentType: Model & Content,
    ThroughType: Model
>: CrudSiblingsControllerProtocol, Crudable where
    ChildType.IDValue: LosslessStringConvertible,
    ParentType.IDValue: LosslessStringConvertible
{
    public typealias ParentType = ParentType
    public typealias ChildType = ChildType
    public typealias ThroughType = ThroughType
    
    public var siblings: KeyPath<ParentType, SiblingsProperty<ParentType, ChildType, ThroughType>>
    public let path: [PathComponent]
    public let router: RoutesBuilder
    let activeMethods: Set<ModifiableSiblingRouterMethod>

    init(
        siblingRelation: KeyPath<ParentType, SiblingsProperty<ParentType, ChildType, ThroughType>>,
        path: [PathComponent],
        router: RoutesBuilder,
        activeMethods: Set<ModifiableSiblingRouterMethod>
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
        let childIdPath = self.path.appending(.parameter("\(ChildType.schema)ID"))

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
