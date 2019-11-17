import Vapor

public enum ParentRouterMethod {
    case read
    case update

    func register<ChildType, ParentType>(
        router: RoutesBuilder,
        controller: CrudParentController<ChildType, ParentType>,
        path: [PathComponent]
    ) {
        switch self {
        case .read:
            router.get(path, use: controller.index)
        case .update:
            router.put(path, use: controller.update)
        }
    }
}
