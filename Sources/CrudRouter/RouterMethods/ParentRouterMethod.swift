import Vapor

public enum ParentRouterMethod {
    case read
    case update

    func register<Controller: CrudParentControllerProtocol>(
        router: Router,
        controller: Controller,
        path: [PathComponentsRepresentable]
    ) {
        switch self {
        case .read:
            router.get(path, use: controller.index)
        case .update:
            router.put(path, use: controller.update)
        }
    }
}
