import Vapor
import Fluent

public struct CrudSiblingsController<
    ChildT: Model & Content,
    ParentT: Model & Content,
    ThroughT: Model
>: CrudSiblingsControllerProtocol, Crudable where
    ChildT.IDValue: LosslessStringConvertible,
    ParentT.IDValue: LosslessStringConvertible
{
//    public var db: Database
    
    public typealias ThroughType = ThroughT
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>
    public let path: [PathComponent]
    public let router: RoutesBuilder
    let activeMethods: Set<ModifiableSiblingRouterMethod>

    init(
        siblingRelation: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>,
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

public extension CrudSiblingsController where
    ThroughType.Right == ParentType,
    ThroughType.Left == ChildType
{
    func boot(routes router: RoutesBuilder) throws {
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

public extension CrudSiblingsController where
    ThroughType.Left == ParentType,
    ThroughType.Right == ChildType
{
    func boot(routes router: RoutesBuilder) throws {
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

public extension CrudSiblingsController {
    func boot(routes router: RoutesBuilder) throws {
        let parentPath = self.path
        let parentIdPath = self.path.appending(.parameter("\(ParentType.schema)ID"))

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.put(parentIdPath, use: self.update)
    }
}
