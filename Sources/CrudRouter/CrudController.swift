import Vapor
import Fluent

public protocol CrudControllerProtocol {
    associatedtype ModelType: Model, Content where ModelType.ID: Parameter
    func indexAll(_ req: Request) throws -> Future<[ModelType]>
    func index(_ req: Request) throws -> Future<ModelType>
    func update(_ req: Request) throws -> Future<ModelType>
    func create(_ req: Request) throws -> Future<ModelType>
    func delete(_ req: Request) throws -> Future<HTTPStatus>
}

public extension CrudControllerProtocol {
    func indexAll(_ req: Request) throws -> Future<[ModelType]> {
        return ModelType.query(on: req).all().map { Array($0) }
    }

    func index(_ req: Request) throws -> Future<ModelType> {
        let id: ModelType.ID = try getId(from: req)
        return ModelType.find(id, on: req).unwrap(or: Abort(.notFound))
    }

    func create(_ req: Request) throws -> Future<ModelType> {
        return try req.content.decode(ModelType.self).flatMap { model in
            return model.save(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<ModelType> {
        let id: ModelType.ID = try getId(from: req)
        return try req.content.decode(ModelType.self).flatMap { model in
            var temp = model
            temp.fluentID = id
            return temp.update(on: req)
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let id: ModelType.ID = try getId(from: req)
        return ModelType
            .find(id, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { model in
                return model.delete(on: req).transform(to: HTTPStatus.ok)
        }
    }
}

fileprivate extension CrudControllerProtocol {
    func getId<T: ID>(from req: Request) throws -> T {
        guard let id = try req.parameters.next(ModelType.ID.self) as? T else { fatalError() }

        return id
    }
}

public struct CrudController<ModelT: Model & Content>: CrudControllerProtocol where ModelT.ID: Parameter {
    public typealias ModelType = ModelT

    let path: [PathComponentsRepresentable]
    let router: Router

    init(path: [PathComponentsRepresentable], router: Router) {
        let path
            = path.count == 0
                ? [String(describing: ModelType.self).snakeCased()! as PathComponentsRepresentable]
                : path

        self.path = path
        self.router = router
    }
}

// MARK: Obsolted ParentsController methods
extension CrudController {
    /// Returns a parent controller, which retrieves models that are parents of ModelType
    ///
    /// - Parameter relation: Keypath from origin model to a Parent relation, which goes from origin model to
    /// - Returns: relation controller, which retrieves models in relation to ModelType
    public func crudRouteCollection<ParentType>(
        at path: PathComponentsRepresentable...,
        forParent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>
    ) -> CrudParentController<ModelType, ParentType> where
        ParentType: Model & Content,
        ModelType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            return CrudParentController(relation: relation, basePath: baseIdPath, path: path)
    }

    public func crud<ParentType>(
        at path: PathComponentsRepresentable...,
        parent relation: KeyPath<ModelType, Parent<ModelType, ParentType>>,
        relationConfiguration: ((CrudParentController<ModelType, ParentType>) throws -> Void)?=nil
    ) throws where
        ParentType: Model & Content,
        ModelType.Database == ParentType.Database,
        ParentType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudParentController(relation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }
}


// MARK: ChildController methods
extension CrudController {
    public func crudRouteCollection<ChildType>(
        at path: PathComponentsRepresentable...,
        forChildren relation: KeyPath<ModelType, Children<ModelType, ChildType>>
    ) -> CrudChildrenController<ChildType, ModelType> where
        ChildType: Model & Content,
        ModelType.Database == ChildType.Database,
        ChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            return CrudChildrenController(childrenRelation: relation, basePath: baseIdPath, path: path)
    }

    public func crud<ChildType>(
        at path: PathComponentsRepresentable...,
        children relation: KeyPath<ModelType, Children<ModelType, ChildType>>,
        relationConfiguration: ((CrudChildrenController<ChildType, ModelType>) throws -> Void)?=nil
    ) throws where
        ChildType: Model & Content,
        ModelType.Database == ChildType.Database,
        ChildType.ID: Parameter {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            let controller = CrudChildrenController(childrenRelation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }
}

// MARK: SiblingController methods
public extension CrudController {
    public func crudRouteCollection<ChildType, ThroughType>(
        forSiblings relation: KeyPath<ModelType, Siblings<ModelType, ChildType, ThroughType>>,
        at path: [PathComponentsRepresentable]
    ) -> CrudSiblingsController<ChildType, ModelType, ThroughType> where
        ChildType: Content,
        ModelType.Database == ThroughType.Database,
        ChildType.ID: Parameter,
        ThroughType: ModifiablePivot,
        ThroughType.Database: JoinSupporting,
        ThroughType.Database == ChildType.Database {
            let baseIdPath = self.path.appending(ModelType.ID.parameter)

            return CrudSiblingsController(siblingRelation: relation, basePath: baseIdPath, path: path)
    }

    public func crud<ChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildType, ThroughType>>,
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

            let controller = CrudSiblingsController(siblingRelation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }

    public func crud<ChildType, ThroughType>(
        at path: PathComponentsRepresentable...,
        siblings relation: KeyPath<ModelType, Siblings<ModelType, ChildType, ThroughType>>,
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

            let controller = CrudSiblingsController(siblingRelation: relation, basePath: baseIdPath, path: path)

            try controller.boot(router: self.router)
    }
}

extension CrudController: RouteCollection {
    public func boot(router: Router) throws {
        let basePath = path
        let baseIdPath = path.appending(ModelType.ID.parameter)

        router.get(baseIdPath, use: self.index)
        router.get(basePath, use: self.indexAll)
        router.post(basePath, use: self.create)
        router.put(baseIdPath, use: self.update)
        router.delete(baseIdPath, use: self.delete)
    }
}
