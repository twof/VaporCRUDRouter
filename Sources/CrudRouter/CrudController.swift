import Vapor
import Fluent

public struct CrudController<ModelT: Model & Content>: CrudControllerProtocol where ModelT.ID: Parameter {
    public typealias ModelType = ModelT

    let path: [PathComponentsRepresentable]
    let router: Router
    let activeMethods: Set<RouterMethod>

    init(path: [PathComponentsRepresentable], router: Router, activeMethods: Set<RouterMethod>) {
        let adjustedPath = path.adjustedPath(for: ModelType.self)

        self.path = adjustedPath
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudController {
    public func crud<ParentType>(
        at path: PathComponentsRepresentable...,
        parent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>,
        useMethods: [ParentRouterMethod] = [.read, .update],
        relationConfiguration: ((CrudParentController<ModelType, ParentType>) throws -> Void)?=nil
    ) throws where
        ParentType: Model & Content,
        ModelType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudParentController(relation: relation, basePath: baseIdPath, path: path, activeMethods: Set(useMethods))

            try controller.boot(router: self.router)
    }
}


// MARK: ChildController methods
extension CrudController {
    public func crud<ChildType>(
        at path: PathComponentsRepresentable...,
        children relation: KeyPath<ModelType, Children<ModelType, ChildType>>,
        useMethods: [ChildrenRouterMethod] = [.read, .readAll, .create, .update, .delete],
        relationConfiguration: ((CrudChildrenController<ChildType, ModelType>) throws -> Void)?=nil
    ) throws where
        ChildType: Model & Content,
        ModelType.Database == ChildType.Database,
        ChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudChildrenController(childrenRelation: relation, basePath: baseIdPath, path: path, activeMethods: Set(useMethods))

            try controller.boot(router: self.router)
    }
}

// MARK: SiblingController methods
public extension CrudController {
    public func crud<ChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildType, ThroughType>>,
        useMethods: [ModifiableSiblingRouterMethod] = [.read, .readAll, .create, .update, .delete],
        relationConfiguration: ((CrudSiblingsController<ChildType, ModelType, ThroughType>) throws -> Void)?=nil
    ) throws where
        ChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildType.Database,
        ThroughType.Left == ModelType,
        ThroughType.Right == ChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudSiblingsController(siblingRelation: relation, basePath: baseIdPath, path: path, activeMethods: Set(useMethods))

            try controller.boot(router: self.router)
    }

    public func crud<ChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildType, ThroughType>>,
        useMethods: [ModifiableSiblingRouterMethod] = [.read, .readAll, .create, .update, .delete],
        relationConfiguration: ((CrudSiblingsController<ChildType, ModelType, ThroughType>) throws -> Void)?=nil
    ) throws where
        ChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildType.Database,
        ThroughType.Right == ModelType,
        ThroughType.Left == ChildType {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudSiblingsController(siblingRelation: relation, basePath: baseIdPath, path: path, activeMethods: Set(useMethods))

            try controller.boot(router: self.router)
    }
}

extension CrudController: RouteCollection {
    public func boot(router: Router) throws {
        let basePath = self.path
        let baseIdPath = self.path.appending(ModelType.ID.parameter)

        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: basePath,
                idPath: baseIdPath
            )
        }
    }
}
