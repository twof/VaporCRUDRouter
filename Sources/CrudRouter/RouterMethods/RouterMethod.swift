import Vapor

public enum RouterMethod {
    case read
    case readAll
    case create
    case update
    case delete

    func register<ModelType>(
        router: RoutesBuilder,
        controller: CrudController<ModelType>,
        path: [PathComponent],
        idPath: [PathComponent]
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
