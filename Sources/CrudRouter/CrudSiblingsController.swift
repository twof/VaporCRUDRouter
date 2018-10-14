import Vapor
import Fluent

public struct CrudSiblingsController<ChildT: Model & Content, ParentT: Model & Content, ThroughT: ModifiablePivot>: CrudSiblingsControllerProtocol where
    ChildT.ID: Parameter,
    ParentT.ID: Parameter,
    ChildT.Database == ParentT.Database,
    ThroughT.Database: JoinSupporting,
ThroughT.Database == ChildT.Database {

    public typealias ThroughType = ThroughT
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var siblings: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]

    init(
        siblingRelation: KeyPath<ParentType, Siblings<ParentType, ChildType, ThroughType>>,
        basePath: [PathComponentsRepresentable],
        path: [PathComponentsRepresentable]
    ) {
        let path
            = path.count == 0
                ? [String(describing: ChildType.self).snakeCased()! as PathComponentsRepresentable]
                : path

        self.siblings = siblingRelation
        self.basePath = basePath
        self.path = path
    }
}

extension CrudSiblingsController: RouteCollection {}

public extension CrudSiblingsController where ThroughType.Right == ParentType,
ThroughType.Left == ChildType {
    public func boot(router: Router) throws {
        let parentPath = self.basePath.appending(self.path)
        let parentIdPath = self.basePath.appending(self.path).appending(ParentType.ID.parameter)

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.post(parentPath, use: self.create)
        router.put(parentIdPath, use: self.update)
        router.delete(parentIdPath, use: self.delete)
    }
}

public extension CrudSiblingsController where ThroughType.Left == ParentType,
ThroughType.Right == ChildType {
    public func boot(router: Router) throws {
        let parentPath = self.basePath.appending(self.path)
        let parentIdPath = self.basePath.appending(self.path).appending(ParentType.ID.parameter)

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.post(parentPath, use: self.create)
        router.put(parentIdPath, use: self.update)
        router.delete(parentIdPath, use: self.delete)
    }
}

public extension CrudSiblingsController {
    public func boot(router: Router) throws {
        let parentPath = self.basePath.appending(self.path)
        let parentIdPath = self.basePath.appending(self.path).appending(ParentType.ID.parameter)

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.put(parentIdPath, use: self.update)
    }
}
