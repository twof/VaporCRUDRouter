import Vapor
import Fluent

public struct CrudChildrenController<ChildT: Model & Content, ParentT: Model & Content>: CrudChildrenControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var children: KeyPath<ParentT, Children<ParentT, ChildT>>
    let path: [PathComponentsRepresentable]
    let router: Router
    let activeMethods: Set<ChildrenRouterMethod>

    init(
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

extension CrudChildrenController {
    public func crud<ParentType>(
        at path: PathComponentsRepresentable...,
        parent relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only([.read, .update]),
        relationConfiguration: ((CrudParentController<ChildType, ParentType>) throws -> Void)?=nil
    ) throws where
        ParentType: Model & Content,
        ChildType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            let baseIdPath = self.path.appending(ChildType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ParentType.self)

            let fullPath = baseIdPath.appending(adjustedPath)


            let allMethods: Set<ParentRouterMethod> = Set([.read, .update])
            let controller: CrudParentController<ChildType, ParentType>

            switch either {
            case .only(let methods):
                controller = CrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            try controller.boot(router: self.router)

            try relationConfiguration?(controller)
    }
}


// MARK: ChildController methods
extension CrudChildrenController {
    public func crud<ChildChildType>(
        at path: PathComponentsRepresentable...,
        children relation: KeyPath<ChildType, Children<ChildType, ChildChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudChildrenController<ChildChildType, ChildType>) throws -> Void)?=nil
    ) throws where
        ChildChildType: Model & Content,
        ChildType.Database == ChildChildType.Database,
        ChildChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ChildType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildType.self)

            let fullPath = baseIdPath.appending(adjustedPath)

            let allMethods: Set<ChildrenRouterMethod> = Set([.read, .update])
            let controller: CrudChildrenController<ChildChildType, ChildType>

            switch either {
            case .only(let methods):
                controller = CrudChildrenController<ChildChildType, ChildType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudChildrenController<ChildChildType, ChildType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            try controller.boot(router: self.router)

            try relationConfiguration?(controller)
    }
}

// MARK: SiblingController methods
public extension CrudChildrenController {
    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ChildType, Siblings<ChildType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ChildType, ThroughType>) throws -> Void)?=nil
    ) throws where
        ChildChildType: Content,
        ChildType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Left == ChildType,
        ThroughType.Right == ChildChildType {
            let baseIdPath = self.path.appending(ChildType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)

            let fullPath = baseIdPath.appending(adjustedPath)

            let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
            let controller: CrudSiblingsController<ChildChildType, ChildType, ThroughType>

            switch either {
            case .only(let methods):
                controller = CrudSiblingsController(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            try controller.boot(router: self.router)

            try relationConfiguration?(controller)
    }

    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ChildType, Siblings<ChildType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ChildType, ThroughType>) throws -> Void)?=nil
    ) throws where
        ChildChildType: Content,
        ChildType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Right == ChildType,
        ThroughType.Left == ChildChildType {
            let baseIdPath = self.path.appending(ChildType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)

            let fullPath = baseIdPath.appending(adjustedPath)

            let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
            let controller: CrudSiblingsController<ChildChildType, ChildType, ThroughType>

            switch either {
            case .only(let methods):
                controller = CrudSiblingsController(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            try controller.boot(router: self.router)

            try relationConfiguration?(controller)
    }
}

extension CrudChildrenController: RouteCollection {
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
