import Vapor
import Fluent

public protocol ControllerProtocol {
    var path: [PathComponent] { get }
    var router: RoutesBuilder { get }
}

public struct CrudController<ModelT: Model & Content>: CrudControllerProtocol, Crudable where ModelT.IDValue: LosslessStringConvertible {
    public typealias ChildType = ModelT
    public typealias ModelType = ModelT

    public let db: Database
    public let path: [PathComponent]
    public let router: RoutesBuilder
    let activeMethods: Set<RouterMethod>

    init(path: [PathComponent], router: RoutesBuilder, activeMethods: Set<RouterMethod>) {
        let adjustedPath = path.adjustedPath(for: ModelType.self)

        self.path = adjustedPath
        self.router = router
        self.activeMethods = activeMethods
    }
}

extension CrudController: RouteCollection {
    public func boot(routes router: RoutesBuilder) throws {
        let basePath = self.path
        let baseIdPath = self.path.appending(PathComponent.parameter("\(ModelType.schema)ID"))

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
