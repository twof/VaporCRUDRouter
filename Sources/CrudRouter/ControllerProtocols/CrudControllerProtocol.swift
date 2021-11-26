import Vapor
import Fluent

protocol CrudControllerProtocol {
    associatedtype ModelType: Model, Content where ModelType.IDValue: LosslessStringConvertible
    
    func indexAll(_ req: Request) async throws -> [ModelType]
    func index(_ req: Request) async throws -> ModelType
    func update(_ req: Request) async throws -> ModelType
    func create(_ req: Request) async throws -> ModelType
    func delete(_ req: Request) async throws -> HTTPStatus
}

extension CrudControllerProtocol {
    func indexAll(_ req: Request) async throws -> [ModelType] {
        return try await ModelType.query(on: req.db).all()
    }

    func index(_ req: Request) async throws -> ModelType {
        let id = try req.getId(modelType: ModelType.self)
        guard let model = try await ModelType.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return model
    }

    func create(_ req: Request) async throws -> ModelType {
        let model = try req.content.decode(ModelType.self)
        try await model.create(on: req.db)
        return model
    }

    func update(_ req: Request) async throws -> ModelType {
        let id = try req.getId(modelType: ModelType.self)
        let model = try req.content.decode(ModelType.self)

        guard let existingModel = try await ModelType.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        let temp = model
        temp._$id.exists = true
        temp.id = existingModel.id
        try await temp.update(on: req.db)
        return temp
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        let id = try req.getId(modelType: ModelType.self)
        guard let model = try await ModelType.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        try await model.delete(on: req.db)
        return HTTPStatus.ok
    }
}
