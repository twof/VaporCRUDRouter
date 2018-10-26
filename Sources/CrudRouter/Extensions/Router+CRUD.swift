import Vapor
import Fluent

public extension Router {
    public func crud<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        register type: ModelType.Type,
        useMethods: [RouterMethod] = [.read, .readAll, .create, .update, .delete],
        relationConfiguration: ((CrudController<ModelType>) throws -> ())?=nil
    ) throws where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>(path: path, router: self, activeMethods: Set(useMethods))
        try controller.boot(router: self)

        try relationConfiguration?(controller)
    }
}
