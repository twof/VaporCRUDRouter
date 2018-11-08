import Vapor
import Fluent

public protocol CrudControllerProtocol {
    associatedtype ModelType: Model, Content, Returnable where ModelType.ID: Parameter
    func indexAll(_ req: Request) throws -> Future<[ModelType.Return]>
    func index(_ req: Request) throws -> Future<ModelType.Return>
    func update(_ req: Request) throws -> Future<ModelType.Return>
    func create(_ req: Request) throws -> Future<ModelType.Return>
    func delete(_ req: Request) throws -> Future<HTTPStatus>
}

public extension CrudControllerProtocol where ModelType: Publicable, ModelType.Return == ModelType.PublicModel {
    func indexAll(_ req: Request) throws -> Future<[ModelType.Return]> {
        return ModelType
            .query(on: req)
            .all()
            .flatMap { models in
                return try models
                    .map { try $0.public(on: req) }
                    .flatten(on: req)
            }
    }
    
    func index(_ req: Request) throws -> Future<ModelType.Return> {
        let id: ModelType.ID = try getId(from: req)
        
        return ModelType
            .find(id, on: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { model in
                return try model.public(on: req)
            }
    }
    
    func create(_ req: Request) throws -> Future<ModelType.Return> {
        return try req.content.decode(ModelType.self).flatMap { model in
            return model.save(on: req).flatMap { try $0.public(on: req) }
        }
    }
    
    func update(_ req: Request) throws -> Future<ModelType.Return> {
        let id: ModelType.ID = try getId(from: req)
        
        return try req.content.decode(ModelType.self).flatMap { model in
            var temp = model
            temp.fluentID = id
            return temp.update(on: req).flatMap { try $0.public(on: req) }
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

public extension CrudControllerProtocol where ModelType.Return == ModelType {
    func indexAll(_ req: Request) throws -> Future<[ModelType.Return]> {
        return ModelType.query(on: req).all().map { elements in
            Array(elements)
        }
    }
    
    func index(_ req: Request) throws -> Future<ModelType.Return> {
        let id: ModelType.ID = try getId(from: req)
        return ModelType.find(id, on: req).unwrap(or: Abort(.notFound))
    }
    
    func create(_ req: Request) throws -> Future<ModelType.Return> {
        return try req.content.decode(ModelType.self).flatMap { model in
            return model.save(on: req)
        }
    }
    
    func update(_ req: Request) throws -> Future<ModelType.Return> {
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

public extension CrudControllerProtocol {
    func indexAll(_ req: Request) throws -> Future<[ModelType.Return]> {
        fatalError()
    }

    func index(_ req: Request) throws -> Future<ModelType.Return> {
        fatalError()
    }

    func create(_ req: Request) throws -> Future<ModelType.Return> {
        fatalError()
    }

    func update(_ req: Request) throws -> Future<ModelType.Return> {
        fatalError()
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        fatalError()
    }
}

fileprivate extension CrudControllerProtocol {
    func getId<T: ID>(from req: Request) throws -> T {
        guard let id = try req.parameters.next(ModelType.ID.self) as? T else { fatalError() }

        return id
    }
}


