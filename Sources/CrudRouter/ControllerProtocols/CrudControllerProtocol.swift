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
        let id: ModelType.ID = try req.getId()
        return ModelType.find(id, on: req).unwrap(or: Abort(.notFound))
    }

    func create(_ req: Request) throws -> Future<ModelType> {
        return try req.content.decode(ModelType.self).flatMap { model in
            return model.save(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<ModelType> {
        let id: ModelType.ID = try req.getId()
        return try req.content.decode(ModelType.self).flatMap { model in
            var temp = model
            temp.fluentID = id
            return temp.update(on: req)
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let id: ModelType.ID = try req.getId()
        return ModelType
            .find(id, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { model in
                return model.delete(on: req).transform(to: HTTPStatus.ok)
        }
    }
}
