import Vapor
import Fluent
public enum RouterMethods {
    case read
    case readAll
    case create
    case update
    case delete

    func register<ModelType>(
        router: Router,
        controller: CrudController<ModelType>,
        path: [PathComponentsRepresentable],
        idPath: [PathComponentsRepresentable]
    ) {
        switch self {
        case .read:
            router.get(idPath, use: controller.index)
        case .readAll:
            router.get(path, use: controller.indexAll)
        case .create:
            router.post(path, use: controller.create)
        case .update:
            router.put(idPath, use: controller.update)
        case .delete:
            router.delete(idPath, use: controller.delete)
        }
    }
}

public extension Router {
    public func crud<ModelType: Model & Content>(
        _ path: PathComponentsRepresentable...,
        register type: ModelType.Type,
        useMethods: [RouterMethods] = [.read, .readAll, .create, .update, .delete],
        relationConfiguration: ((CrudController<ModelType>) throws -> ())?=nil
    ) throws where ModelType.ID: Parameter {
        let controller = CrudController<ModelType>(path: path, router: self, activeMethods: Set(useMethods))
        try controller.boot(router: self)

        try relationConfiguration?(controller)
    }
}
