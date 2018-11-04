import Vapor
import Fluent

public protocol Crudable: ControllerProtocol {
    associatedtype ChildType: Model, Content where ChildType.ID: Parameter

    func crud<ParentType>(
        at path: PathComponentsRepresentable...,
        parent relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod>,
        relationConfiguration: ((CrudParentController<ChildType, ParentType>) -> Void)?
    ) where
        ParentType: Model & Content,
        ChildType.Database == ParentType.Database,
        ParentType.ID: Parameter

    func crud<ChildChildType>(
        at path: PathComponentsRepresentable...,
        children relation: KeyPath<ChildType, Children<ChildType, ChildChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod>,
        relationConfiguration: ((CrudChildrenController<ChildChildType, ChildType>) -> Void)?
    ) where
        ChildChildType: Model & Content,
        ChildType.Database == ChildChildType.Database,
        ChildChildType.ID: Parameter

    func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ChildType, Siblings<ChildType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod>,
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ChildType, ThroughType>) -> Void)?
    ) where
        ChildChildType: Content,
        ChildType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Left == ChildType,
        ThroughType.Right == ChildChildType

    func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ChildType, Siblings<ChildType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod>,
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ChildType, ThroughType>) -> Void)?
    ) where
        ChildChildType: Content,
        ChildType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Right == ChildType,
        ThroughType.Left == ChildChildType
}

extension Crudable {
    public func crud<ParentType>(
        at path: PathComponentsRepresentable...,
        parent relation: KeyPath<ChildType, Parent<ChildType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only([.read, .update]),
        relationConfiguration: ((CrudParentController<ChildType, ParentType>) -> Void)?=nil
    ) where
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

            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

            relationConfiguration?(controller)
    }

    public func crud<ChildChildType>(
        at path: PathComponentsRepresentable...,
        children relation: KeyPath<ChildType, Children<ChildType, ChildChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudChildrenController<ChildChildType, ChildType>) -> Void)?=nil
    ) where
        ChildChildType: Model & Content,
        ChildType.Database == ChildChildType.Database,
        ChildChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ChildType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)

            let fullPath = baseIdPath.appending(adjustedPath)

            let allMethods: Set<ChildrenRouterMethod> = Set([.read, .update])
            let controller: CrudChildrenController<ChildChildType, ChildType>

            switch either {
            case .only(let methods):
                controller = CrudChildrenController<ChildChildType, ChildType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudChildrenController<ChildChildType, ChildType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

            relationConfiguration?(controller)
    }

    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ChildType, Siblings<ChildType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ChildType, ThroughType>) -> Void)?=nil
    ) where
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
                controller = CrudSiblingsController<ChildChildType, ChildType, ThroughType>(siblingRelation: relation, path: fullPath, router:
                    self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController<ChildChildType, ChildType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

             do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

            relationConfiguration?(controller)
    }

    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ChildType, Siblings<ChildType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ChildType, ThroughType>) -> Void)?=nil
    ) where
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
                controller = CrudSiblingsController<ChildChildType, ChildType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController<ChildChildType, ChildType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

            relationConfiguration?(controller)
    }
}
