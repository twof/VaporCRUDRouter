import Vapor
import Fluent

public protocol ControllerProtocol: RouteCollection {
    associatedtype ModelType: Model, Content where ModelType.ID: Parameter
    associatedtype ReturnModelType: Content
    
    var path: [PathComponentsRepresentable] { get }
    var router: Router { get }
}

public struct CrudController<ModelT: Model & Content> where ModelT.ID: Parameter {
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<RouterMethod>

    init(path: [PathComponentsRepresentable], router: Router, activeMethods: Set<RouterMethod>) {
        let adjustedPath = path.adjustedPath(for: ModelType.self)

        self.path = adjustedPath
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudController: CrudControllerProtocol {
    public typealias ModelType = ModelT
    public typealias ReturnModelType = ModelT
}

extension CrudController: Crudable { }

extension CrudController: RouteCollection {
    public func boot(router: Router) throws {
        let basePath = self.path
        let baseIdPath = self.path.appending(ModelType.ID.parameter)

        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: basePath,
                idPath: baseIdPath
            )
        }
    }
}

public struct PublicableCrudController<ModelT: Model & Content> where ModelT.ID: Parameter, ModelT: Publicable {
    public let path: [PathComponentsRepresentable]
    public let router: Router
    let activeMethods: Set<RouterMethod>
    
    init(path: [PathComponentsRepresentable], router: Router, activeMethods: Set<RouterMethod>) {
        let adjustedPath = path.adjustedPath(for: ModelType.self)
        
        self.path = adjustedPath
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension PublicableCrudController: CrudControllerProtocol {
    public typealias ModelType = ModelT
    public typealias ReturnModelType = ModelT.PublicModel
}

extension PublicableCrudController: Crudable { }

extension PublicableCrudController: ControllerProtocol {
    public func boot(router: Router) throws {
        let basePath = self.path
        let baseIdPath = self.path.appending(ModelType.ID.parameter)
        
        self.activeMethods.forEach {
            $0.register(
                router: router,
                controller: self,
                path: basePath,
                idPath: baseIdPath
            )
        }
    }
}

//extension PublicableCrudController: RouteCollection {
//    public func boot(router: Router) throws {
//        let basePath = path
//        let baseIdPath = path.appending(ModelType.ID.parameter)
//
//        router.get(baseIdPath, use: self.index)
//        router.get(basePath, use: self.indexAll)
//        router.post(basePath, use: self.create)
//        router.put(baseIdPath, use: self.update)
//        router.delete(baseIdPath, use: self.delete)
//    }
//}
