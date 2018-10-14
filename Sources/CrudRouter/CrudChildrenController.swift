import Vapor
import Fluent

public struct CrudChildrenController<ChildT: Model & Content, ParentT: Model & Content>: CrudChildrenControllerProtocol where ChildT.ID: Parameter, ParentT.ID: Parameter, ChildT.Database == ParentT.Database {
    public typealias ParentType = ParentT
    public typealias ChildType = ChildT

    public var children: KeyPath<ParentT, Children<ParentT, ChildT>>
    let basePath: [PathComponentsRepresentable]
    let path: [PathComponentsRepresentable]

    init(childrenRelation: KeyPath<ParentT, Children<ParentT, ChildT>>, basePath: [PathComponentsRepresentable], path: [PathComponentsRepresentable]) {
        let path
            = path.count == 0
                ? [String(describing: ChildType.self).snakeCased()! as PathComponentsRepresentable]
                : path

        self.children = childrenRelation
        self.basePath = basePath
        self.path = path
    }
}

extension CrudChildrenController: RouteCollection {
    public func boot(router: Router) throws {

        let parentString
            = self.path.count == 0
                ? [String(describing: ParentType.self).snakeCased()! as PathComponentsRepresentable]
                : self.path

        let parentPath = self.basePath.appending(parentString)
        let parentIdPath = self.basePath.appending(parentString).appending(ParentType.ID.parameter)

        router.get(parentIdPath, use: self.index)
        router.get(parentPath, use: self.indexAll)
        router.post(parentPath, use: self.create)
        router.put(parentIdPath, use: self.update)
        router.delete(parentIdPath, use: self.delete)
    }
}
