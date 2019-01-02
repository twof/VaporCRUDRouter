import Vapor
import Fluent

public protocol Crudable: ControllerProtocol {
//    func crud<ParentType>(
//        at path: PathComponentsRepresentable...,
//        parent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>,
//        _ either: OnlyExceptEither<ParentRouterMethod>,
//        relationConfiguration: ((CrudParentController<ModelType, ParentType>) -> Void)?
//    ) where
//        ParentType: Model & Content,
//        ModelType.Database == ParentType.Database,
//        ParentType.ID: Parameter

//    func crud<ChildChildType>(
//        at path: PathComponentsRepresentable...,
//        children relation: KeyPath<ModelType, Children<ModelType, ChildChildType>>,
//        _ either: OnlyExceptEither<ChildrenRouterMethod>,
//        relationConfiguration: ((CrudChildrenController<ChildChildType, ModelType>) -> Void)?
//    ) where
//        ChildChildType: Model & Content,
//        ModelType.Database == ChildChildType.Database,
//        ChildChildType.ID: Parameter
//
//    func crud<ChildChildType, ThroughType>(
//        at path: PathComponentsRepresentable...,
//        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildChildType, ThroughType>>,
//        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod>,
//        relationConfiguration: ((CrudSiblingsController<ChildChildType, ModelType, ThroughType>) -> Void)?
//    ) where
//        ChildChildType: Content,
//        ModelType.Database == ThroughType.Database,
//        ChildChildType.ID: Parameter,
//        ThroughType: ModifiablePivot,
//        ThroughType.Database: JoinSupporting,
//        ThroughType.Database == ChildChildType.Database,
//        ThroughType.Left == ModelType,
//        ThroughType.Right == ChildChildType
//
//    func crud<ChildChildType, ThroughType>(
//        at path: PathComponentsRepresentable...,
//        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildChildType, ThroughType>>,
//        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod>,
//        relationConfiguration: ((CrudSiblingsController<ChildChildType, ModelType, ThroughType>) -> Void)?
//    ) where
//        ChildChildType: Content,
//        ModelType.Database == ThroughType.Database,
//        ChildChildType.ID: Parameter,
//        ThroughType: ModifiablePivot,
//        ThroughType.Database: JoinSupporting,
//        ThroughType.Database == ChildChildType.Database,
//        ThroughType.Right == ModelType,
//        ThroughType.Left == ChildChildType
}

extension Crudable where ReturnModelType == ModelType {
    public func crud<ParentType>(
        at path: PathComponentsRepresentable...,
        parent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only([.read, .update]),
        relationConfiguration: ((CrudParentController<ModelType, ParentType>) -> Void)?=nil
    ) where
        ParentType: Model & Content,
        ModelType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ParentType.self)

            let fullPath = baseIdPath.appending(adjustedPath)


            let allMethods: Set<ParentRouterMethod> = Set([.read, .update])
            let controller: CrudParentController<ModelType, ParentType>

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
        children relation: KeyPath<ModelType, Children<ModelType, ChildChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudChildrenController<ChildChildType, ModelType>) -> Void)?=nil
    ) where
        ChildChildType: Model & Content,
        ModelType.Database == ChildChildType.Database,
        ChildChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)

            let fullPath = baseIdPath.appending(adjustedPath)

            let allMethods: Set<ChildrenRouterMethod> = Set([.read, .update])
            let controller: CrudChildrenController<ChildChildType, ModelType>

            switch either {
            case .only(let methods):
                controller = CrudChildrenController<ChildChildType, ModelType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudChildrenController<ChildChildType, ModelType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

            relationConfiguration?(controller)
    }

    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ModelType, ThroughType>) -> Void)?=nil
    ) where
        ChildChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Left == ModelType,
        ThroughType.Right == ChildChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)

            let fullPath = baseIdPath.appending(adjustedPath)

            let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
            let controller: CrudSiblingsController<ChildChildType, ModelType, ThroughType>

            switch either {
            case .only(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router:
                    self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

             do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

            relationConfiguration?(controller)
    }

    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ModelType, ThroughType>) -> Void)?=nil
    ) where
        ChildChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Right == ModelType,
        ThroughType.Left == ChildChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)

            let fullPath = baseIdPath.appending(adjustedPath)

            let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
            let controller: CrudSiblingsController<ChildChildType, ModelType, ThroughType>

            switch either {
            case .only(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }

            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }

            relationConfiguration?(controller)
    }
}

