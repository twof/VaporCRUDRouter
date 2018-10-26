import Vapor
import Fluent

public extension Router {
    public func crud<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        register type: ModelType.Type,
        _ either: OnlyExceptEither<RouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudController<ModelType>) throws -> ())?=nil
    ) throws where ModelType.ID: Parameter {
        let allMethods: Set<RouterMethod> = Set([.read, .readAll, .create, .update, .delete])
        let controller: CrudController<ModelType>

        switch either {
        case .only(let methods):
            controller = CrudController<ModelType>(path: path, router: self, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudController<ModelType>(path: path, router: self, activeMethods: allMethods.subtracting(Set(methods)))
        }

        try controller.boot(router: self)

        try relationConfiguration?(controller)
    }
}
