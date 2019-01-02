import Vapor
import Fluent

public protocol ParentControllerProtocol: Crudable, RouteCollection {
    associatedtype ChildType: Model & Content where ChildType.ID: Parameter, ChildType.Database == ParentType.Database
    associatedtype ParentType: Model & Content where ParentType.ID: Parameter
    
    init(
        relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ParentRouterMethod>
    )
}

public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content> where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    
    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<ParentRouterMethod>

    public init(
        relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ParentRouterMethod>
    ) {
        self.relation = relation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudParentController: CrudParentControllerProtocol {
    public typealias ModelType = ChildT
    public typealias ReturnModelType = ChildT
}

extension CrudParentController: ParentControllerProtocol {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT
    
    public func boot(router: Router) throws {
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

public struct PublicableCrudParentController<ChildT: Model & Content, ParentT: Model & Content> where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database, ChildT: Publicable {
    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<ParentRouterMethod>
    
    public init(
        relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        path: [PathComponentsRepresentable],
        router: Router,
        activeMethods: Set<ParentRouterMethod>
    ) {
        self.relation = relation
        self.path = path
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension PublicableCrudParentController: CrudParentControllerProtocol {
    public typealias ModelType = ChildT
    public typealias ReturnModelType = ChildT.PublicModel
}

extension PublicableCrudParentController: ParentControllerProtocol {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT
    
    public func boot(router: Router) throws {
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



