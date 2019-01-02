import Vapor
import Fluent

public protocol CrudControllerProtocol {
    associatedtype ModelType: Model, Content where ModelType.ID: Parameter
    associatedtype ReturnModelType: Content
    func indexAll(_ req: Request) throws -> Future<[ReturnModelType]>
    func index(_ req: Request) throws -> Future<ReturnModelType>
    func update(_ req: Request) throws -> Future<ReturnModelType>
    func create(_ req: Request) throws -> Future<ReturnModelType>
    func delete(_ req: Request) throws -> Future<HTTPStatus>
}

public extension CrudControllerProtocol where ModelType: Publicable, ReturnModelType == ModelType.PublicModel {
    func indexAll(_ req: Request) throws -> Future<[ReturnModelType]> {
        return ModelType
            .query(on: req)
            .all()
            .flatMap { models in
                return try models
                    .map { try $0.public(on: req) }
                    .flatten(on: req)
        }
    }
    
    func index(_ req: Request) throws -> Future<ReturnModelType> {
        let id: ModelType.ID = try req.getId()
        
        return ModelType
            .find(id, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { model in
                return try model.public(on: req)
        }
    }
    
    func create(_ req: Request) throws -> Future<ReturnModelType> {
        return try req.content.decode(ModelType.self).flatMap { model in
            return model.save(on: req).flatMap { try $0.public(on: req) }
        }
    }
    
    func update(_ req: Request) throws -> Future<ReturnModelType> {
        let id: ModelType.ID = try req.getId()
        
        return try req.content.decode(ModelType.self).flatMap { model in
            var temp = model
            temp.fluentID = id
            return temp.update(on: req).flatMap { try $0.public(on: req) }
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


public extension CrudControllerProtocol where ReturnModelType == ModelType {
    func indexAll(_ req: Request) throws -> Future<[ReturnModelType]> {
        return ModelType.query(on: req).all().map { Array($0) }
    }

    func index(_ req: Request) throws -> Future<ReturnModelType> {
        let id: ModelType.ID = try req.getId()
        return ModelType.find(id, on: req).unwrap(or: Abort(.notFound))
    }

    func create(_ req: Request) throws -> Future<ReturnModelType> {
        return try req.content.decode(ModelType.self).flatMap { model in
            return model.save(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<ReturnModelType> {
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
