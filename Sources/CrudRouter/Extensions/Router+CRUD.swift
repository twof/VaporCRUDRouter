import Vapor
import Fluent

public extension Router {
    public func crudRouterCollection<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        for type: ModelType.Type
    )  -> CrudController<ModelType> where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>(path: path)

        return controller
    }

    public func crudRegister<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        for type: ModelType.Type
    ) throws where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>(path: path)
        try controller.boot(router: self)
    }
}
