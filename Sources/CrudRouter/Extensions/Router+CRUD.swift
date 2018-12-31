import Vapor
import Fluent

public extension Router {
    
    /// Registers CRUD routes for the supplied model.
    ///
    /// - Parameters:
    ///   - path: The path where all created routes will be based. Defaults to snake cased name of type.
    ///   - type: The model to create routes for.
    ///   - either: Select to include or exclude specific operations. Defaults to all CRUD operations.
    ///   - relationConfiguration: Closure to configure child, parent, or sibling routes.
    public func crud<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        register type: ModelType.Type,
        _ either: OnlyExceptEither<RouterMethod> = .only([.read, .readAll, .create, .update, .delete]),
        relationConfiguration: ((CrudController<ModelType>) -> ())?=nil
    ) where ModelType.ID: Parameter {
        let allMethods: Set<RouterMethod> = Set([.read, .readAll, .create, .update, .delete])
        let controller: CrudController<ModelType>

        switch either {
        case .only(let methods):
            controller = CrudController<ModelType>(path: path, router: self, activeMethods: Set(methods))
        case .except(let methods):
            controller = CrudController<ModelType>(path: path, router: self, activeMethods: allMethods.subtracting(Set(methods)))
        }

        do { try controller.boot(router: self) } catch { fatalError("I have no reason to expect boot to throw") }

        relationConfiguration?(controller)
    }
}
