import Vapor

public enum ParentRouterMethod: CaseIterable {
    case read
    case update

    func register<ChildType, ParentType>(
        router: RoutesBuilder,
        controller: CrudParentController<ChildType, ParentType>,
        path: [PathComponent]
    ) {
        switch self {
        case .read:
            router.on(.GET, path, use: controller.index)
        case .update:
            router.put(path, use: controller.update)
        }
    }
}
