import Vapor
import Fluent

public struct CrudParentController<ChildT: Model & Content, ParentT: Model & Content>: CrudParentControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public let relation: KeyPath<ChildType, Parent<ChildType, ParentType>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]

    init(relation: KeyPath<ChildType, Parent<ChildType, ParentType>>, basePath: [PathComponentsRepresentable], path: [PathComponentsRepresentable]) {
        let path
            = path.count == 0
                ? [String(describing: ParentType.self).snakeCased()! as PathComponentsRepresentable]
                : path

        self.relation = relation
        self.basePath = basePath
        self.path = path
    }
}

extension CrudParentController: RouteCollection {
    public func boot(router: Router) throws {

        let parentString
            = self.path.count == 0
                ? [String(describing: ParentType.self).snakeCased()! as PathComponentsRepresentable]
                : self.path

        let parentPath = self.basePath.appending(parentString)

        router.get(parentPath, use: self.index)
        router.put(parentPath, use: self.update)
    }
}
