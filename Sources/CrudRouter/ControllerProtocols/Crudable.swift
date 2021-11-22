import Vapor
import Fluent

public protocol Crudable: ControllerProtocol {
    associatedtype OriginType: Model, Content where OriginType.IDValue: LosslessStringConvertible

    func crud<ParentType>(
        at path: PathComponent...,
        parent relation: KeyPath<OriginType, ParentProperty<OriginType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod>,
        relationConfiguration: ((CrudParentController<ParentType, OriginType>) -> Void)?
    ) where
        ParentType: Model & Content,
        ParentType.IDValue: LosslessStringConvertible

    func crud<ChildType>(
        at path: PathComponent...,
        children relation: KeyPath<OriginType, ChildrenProperty<OriginType, ChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod>,
        relationConfiguration: ((CrudChildrenController<ChildType, OriginType>) -> Void)?
    ) where
        ChildType: Model & Content

    func crud<SiblingType, ThroughType>(
        at path: PathComponent...,
        siblings relation: KeyPath<OriginType, SiblingsProperty<OriginType, SiblingType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod>,
        relationConfiguration: ((CrudSiblingsController<SiblingType, OriginType, ThroughType>) -> Void)?
    ) where
        SiblingType: Content,
        SiblingType.IDValue: LosslessStringConvertible,
        ThroughType: Model
}

extension Crudable {
    public func crud<ParentType>(
        at path: PathComponent...,
        parent relation: KeyPath<OriginType, ParentProperty<OriginType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only([.read, .update]),
        relationConfiguration: ((CrudParentController<ParentType, OriginType>) -> Void)?=nil
    ) where
        ParentType: Model & Content,
        ParentType.IDValue: LosslessStringConvertible
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: ParentType.self)

        let fullPath = baseIdPath + adjustedPath


        let allMethods: Set<ParentRouterMethod> = Set([.read, .update])
        let controller: CrudParentController<ParentType, OriginType>

        switch either {
        case .only(let methods):
            controller = CrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
        }

        do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    public func crud<ChildChildType>(
        at path: PathComponent...,
        children relation: KeyPath<OriginType, ChildrenProperty<OriginType, ChildChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudChildrenController<ChildChildType, OriginType>) -> Void)?=nil
    ) where
        ChildChildType: Model & Content,
        ChildChildType.IDValue: LosslessStringConvertible
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: ChildChildType.self)

        let fullPath = baseIdPath + adjustedPath

        let allMethods: Set<ChildrenRouterMethod> = Set([.create, .read, .readAll, .update, .delete])
        let controller: CrudChildrenController<ChildChildType, OriginType>

        switch either {
        case .only(let methods):
            controller = CrudChildrenController<ChildChildType, OriginType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudChildrenController<ChildChildType, OriginType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
        }

        do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }

    public func crud<ChildChildType, ThroughType>(
        at path: PathComponent...,
        siblings relation: KeyPath<OriginType, SiblingsProperty<OriginType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, OriginType, ThroughType>) -> Void)?=nil
    ) where
        ChildChildType: Content,
        ChildChildType.IDValue: LosslessStringConvertible,
        ThroughType: Model
    {
        let baseIdPath = self.path.appending(.parameter("\(OriginType.schema)ID"))
        let adjustedPath = path.adjustedPath(for: ChildChildType.self)

        let fullPath = baseIdPath + adjustedPath

        let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
        let controller: CrudSiblingsController<ChildChildType, OriginType, ThroughType>

        switch either {
        case .only(let methods):
            controller = CrudSiblingsController<ChildChildType, OriginType, ThroughType>(siblingRelation: relation, path: fullPath, router:
                self.router, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudSiblingsController<ChildChildType, OriginType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
        }

         do { try controller.boot(routes: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }
}