extension Crudable where ModelType: Publicable, ReturnModelType == ModelType.PublicModel {
    public func crud<ParentType>(
        at path: PathComponentsRepresentable...,
        parent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>,
        _ either: OnlyExceptEither<ParentRouterMethod> = .only([.read, .update]),
        relationConfiguration: ((PublicableCrudParentController<ModelType, ParentType>) -> Void)?=nil
    ) where
        ParentType: Model & Content,
        ModelType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ParentType.self)
            
            let fullPath = baseIdPath.appending(adjustedPath)
            
            
            let allMethods: Set<ParentRouterMethod> = Set([.read, .update])
            let controller: PublicableCrudParentController<ModelType, ParentType>
            
            switch either {
            case .only(let methods):
                controller = PublicableCrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = PublicableCrudParentController(relation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }
            
            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }
            
            relationConfiguration?(controller)
    }
    
    public func crud<ChildChildType>(
        at path: PathComponentsRepresentable...,
        children relation: KeyPath<ModelType, Children<ModelType, ChildChildType>>,
        _ either: OnlyExceptEither<ChildrenRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudChildrenController<ChildChildType, ModelType>) -> Void)?=nil
        ) where
        ChildChildType: Model & Content,
        ModelType.Database == ChildChildType.Database,
        ChildChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)
            
            let fullPath = baseIdPath.appending(adjustedPath)
            
            let allMethods: Set<ChildrenRouterMethod> = Set([.read, .update])
            let controller: CrudChildrenController<ChildChildType, ModelType>
            
            switch either {
            case .only(let methods):
                controller = CrudChildrenController<ChildChildType, ModelType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudChildrenController<ChildChildType, ModelType>(childrenRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }
            
            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }
            
            relationConfiguration?(controller)
    }
    
    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ModelType, ThroughType>) -> Void)?=nil
        ) where
        ChildChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Left == ModelType,
        ThroughType.Right == ChildChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)
            
            let fullPath = baseIdPath.appending(adjustedPath)
            
            let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
            let controller: CrudSiblingsController<ChildChildType, ModelType, ThroughType>
            
            switch either {
            case .only(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router:
                    self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }
            
            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }
            
            relationConfiguration?(controller)
    }
    
    public func crud<ChildChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildChildType, ThroughType>>,
        _ either: OnlyExceptEither<ModifiableSiblingRouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudSiblingsController<ChildChildType, ModelType, ThroughType>) -> Void)?=nil
        ) where
        ChildChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildChildType.Database,
        ThroughType.Right == ModelType,
        ThroughType.Left == ChildChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)
            let adjustedPath = path.adjustedPath(for: ChildChildType.self)
            
            let fullPath = baseIdPath.appending(adjustedPath)
            
            let allMethods: Set<ModifiableSiblingRouterMethod> = Set([.read, .readAll, .create, .update, .delete])
            let controller: CrudSiblingsController<ChildChildType, ModelType, ThroughType>
            
            switch either {
            case .only(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: Set(methods))
            case .except(let methods):
                controller = CrudSiblingsController<ChildChildType, ModelType, ThroughType>(siblingRelation: relation, path: fullPath, router: self.router, activeMethods: allMethods.subtracting(Set(methods)))
            }
            
            do { try controller.boot(router: self.router) } catch { fatalError("I have no reason to expect boot to throw") }
            
            relationConfiguration?(controller)
    }
}
