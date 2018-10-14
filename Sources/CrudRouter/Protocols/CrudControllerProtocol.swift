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

public extension CrudControllerProtocol where ModelType: Publicable {
    func indexAll(_ req: Request) throws -> Future<[ModelType.PublicModel]> {
        return ModelType
            .query(on: req)
            .all()
            .map { models in
                return try Array(models)
                    .map { try $0.public(on: req) }
            }
    }
    
    func index(_ req: Request) throws -> Future<ModelType.PublicModel> {
        let id: ModelType.ID = try getId(from: req)
        
        return ModelType
            .find(id, on: req)
            .unwrap(or: Abort(.notFound))
            .map { model in
                return try model.public(on: req)
            }
    }
    
    func create(_ req: Request) throws -> Future<ModelType.PublicModel> {
        return try req.content.decode(ModelType.self).flatMap { model in
            return model.save(on: req).map { try $0.public(on: req) }
        }
    }
    
    func update(_ req: Request) throws -> Future<ModelType.PublicModel> {
        let id: ModelType.ID = try getId(from: req)
        
        return try req.content.decode(ModelType.self).flatMap { model in
            var temp = model
            temp.fluentID = id
            return temp.update(on: req).map { try $0.public(on: req) }
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
