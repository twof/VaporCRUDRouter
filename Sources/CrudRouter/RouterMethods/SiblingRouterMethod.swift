import Vapor
import Fluent

public enum ModifiableSiblingRouterMethod {
    case read
    case readAll
    case create
    case update
    case delete

    func register<ChildType, ParentType, ThroughType>(
        router: RoutesBuilder,
        controller: CrudSiblingsController<ChildType, ParentType, ThroughType>,
        path: [PathComponent],
        idPath: [PathComponent]
    ) where ThroughType.Left == ParentType,
        ThroughType.Right == ChildType {
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

    func register<ChildType, ParentType, ThroughType>(
        router: RoutesBuilder,
        controller: CrudSiblingsController<ChildType, ParentType, ThroughType>,
        path: [PathComponent],
        idPath: [PathComponent]
    ) where ThroughType.Left == ChildType,
        ThroughType.Right == ParentType {
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
