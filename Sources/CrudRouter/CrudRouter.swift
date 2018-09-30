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
extension String {
    func snakeCased() -> String? {
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
}


public extension Router {
    func crudRegister<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        for type: ModelType.Type
    ) where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>()

        let path
            = path.count == 0
                ? [String(describing: ModelType.self).snakeCased()! as PathComponentsRepresentable]
                : path

        self.get(path, ModelType.ID.parameter, use: controller.index)
        self.get(path, use: controller.indexAll)
        self.post(path, use: controller.create)
        self.put(path, ModelType.ID.parameter, use: controller.update)
        self.delete(path, ModelType.ID.parameter, use: controller.delete)
    }

    // notes:
    // we want to register other models
    // if something like /todo/1/user comes in, it ought to be translated to
    // /todo?userid=1
}
