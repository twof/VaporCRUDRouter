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
        return ModelType
            .query(on: req)
            .all()
            .map { Array($0) }
    }

    func index(_ req: Request) throws -> Future<ModelType> {
        let id: ModelType.ID = try getId(from: req)
        return ModelType.find(id, on: req).unwrap(or: Abort(.notFound))
    }

    func create(_ req: Request) throws -> Future<ModelType> {
        return try req
            .content
            .decode(ModelType.self)
            .flatMap { model in
                return model.save(on: req)
            }
    }

    func update(_ req: Request) throws -> Future<ModelType> {
        let id: ModelType.ID = try getId(from: req)
        return try req
            .content.decode(ModelType.self)
            .flatMap { model in
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

fileprivate final class CrudController<T: Model>: CrudControllerProtocol where T.ID: Parameter, T: Content {
    typealias ModelType = T
}

public extension Router {
    func crudRegister<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        for type: ModelType.Type
    ) where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>()

        self.get(path, CrudController<ModelType>.ModelType.ID.parameter, use: controller.index)
        self.get(path, use: controller.indexAll)
        self.post(path, use: controller.create)
        self.put(path, CrudController<ModelType>.ModelType.ID.parameter, use: controller.update)
        self.delete(path, CrudController<ModelType>.ModelType.ID.parameter, use: controller.delete)
    }
}
