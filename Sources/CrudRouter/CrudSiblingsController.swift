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

//public extension CrudSiblingsController where
//    ThroughType.Right == ParentType,
//    ThroughType.Left == ChildType
//{
//    func boot(routes router: RoutesBuilder) throws {
//        let parentPath = self.path
//        let parentIdPath = self.path.appending(.parameter("\(ParentType.schema)ID"))
//
//        self.activeMethods.forEach {
//            $0.register(
//                router: router,
//                controller: self,
//                path: parentPath,
//                idPath: parentIdPath
//            )
//        }
//    }
//}
//
public extension CrudSiblingsController
//    where
//    ThroughType.Left == ParentType,
//    ThroughType.Right == ChildType
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

//public extension CrudSiblingsController {
//    func boot(routes router: RoutesBuilder) throws {
//        let parentPath = self.path
//        let parentIdPath = self.path.appending(.parameter("\(ParentType.schema)ID"))
//
//        router.on(.GET, parentIdPath, use: self.index)
//        router.on(.GET, parentPath, use: self.indexAll)
//        router.put(parentIdPath, use: self.update)
//    }
//}
