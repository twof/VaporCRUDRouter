import Vapor
import Fluent

public protocol ChildrenControllerProtocol: Crudable, RouteCollection {
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    
    init(
        childrenRelation: KeyPath<ParentType, Children<ParentType, ChildType>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ChildrenRouterMethod>
    )
}

public struct CrudChildrenController<ChildT: Model & Content, ParentT: Model & Content> where
    ChildT.ID: Parameter,
    ParentT.ID: Parameter,
    ChildT.Database == ParentT.Database
{
    public var children: KeyPath<ParentT, Children<ParentT, ChildT>>
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<ChildrenRouterMethod>

    public init(
        childrenRelation: KeyPath<ParentT, Children<ParentT, ChildT>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ChildrenRouterMethod>
    ) {
        self.children = childrenRelation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudChildrenController: CrudChildrenControllerProtocol {
    public typealias ModelType = ParentT
    public typealias ReturnModelType = ParentT
}

extension CrudChildrenController: ChildrenControllerProtocol {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT
    
    public func boot(router: Router) throws {
        let parentPath = self.path
        let parentIdPath = self.path.appending(ParentType.ID.parameter)
        
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
