import Vapor
import Fluent

protocol CrudControllerProtocol {
    associatedtype ModelType: Model, Content where ModelType.IDValue: LosslessStringConvertible
    
    func indexAll(_ req: Request) async throws -> Response
    func index(_ req: Request) async throws -> Response
    func update(_ req: Request) async throws -> Response
    func create(_ req: Request) async throws -> Response
    func delete(_ req: Request) async throws -> Response
}

extension CrudControllerProtocol {
    func indexAll(_ req: Request) async throws -> Response {
        let model = try await ModelType.query(on: req.db).all()
        return try await model.encodeResponse(status: .ok, for: req)
    }

    func index(_ req: Request) async throws -> Response {
        let id = try req.getId(modelType: ModelType.self)
        guard let model = try await ModelType.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return try await model.encodeResponse(status: .ok, for: req)
    }

    func create(_ req: Request) async throws -> Response {
        let model = try req.content.decode(ModelType.self)
        try await model.create(on: req.db)
        return try await model.encodeResponse(status: .created, for: req)
    }

    func update(_ req: Request) async throws -> Response {
        let id = try req.getId(modelType: ModelType.self)
        let model = try req.content.decode(ModelType.self)

        guard let existingModel = try await ModelType.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        let temp = model
        temp._$id.exists = true
        temp.id = existingModel.id
        try await temp.update(on: req.db)
        return try await temp.encodeResponse(status: .ok, for: req)
    }

    func delete(_ req: Request) async throws -> Response {
        let id = try req.getId(modelType: ModelType.self)
        guard let model = try await ModelType.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        try await model.delete(on: req.db)
        return try await HTTPStatus.noContent.encodeResponse(for: req)
    }
}
