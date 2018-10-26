import Vapor

public enum ParentRouterMethod {
    case read
    case update

    func register<ChildType, ParentType>(
        router: Router,
        controller: CrudParentController<ChildType, ParentType>,
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
