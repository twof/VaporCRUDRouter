import Vapor
import Fluent

public protocol CrudControllerProtocol {
    associatedtype ModelType: Model, Content where ModelType.IDValue: LosslessStringConvertible
//    var db: Database { get }
    
    func indexAll(_ req: Request) throws -> EventLoopFuture<[ModelType]>
    func index(_ req: Request) throws -> EventLoopFuture<ModelType>
    func update(_ req: Request) throws -> EventLoopFuture<ModelType>
    func create(_ req: Request) throws -> EventLoopFuture<ModelType>
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus>
}

public extension CrudControllerProtocol {
    func indexAll(_ req: Request) throws -> EventLoopFuture<[ModelType]> {
        return ModelType.query(on: req.db).all().map { Array($0) }
    }

    func index(_ req: Request) throws -> EventLoopFuture<ModelType> {
        let id: ModelType.IDValue = try req.getId()
        return ModelType.find(id, on: req.db).unwrap(or: Abort(.notFound))
    }

    func create(_ req: Request) throws -> EventLoopFuture<ModelType> {
        return try req.content.decode(ModelType.self).save(on: req.db).map {
            return
        }
    }

    func update(_ req: Request) throws -> EventLoopFuture<ModelType> {
        let id: ModelType.IDValue = try req.getId()
        let model = try req.content.decode(ModelType.self)
       
        let temp = model
        temp.id = id
        return temp.update(on: req.db).map {
            return 
        }
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let id: ModelType.IDValue = try req.getId()
        return ModelType
            .find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { model in
                return model.delete(on: req.db).transform(to: HTTPStatus.ok)
        }
    }
}
