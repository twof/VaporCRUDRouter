import Vapor
import Fluent

public extension Router {
    public func crudRouterCollection<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        for type: ModelType.Type
    )  -> CrudController<ModelType> where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>(path: path, router: self)

        return controller
    }

    public func crud<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        register type: ModelType.Type,
        relationConfiguration: ((CrudController<ModelType>) -> ())?=nil
    ) where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>(path: path, router: self)
        do { try controller.boot(router: self) } catch { fatalError("I have no reason to expect boot to throw") }
        
        relationConfiguration?(controller)
    }
}
