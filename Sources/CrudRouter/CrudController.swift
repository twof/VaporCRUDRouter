import Vapor
import Fluent

public protocol ControllerProtocol {
    var path: [PathComponentsRepresentable] { get }
    var router: Router { get }
}

public struct CrudController<ModelT: Model & Content & Returnable>: CrudControllerProtocol, Crudable where ModelT.ID: Parameter {
    public typealias ChildType = ModelT

    public typealias ModelType = ModelT

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
