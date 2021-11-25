import Vapor
import Fluent

public protocol ControllerProtocol {
    var path: [PathComponent] { get }
    var router: RoutesBuilder { get }
}

public protocol Crudable: ControllerProtocol {
    associatedtype OriginType: Model, Content where OriginType.IDValue: LosslessStringConvertible
    associatedtype TargetType: Model, Content where TargetType.IDValue: LosslessStringConvertible

    func crud<ParentType>(
        at path: PathComponent...,
        parent relation: KeyPath<TargetType, ParentProperty<TargetType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod>,
        relationConfiguration: ((CrudParentController<TargetType, ParentType>) -> Void)?
    ) where
        ParentType: Model & Content,
        ParentType.IDValue: LosslessStringConvertible

    func crud<ChildType>(
        at path: PathComponent...,
        children relation: KeyPath<TargetType, ChildrenProperty<TargetType, ChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod>,
        relationConfiguration: ((CrudChildrenController<TargetType, ChildType>) -> Void)?
    ) where
        ChildType: Model & Content

    func crud<SiblingType, ThroughType>(
        at path: PathComponent...,
        siblings relation: KeyPath<TargetType, SiblingsProperty<TargetType, SiblingType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod>,
        relationConfiguration: ((CrudSiblingsController<TargetType, SiblingType, ThroughType>) -> Void)?
    ) where
        SiblingType: Content,
        SiblingType.IDValue: LosslessStringConvertible,
        ThroughType: Model
}

extension Crudable {
    public func crud<ParentType>(
        at path: PathComponent...,
        parent relation: KeyPath<TargetType, ParentProperty<TargetType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only([.read, .update]),
        relationConfiguration: ((CrudParentController<TargetType, ParentType>) -> Void)?=nil
    ) where
        ParentType: Model & Content,
        ParentType.IDValue: LosslessStringConvertible
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: ParentType.self)

        let fullPath = baseIdPath + adjustedPath

        let allMethods: Set<ParentRouterMethod> = Set([.read, .update])
        let controller: CrudParentController<TargetType, ParentType>

        switch either {
        case .only(let methods):
            controller = CrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
        }

        do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    public func crud<ChildType>(
        at path: PathComponent...,
        children relation: KeyPath<TargetType, ChildrenProperty<TargetType, ChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudChildrenController<TargetType, ChildType>) -> Void)?=nil
    ) where
        ChildType: Model & Content,
        ChildType.IDValue: LosslessStringConvertible
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: ChildType.self)

        let fullPath = baseIdPath + adjustedPath

        let allMethods: Set<ChildrenRouterMethod> = Set([.create, .read, .readAll, .update, .delete])
        let controller: CrudChildrenController<TargetType, ChildType>

        switch either {
        case .only(let methods):
            controller = CrudChildrenController<TargetType, ChildType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudChildrenController<TargetType, ChildType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
        }

        do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    public func crud<SiblingType, ThroughType>(
        at path: PathComponent...,
        siblings relation: KeyPath<TargetType, SiblingsProperty<TargetType, SiblingType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<TargetType, SiblingType, ThroughType>) -> Void)?=nil
    ) where
        SiblingType: Content,
        SiblingType.IDValue: LosslessStringConvertible,
        ThroughType: Model
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: SiblingType.self)

        let fullPath = baseIdPath + adjustedPath

        let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
        let controller: CrudSiblingsController<TargetType, SiblingType, ThroughType>

        switch either {
        case .only(let methods):
            controller = CrudSiblingsController<TargetType, SiblingType, ThroughType>(siblingRelation: relation, path: fullPath, router:
                self.router, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudSiblingsController<TargetType, SiblingType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
        }

         do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }
}
