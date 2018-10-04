import Vapor
import Fluent

public extension Router {
    @available(swift, obsoleted: 4.0, renamed: "crud(_:register:relationConfiguration:)")
    public func crudRegister<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        for type: ModelType.Type,
        relationConfiguration: ((CrudController<ModelType>) throws -> ())?=nil
    ) throws where ModelType.ID: Parameter {}
}
